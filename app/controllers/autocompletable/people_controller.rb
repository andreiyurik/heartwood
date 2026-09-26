class Autocompletable::PeopleController < ApplicationController
  PURPOSES = %w[relative relationship].freeze

  before_action :set_person
  before_action :set_purpose

  def index
    @matches = @person.relative_candidates(params[:q], user: Current.user, relation: params[:relation])
  end

  private
    def set_person
      @person = Current.tree.people.visible_to(Current.user).find(params[:person_id])
    end

    def set_purpose
      @purpose = params[:for].presence_in(PURPOSES) or head :unprocessable_entity
    end
end
