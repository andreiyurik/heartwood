# "How are we related?" — names the kinship between a focus Person and another
# person picked from a type-ahead. Pure read; the naming lives in Person.
class RelationshipsController < ApplicationController
  before_action :set_person

  def show
    @other = Current.tree.people.visible_to(Current.user).find_by(id: params[:with])
    @relationship = @person.relationship_to(@other) if @other
  end

  # Combobox lookup: anyone in this tree (the focus person aside) is fair game —
  # unlike the relatives picker we don't exclude existing kin.
  def search
    @matches = candidate_people
  end

  private

  def set_person
    @person = Current.tree.people.find(params[:person_id])
  end

  def candidate_people
    query = params[:q].to_s.strip
    return Person.none if query.blank?

    Current.tree.people
           .search(query, user: Current.user)
           .where.not(id: @person.id)
           .order(:surname, :given_names)
           .limit(8)
  end
end
