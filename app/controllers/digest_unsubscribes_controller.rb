class DigestUnsubscribesController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :set_current_tree
  # A mail client's one-click unsubscribe (RFC 8058) posts without a form token.
  skip_forgery_protection only: :create
  before_action :set_user

  def show
  end

  def create
    @user.update!(weekly_digest: false)
    redirect_to digest_unsubscribe_path(params[:token]), notice: t("digests.flash.unsubscribed")
  end

  private
    def set_user
      @user = User.find_by_token_for(:digest_unsubscribe, params[:token]) or head :not_found
    end
end
