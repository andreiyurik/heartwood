class SettingsController < ApplicationController
  before_action :require_owner

  def show
  end

  def update
    if Current.tree.update(params.expect(tree: %i[name crest_shape crest_hue crest_symbol crest_image]))
      redirect_to params[:step] == "crest" ? settings_crest_path : settings_path, notice: (t("settings.flash.saved") if params.dig(:tree, :name))
    else
      render :show, status: :unprocessable_entity
    end
  end
end
