class ShareLinksController < ApplicationController
  before_action :require_owner

  def create
    if (link = Current.tree.share_link)
      link.renew!
    else
      Current.tree.create_share_link!
    end

    redirect_to tree_memberships_path, notice: t("share_links.flash.created")
  end

  def destroy
    Current.tree.share_link&.destroy!
    redirect_to tree_memberships_path, notice: t("share_links.flash.destroyed")
  end
end
