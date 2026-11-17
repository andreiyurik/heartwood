# Pages behind a view-only ShareLink: what a guest may see, whoever is signed in.
module SharedAccess
  extend ActiveSupport::Concern

  included do
    include SecretLink
    before_action :set_share_link
  end

  private
    def set_share_link
      if (@share_link = ShareLink.find_by(token: params[:token]))
        @tree = @share_link.tree
      else
        render "shared/expired", status: :not_found
      end
    end
end
