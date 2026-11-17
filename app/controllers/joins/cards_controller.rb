class Joins::CardsController < ApplicationController
  include TreeCard
  allow_unauthenticated_access

  def show
    tree = Tree.find_by!(join_code: params[:join_code])
    send_card tree
  end
end
