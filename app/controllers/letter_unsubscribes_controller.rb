class LetterUnsubscribesController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :set_current_tree
  # A mail client's one-click unsubscribe (RFC 8058) posts without a form token; the signed token is the proof.
  skip_forgery_protection only: :create
  before_action :set_user

  def show
  end

  def create
    @user.unsubscribe(params[:kind])
    redirect_to letter_unsubscribe_path(params[:kind], params[:token]), notice: t("letters.flash.unsubscribed")
  end

  private
    def set_user
      @user = User.find_by_unsubscribe_token(params[:kind], params[:token]) or head :not_found
    end
end
