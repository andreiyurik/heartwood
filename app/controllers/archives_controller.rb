class ArchivesController < ApplicationController
  rate_limit to: 5, within: 1.hour, only: :create, with: -> { redirect_back_or_to root_path, alert: t("flash.try_later") }

  def create
    archive = Current.tree.archives.create!(user: Current.user)
    archive.build_later
    redirect_to archive
  end

  def show
    @archive = Current.user.archives.find(params[:id])
  end
end
