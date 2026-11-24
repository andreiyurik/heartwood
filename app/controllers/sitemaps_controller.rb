class SitemapsController < ApplicationController
  allow_unauthenticated_access

  def show
    @guides = Guide.indexed? ? Guide.all : []
  end
end
