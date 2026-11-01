class Edits::ReversionsController < ApplicationController
  before_action :require_can_edit

  def create
    Current.tree.edits.find(params[:edit_id]).revert(by: Current.user)
    redirect_back_or_to edits_path, status: :see_other, notice: t("edits.flash.reverted")
  rescue ActiveRecord::RecordInvalid => error
    redirect_back_or_to edits_path, status: :see_other, alert: t("edits.flash.failed", errors: error.record.errors.full_messages.to_sentence)
  end
end
