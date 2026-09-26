class PeopleController < ApplicationController
  TABS = %w[details sources memories timeline map].freeze

  before_action :set_person, only: %i[show panel edit update destroy]
  before_action :require_can_edit, only: %i[new create edit update destroy]

  def index
    @q      = params[:q].to_s.strip
    @sex    = params[:sex].to_s
    @sort   = Person::SORT_OPTIONS.include?(params[:sort]) ? params[:sort] : Person::SORT_OPTIONS.first
    @people = Current.tree.people
                     .search(@q, user: Current.user)
                     .then { |r| Person::SEXES.include?(@sex) ? r.where(sex: @sex) : r }
                     .sorted(@sort)
  end

  def show
    @tab = TABS.include?(params[:tab]) ? params[:tab] : "details"
  end

  def panel
  end

  def new
    @person = params[:yourself] ? Person.named_like(Current.user) : Person.new
  end

  def edit
  end

  def create
    @person = Current.tree.people.build(person_params)
    if @person.save
      redirect_to @person, notice: t("people.flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @person.update(person_params)
      redirect_to @person, notice: t("people.flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @person.destroy!
    redirect_to people_url, notice: t("people.flash.destroyed")
  end

  private

  def set_person
    @person = Current.tree.people.visible_to(Current.user).find(params[:id])
  end

  def person_params
    params.expect(person: %i[given_names surname name_prefix name_suffix nickname sex avatar biography])
  end
end
