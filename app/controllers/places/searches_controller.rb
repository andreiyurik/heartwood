class Places::SearchesController < ApplicationController
  def show
    @matches = Current.tree.places.search(params[:q]).limit(8)
    render layout: false
  end
end
