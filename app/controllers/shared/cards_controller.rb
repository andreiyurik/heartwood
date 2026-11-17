class Shared::CardsController < ApplicationController
  include SharedAccess, TreeCard

  def show
    send_card @tree
  end
end
