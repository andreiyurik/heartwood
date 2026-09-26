class RelationshipsController < ApplicationController
  include PersonScoped

  def show
    @other = Current.tree.people.visible_to(Current.user).find_by(id: params[:with])
    @relationship = @person.relationship_to(@other) if @other
  end
end
