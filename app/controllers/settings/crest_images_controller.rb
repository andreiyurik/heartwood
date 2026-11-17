class Settings::CrestImagesController < ApplicationController
  before_action :require_owner

  def destroy
    Current.tree.crest_image.purge_later
    redirect_to settings_path, status: :see_other
  end
end
