class LandingController < ApplicationController
  allow_unauthenticated_access

  def show
    @demo_url = demo_url
  end

  private
    def demo_url
      landing = Rails.configuration.x.landing
      landing.demo_url || (ShareLink.of_owner(landing.demo_owner).first&.then { shared_tree_path(it.token) } if landing.demo_owner)
    end
end
