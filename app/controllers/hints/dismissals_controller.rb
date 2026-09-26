class Hints::DismissalsController < ApplicationController
  before_action :require_can_edit

  def create
    @hint = Current.tree.duplicate_hints.find(params[:hint_id])
    @hint.dismissed!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to hints_path, notice: t("hints.flash.dismissed") }
    end
  end
end
