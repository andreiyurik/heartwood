require "test_helper"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tree   = trees(:alpha)
    @person = Person.create!(given_names: "Ada", surname: "Lovelace", sex: "F", tree: @tree)
    sign_in_as users(:one)
    Current.tree = @tree
  end

  test "requires authentication" do
    sign_out
    get people_url
    assert_redirected_to new_session_url
  end

  test "lists people when signed in" do
    get people_url
    assert_response :success
    assert_select "body", /Lovelace/
  end

  test "lists people as rows with the name over a metadata line" do
    Event.create!(kind: "BIRT", eventable: @person, tree: @tree, date_raw: "1815", date_start: Date.new(1815, 12, 10))
    get people_url
    assert_select ".person-row" do
      assert_select ".person-row__name a[href=?]", person_path(@person), text: "Ada Lovelace"
      assert_select ".person-row__meta", text: /1815/
      assert_select "hr.separator", count: 0
    end
  end

  test "shows a person" do
    get person_url(@person)
    assert_response :success
    assert_select "body", /Ada Lovelace/
  end

  test "panel renders the compact card inside the person-panel frame" do
    Event.create!(kind: "BIRT", eventable: @person, tree: @tree, date_raw: "1815",
                  date_start: Date.new(1815, 12, 10), place_name: "London")
    get person_panel_url(@person)
    assert_response :success
    assert_select "turbo-frame#person-panel" do
      assert_select ".person-panel-name", text: "Ada Lovelace"
      assert_select ".person-panel-field dd", text: /1815 · London/
    end
  end

  test "the profile reads record-first: events and family before the biography, no facts block" do
    place = Place.create!(name: "London", latitude: 51.5, longitude: -0.12, tree: @tree)
    Event.create!(kind: "BIRT", eventable: @person, tree: @tree, place: place)
    get person_url(@person)
    assert_select ".profile-tab", count: 0
    assert_select ".facts", count: 0
    assert_select ".relationship-tool", count: 0

    sections = %w[events family biography sources memories map]
    sections.each do |section|
      assert_select ".profile-nav a[href='##{section}']"
      assert_select "section##{section}"
    end
    positions = sections.map { |section| @response.body.index(%(id="#{section}")) }
    assert_equal positions.sort, positions, "sections are out of order"
  end

  test "the metadata line carries nickname and years" do
    @person.update!(nickname: "Countess")
    Event.create!(kind: "BIRT", eventable: @person, tree: @tree, date_raw: "1815", date_start: Date.new(1815, 12, 10))
    get person_url(@person)
    assert_select ".page-header__meta", text: "Countess · 1815"
  end

  test "the metadata line is left out when there is nothing to say" do
    @person.update!(sex: "U")
    Event.create!(kind: "DEAT", eventable: @person, tree: @tree, date_raw: "")
    get person_url(@person)
    assert_select ".page-header__meta", count: 0
  end

  test "family lists relatives as people rows and keeps empty groups quiet" do
    parent = @person.add_parent(given_names: "Anne", surname: "Milbanke", sex: "F")
    get person_url(@person)
    assert_select "#family .person-row .person-row__name a[href=?]", person_path(parent), text: "Anne Milbanke"
    assert_select "#family", text: /#{I18n.t("family.none")}/, count: 0
    assert_select "#family h3", text: I18n.t("family.siblings"), count: 0
    assert_select "#family a[href=?]", new_person_relative_path(@person, relation: "child")
  end

  test "a viewer sees an empty family group named, not an add button" do
    viewer = User.create!(name: "Viewer Vee", email_address: "vee@example.com", password: "password")
    TreeMembership.create!(user: viewer, tree: @tree, role: "viewer")
    sign_in_as viewer
    get person_url(@person)
    assert_select "#family", text: /#{I18n.t("family.none")}/
    assert_select "#family a[href=?]", new_person_relative_path(@person, relation: "child"), count: 0
  end

  test "empty sources say what a source is; empty memories offer to add photos" do
    get person_url(@person)
    assert_select "section#sources .blank-slate"
    assert_select "section#memories form.photo-add"
  end

  test "the profile's more menu offers the relationship calculator and deletion for editors" do
    get person_url(@person)
    assert_select "#header details.action-menu" do
      assert_select "a[href=?]", person_relationship_path(@person)
      assert_select "form[action=?] input[name=_method][value=delete]", person_path(@person)
    end
  end

  test "viewers get the relationship calculator but not deletion in the more menu" do
    viewer = User.create!(name: "Viewer Vee", email_address: "vee@example.com", password: "password")
    TreeMembership.create!(user: viewer, tree: @tree, role: "viewer")
    sign_in_as viewer
    get person_url(@person)
    assert_select "#header details.action-menu a[href=?]", person_relationship_path(@person)
    assert_select "#header form[action=?] input[name=_method][value=delete]", person_path(@person), count: 0
  end

  test "a stray tab param is ignored" do
    get person_url(@person, tab: "hacker/../../etc")
    assert_response :success
    assert_select "section#events"
  end

  test "index search filters by name" do
    hidden = Person.create!(given_names: "Turing", surname: "Alan", sex: "M", tree: @tree)
    get people_url(q: "Lovelace")
    assert_select "body", /Lovelace/
    assert_select "body", text: /Turing/, count: 0
  end

  test "index sex filter narrows results" do
    get people_url(sex: "F")
    assert_select "body", /Lovelace/
  end

  test "index defaults to surname_asc when sort is absent or unknown" do
    get people_url
    assert_select "select#sort option[selected][value=surname_asc]"

    get people_url(sort: "not-a-real-option")
    assert_select "select#sort option[selected][value=surname_asc]"
  end

  test "index honors a whitelisted sort param" do
    get people_url(sort: "created_desc")
    assert_select "select#sort option[selected][value=created_desc]"
  end

  test "index renders search form" do
    get people_url
    assert_select "form[data-controller='autocomplete auto-submit']"
    assert_select "input[type='search']"
  end

  test "creates a person" do
    assert_difference "Person.count", 1 do
      post people_url, params: { person: { given_names: "Grace", surname: "Hopper", sex: "F" } }
    end
    assert_redirected_to person_url(Person.last)
    assert_equal "Hopper", Person.last.surname
  end

  test "create with invalid params re-renders the form (422)" do
    assert_no_difference "Person.count" do
      post people_url, params: { person: { given_names: "Bad", sex: "Z" } }
    end
    assert_response :unprocessable_entity
  end

  test "updates a person" do
    patch person_url(@person), params: { person: { nickname: "The Countess" } }
    assert_redirected_to person_url(@person)
    assert_equal "The Countess", @person.reload.nickname
  end

  test "update with invalid params re-renders the form (422) and leaves the record unchanged" do
    patch person_url(@person), params: { person: { sex: "Z" } }
    assert_response :unprocessable_entity
    assert_equal "F", @person.reload.sex
  end

  test "updates a person's biography" do
    patch person_url(@person), params: { person: { biography: "Born by the sea." } }
    assert_redirected_to person_url(@person)
    assert_equal "Born by the sea.", @person.reload.biography.to_plain_text
  end

  test "show renders the biography on the profile" do
    @person.update!(biography: "A life of quiet adventure.")
    get person_url(@person)
    assert_response :success
    assert_select ".biography", text: /A life of quiet adventure/
  end

  test "edit renders the Lexxy rich-text editor for the biography" do
    get edit_person_url(@person)
    assert_response :success
    assert_select "lexxy-editor"
  end

  test "destroys a person" do
    assert_difference "Person.count", -1 do
      delete person_url(@person)
    end
    assert_redirected_to people_url
  end

  test "a viewer cannot create, edit, or destroy a person" do
    viewer = User.create!(name: "Viewer", email_address: "viewer@example.com", password: "password")
    TreeMembership.create!(user: viewer, tree: @tree, role: "viewer")
    sign_out
    sign_in_as viewer
    Current.tree = @tree

    assert_no_difference "Person.count" do
      post people_url, params: { person: { given_names: "New", surname: "Guy", sex: "U" } }
    end
    assert_response :forbidden

    patch person_url(@person), params: { person: { nickname: "Sneaky" } }
    assert_response :forbidden
    assert_nil @person.reload.nickname

    assert_no_difference "Person.count" do
      delete person_url(@person)
    end
    assert_response :forbidden

    # reads still work
    get people_url
    assert_response :success
    get person_url(@person)
    assert_response :success
  end

  test "an empty tree shows one blank slate with two ways to begin" do
    @tree.people.destroy_all
    get people_url
    assert_select ".blank-slate" do
      assert_select "a[href=?]", new_person_path(yourself: true)
      assert_select "a[href=?]", new_import_path
    end
    assert_select "form.search-form", count: 0
    assert_select "#header form[action=?]", export_path, count: 0
    assert_select "nav.sections", count: 0
  end

  test "a tree with people keeps search, export and navigation" do
    get people_url
    assert_select ".blank-slate", count: 0
    assert_select "form.search-form"
    assert_select "#header .header-actions form[action=?]", export_path, count: 0
    assert_select "#header details.account-menu form[action=?] button", export_path, text: I18n.t("exports.create")
    assert_select "#header details.account-menu a[href=?]", new_import_path, text: I18n.t("imports.title")
    assert_select "nav.sections a", count: 3
  end

  test "a viewer gets export but not import in the account menu" do
    viewer = User.create!(name: "Vi", email_address: "vi@example.com", password: "password")
    TreeMembership.create!(user: viewer, tree: @tree, role: "viewer")
    sign_out
    sign_in_as viewer
    get people_url
    assert_select "#header details.account-menu form[action=?]", export_path
    assert_select "#header details.account-menu a[href=?]", new_import_path, count: 0
  end

  test "a viewer of an empty tree is told to wait, not offered actions" do
    @tree.people.destroy_all
    viewer = User.create!(name: "Vi", email_address: "vi@example.com", password: "password")
    TreeMembership.create!(user: viewer, tree: @tree, role: "viewer")
    sign_out
    sign_in_as viewer
    get people_url
    assert_select ".blank-slate a", count: 0
    assert_select ".blank-slate", text: /#{I18n.t("people.empty_viewer")}/
  end

  test "adding yourself prefills the form from your name" do
    users(:one).update!(name: "Anna Maria Karenina")
    get new_person_url(yourself: true)
    assert_select "input[name='person[given_names]'][value=?]", "Anna Maria"
    assert_select "input[name='person[surname]'][value=?]", "Karenina"
  end

  test "the person form shows the essentials and tucks the rest into details" do
    get new_person_url
    assert_select "form.form > .field input[name='person[given_names]']"
    assert_select "form.form > .field input[name='person[surname]']"
    assert_select "form.form > .field select[name='person[sex]']"
    assert_select "form.form details.more-fields" do
      assert_select "input[name='person[name_prefix]']"
      assert_select "input[name='person[name_suffix]']"
      assert_select "input[name='person[nickname]']"
    end
    assert_select "form.form > .field input[name='person[nickname]']", count: 0
  end

  test "the form keeps details open when a hidden field has an error or a value" do
    @person.update!(nickname: "Countess")
    get edit_person_url(@person)
    assert_select "details.more-fields[open]"
  end

  test "an editor changes the photo from the profile header on file change" do
    get person_url(@person)
    assert_select "form.avatar-form[action=?][data-controller=auto-submit]", person_path(@person) do
      assert_select "input[type=file][name='person[avatar]'][data-action='change->auto-submit#submit']"
    end
  end

  test "a viewer cannot change the photo from the profile" do
    viewer = User.create!(name: "Vi", email_address: "vi@example.com", password: "password")
    TreeMembership.create!(user: viewer, tree: @tree, role: "viewer")
    sign_out
    sign_in_as viewer
    get person_url(@person)
    assert_select "form.avatar-form", count: 0
  end

  test "updating with only a photo keeps the rest" do
    png = Rack::Test::UploadedFile.new(StringIO.new("\x89PNG\r\n\x1a\n" + "\x00" * 100), "image/png", original_filename: "a.png")
    patch person_url(@person), params: { person: { avatar: png } }
    assert_redirected_to person_url(@person)
    assert @person.reload.avatar.attached?
    assert_equal "Ada", @person.given_names
  end

  test "search fields are labelled" do
    get people_url
    assert_select "input[type=search][name=q][aria-label=?]", I18n.t("people.search_placeholder")
    get new_person_relative_url(@person, relation: "parent")
    assert_select "input[type=search][name=q][aria-label]"
    get person_relationship_url(@person)
    assert_select "input[type=search][name=q][aria-label]"
  end

  test "the person form stacks the biography under its own label, full width" do
    get edit_person_url(@person)
    assert_select ".more-fields .field--biography.field--stacked label[for=person_biography]"
  end

  test "the profile's edit action is labelled, not just an icon" do
    get person_url(@person)
    assert_select "#header .header-actions a[href=?]", edit_person_path(@person), text: /#{I18n.t("people.edit_button")}/
  end

  test "the map section appears only when one of the person's events is located" do
    get person_url(@person)
    assert_select "section#map", count: 0

    place = Place.create!(name: "London", latitude: 51.5, longitude: -0.12, tree: @tree)
    Event.create!(kind: "BIRT", eventable: @person, tree: @tree, place: place)
    get person_url(@person)
    assert_select "section#map [data-controller=map]"
  end

  test "initials avatars take a hue from the name" do
    get people_url
    assert_select ".person-row .avatar--initials[style*='--avatar-hue']"
  end

  test "the owner is one click from inviting relatives" do
    get people_url
    assert_select ".header-actions a[href=?]", tree_memberships_path(anchor: "invite"), text: /#{I18n.t("people.invite")}/
  end

  test "an editor is not offered the owner's invite link" do
    tree_memberships(:one_alpha).update!(role: "editor")
    get people_url
    assert_select "a[href=?]", tree_memberships_path(anchor: "invite"), count: 0
  end

  test "the form asks for what a relative knows: names, surname at birth, born, died" do
    get new_person_url
    %w[given_names surname birth_surname born died].each { assert_select "form input[name='person[#{it}]']" }
    assert_select "form input[type=checkbox][name='person[unnamed]']"
  end

  test "creating a person with years records the events in the same step" do
    post people_url, params: { person: { given_names: "Grace", surname: "Hopper", sex: "F", born: "1906", died: "1992", unnamed: "0" } }
    person = Person.find_by!(surname: "Hopper")
    assert_redirected_to person
    assert_equal "1906 – 1992", person.life_years
  end

  test "an empty form adds nobody" do
    assert_no_difference "Person.count" do
      post people_url, params: { person: { given_names: "", surname: "", sex: "U", unnamed: "0" } }
    end
    assert_response :unprocessable_entity
    assert_select ".errors", text: /#{I18n.t("activerecord.errors.models.person.attributes.base.unnamed")}/
  end

  test "an unknown ancestor can still be added on purpose" do
    assert_difference "Person.count", 1 do
      post people_url, params: { person: { given_names: "", surname: "", sex: "F", unnamed: "1" } }
    end
  end

  test "the profile shows the surname at birth and no sex in the metadata line" do
    @person.update!(birth_surname: "Byron")
    get person_url(@person)
    assert_select ".page-header__meta", text: /#{I18n.t("people.nee", surname: "Byron")}/
    assert_select ".page-header__meta", text: /#{I18n.t("people.sex.F")}/, count: 0
  end

  test "the list says how many people the tree holds" do
    get people_url
    assert_select ".page-header__meta", text: I18n.t("trees.people", count: 1)
  end

  test "a free-form event leads with what happened, not with the word Event" do
    Event.create!(kind: "EVEN", eventable: @person, tree: @tree, date_raw: "1833", value: "Met Charles Babbage")
    get person_url(@person)
    assert_select ".event-row .event-kind", text: "Met Charles Babbage"
    assert_select ".event-row", text: /#{I18n.t("events.kinds.EVEN")}/, count: 0
  end

  test "the list costs the same number of queries for three people as for twelve" do
    grow_tree_to 3
    small = count_queries { get people_url }
    grow_tree_to 12
    large = count_queries { get people_url }

    assert_equal small, large
  end

  test "a long list arrives a page at a time" do
    grow_tree_to PeopleController::PER_PAGE + 5
    get people_url
    assert_select ".people-list li.person-row", PeopleController::PER_PAGE
    assert_select "turbo-frame#people_page_2[loading=lazy][src*='page=2']"

    get people_url(page: 2)
    assert_select "turbo-frame#people_page_2 li.person-row", 5
    assert_select "turbo-frame#people_page_3", count: 0
  end

  private
    def grow_tree_to(size)
      (size - @tree.people.count).times do |i|
        person = Person.create!(given_names: "Person #{i}", surname: "Test", sex: "U", tree: @tree)
        person.events.create!(kind: "BIRT", date_raw: (1800 + i).to_s)
      end
    end

    def count_queries(&block)
      count = 0
      counter = ->(*, payload) { count += 1 unless payload[:name].in?(%w[SCHEMA TRANSACTION]) || payload[:cached] }
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
      count
    end
end
