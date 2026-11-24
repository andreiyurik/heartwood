class GuidesController < ApplicationController
  allow_unauthenticated_access

  before_action :redirect_to_language, only: :index, unless: -> { params[:locale] }

  def index
    @guides = Guide.all
  end

  def show
    @guide = Guide.find(params[:slug])
  end

  private
    def redirect_to_language
      redirect_to guides_path(locale: I18n.locale)
    end
end
