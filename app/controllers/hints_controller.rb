class HintsController < ApplicationController
  before_action :set_hint, only: :dismiss
  before_action :require_can_edit, only: %i[scan dismiss]

  def index
    @hints = Current.tree.duplicate_hints.pending
                    .includes(:person_a, :person_b)
                    .order(score: :desc, id: :asc)
  end

  def scan
    DuplicateScanJob.perform_later(Current.tree)
    redirect_to hints_path, notice: t("hints.flash.scanning")
  end

  def dismiss
    @hint.dismissed!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to hints_path, notice: t("hints.flash.dismissed") }
    end
  end

  private

  def set_hint
    @hint = Current.tree.duplicate_hints.find(params[:id])
  end
end
