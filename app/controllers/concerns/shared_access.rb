# Pages behind a view-only ShareLink: what a guest may see, whoever is signed in.
module SharedAccess
  extend ActiveSupport::Concern

  included do
    allow_unauthenticated_access
    skip_before_action :set_current_tree
    before_action :set_share_link, :keep_out_of_search_and_referrers
  end

  private
    def set_share_link
      @share_link = ShareLink.find_by!(token: params[:token])
      @tree = @share_link.tree
    end

    # The token is the only key, so it must not travel in a Referer header or land in an index.
    def keep_out_of_search_and_referrers
      response.set_header "X-Robots-Tag", "noindex, nofollow"
      response.set_header "Referrer-Policy", "no-referrer"
    end
end
