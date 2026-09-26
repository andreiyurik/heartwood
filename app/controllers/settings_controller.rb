class SettingsController < ApplicationController
  before_action :require_owner

  def show
  end

  def update
    if Current.tree.update(params.expect(tree: :name))
      redirect_to settings_path, notice: t("settings.flash.saved")
    else
      render :show, status: :unprocessable_entity
    end
  end
end
