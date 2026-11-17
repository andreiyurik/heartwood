# The token in the URL is the only key, so it must not travel in a Referer header or land in an index.
module SecretLink
  extend ActiveSupport::Concern

  included do
    allow_unauthenticated_access
    skip_before_action :set_current_tree
    before_action :keep_out_of_search_and_referrers
  end

  private
    def keep_out_of_search_and_referrers
      response.set_header "X-Robots-Tag", "noindex, nofollow"
      response.set_header "Referrer-Policy", "no-referrer"
    end
end
