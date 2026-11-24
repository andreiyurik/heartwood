require "test_helper"

# docs/features/feedback.md
class FeedbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @person = trees(:alpha).people.create!(given_names: "Vera")
    sign_in_as @user
  end

  test "the account menu offers to write to us when the install names an operator address" do
    with_operator_email { get person_path(@person) }
    assert_select ".account-menu a[href=?]", new_feedback_path, text: I18n.t("feedbacks.menu")
  end

  test "a self-hosted install with no operator address mails no one" do
    get person_path(@person)
    assert_select ".account-menu a[href=?]", new_feedback_path, count: 0

    get new_feedback_path
    assert_response :not_found
  end

  test "the form remembers the page the member came from" do
    with_operator_email { get new_feedback_path, headers: { "Referer" => person_url(@person) + "?tab=sources" } }
    assert_response :success
    assert_select "textarea[name='feedback[body]'][maxlength='2000']"
    assert_select "input[type=hidden][name='feedback[page]'][value=?]", person_path(@person) + "?tab=sources"
  end

  test "a page on another site is never taken for the page they wrote from" do
    with_operator_email { get new_feedback_path, headers: { "Referer" => "https://evil.example/x" } }
    assert_select "input[type=hidden][name='feedback[page]']", count: 0
  end

  test "sending mails the operator and takes the member back where they were" do
    with_operator_email do
      assert_emails 1 do
        post feedback_path, params: { feedback: { body: "The tree button does nothing", page: person_path(@person) } }
      end
    end
    mail = ActionMailer::Base.deliveries.last
    assert_equal [ "maker@example.com" ], mail.to
    assert_match "The tree button does nothing", mail.text_part.body.to_s
    assert_match "#{person_path(@person)}\n", mail.text_part.body.to_s
    assert_redirected_to person_path(@person)
    assert_equal I18n.t("feedbacks.sent"), flash[:notice]
  end

  test "a page that isn't ours is dropped, and an empty letter isn't sent" do
    with_operator_email do
      assert_emails 1 do
        post feedback_path, params: { feedback: { body: "Hello", page: "//evil.example/x" } }
      end
      assert_no_match "evil.example", ActionMailer::Base.deliveries.last.text_part.body.to_s
      assert_redirected_to root_path

      assert_no_emails do
        post feedback_path, params: { feedback: { body: "   " } }
      end
      assert_response :unprocessable_entity
    end
  end

  test "the letter's words stay out of the job queue and the request log" do
    with_operator_email do
      assert_no_enqueued_jobs { post feedback_path, params: { feedback: { body: "Private words" } } }
    end
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    assert_equal "[FILTERED]", filter.filter("feedback" => { "body" => "Private words" }).dig("feedback", "body")
  end

  test "a guest is asked to sign in" do
    sign_out
    with_operator_email { get new_feedback_path }
    assert_redirected_to new_session_path
  end

  private
    def with_operator_email
      original = Rails.configuration.x.operator
      Rails.configuration.x.operator = original.merge(email: "maker@example.com")
      yield
    ensure
      Rails.configuration.x.operator = original
    end
end
