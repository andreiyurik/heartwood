# Smart hints — the review queue of suggested duplicate people. The user decides:
# dismiss here, merge later (v2). We only ever suggest. See DuplicateFinder.
class HintsController < ApplicationController
  before_action :set_hint, only: :dismiss

  def index
    @hints = Current.tree.duplicate_hints.pending
                    .includes(:person_a, :person_b)
                    .order(score: :desc, id: :asc)
  end

  # Kick off a rescan by hand (imports do this automatically).
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
