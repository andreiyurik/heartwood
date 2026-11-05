class MapsController < ApplicationController
  before_action -> { head :not_found }, unless: -> { Maps.tiles? }

  def show
  end
end
