class Hints::DismissalsController < ApplicationController
  before_action :require_can_edit

  def create
    Current.tree.duplicate_hints.find(params[:hint_id]).dismissed!
    redirect_to hints_path, status: :see_other, notice: t("hints.flash.dismissed")
  end
end
