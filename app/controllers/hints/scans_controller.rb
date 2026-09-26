class Hints::ScansController < ApplicationController
  before_action :require_can_edit

  def create
    DuplicateScanJob.perform_later(Current.tree)
    redirect_to hints_path, notice: t("hints.flash.scanning")
  end
end
