class Shared::PeopleController < ApplicationController
  include SharedAccess

  def show
    @person = @share_link.people.find(params[:id])
  end
end
