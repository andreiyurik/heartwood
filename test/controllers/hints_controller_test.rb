require "test_helper"

class HintsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree = trees(:alpha)
    Current.tree = @tree
    @a = Person.create!(given_names: "John", surname: "Smith", sex: "M", tree: @tree)
    @b = Person.create!(given_names: "John", surname: "Smith", sex: "M", tree: @tree)
    @hint = @tree.duplicate_hints.create!(
      person_a: @a, person_b: @b, score: 80, reasons: %w[surname given_names]
    )
    sign_in_as users(:one)
  end

  teardown { Current.reset }

  test "requires authentication" do
    sign_out
    get hints_url
    assert_redirected_to new_session_url
  end

  test "index lists pending hints" do
    get hints_url
    assert_response :success
    assert_select "#hints .hint-row", 1
  end

  test "index hides resolved hints" do
    @hint.dismissed!
    get hints_url
    assert_response :success
    assert_select ".hint-row", 0
  end

  test "scan enqueues a duplicate scan" do
    assert_enqueued_with(job: DuplicateScanJob) do
      post scan_hints_url
    end
    assert_redirected_to hints_url
  end

  test "dismiss marks the hint and removes its row via turbo stream" do
    patch dismiss_hint_url(@hint), as: :turbo_stream
    assert_response :success
    assert_equal "dismissed", @hint.reload.status
    assert_select "turbo-stream[action=remove][target=?]", "duplicate_hint_#{@hint.id}"
  end

  test "cannot dismiss a hint from another tree" do
    other = trees(:beta).duplicate_hints.create!(
      person_a: Person.create!(sex: "U", tree: trees(:beta)),
      person_b: Person.create!(sex: "U", tree: trees(:beta)),
      score: 80, reasons: []
    )
    patch dismiss_hint_url(other)
    assert_response :not_found
  end
end
