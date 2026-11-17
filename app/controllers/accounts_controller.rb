class AccountsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :destroy,
             with: -> { redirect_to account_path, alert: t("flash.try_later") }

  def show
  end

  def update
    if Current.user.update(user_params)
      Current.user.sessions.where.not(id: Current.session.id).destroy_all if Current.user.saved_change_to_password_digest?
      redirect_to account_path, notice: t("accounts.flash.updated")
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    if Current.user.authenticate(params[:password].to_s)
      Current.user.destroy!
      cookies.delete(:session_id)
      redirect_to new_session_path, notice: t("accounts.flash.deleted")
    else
      flash.now[:alert] = t("accounts.flash.wrong_password")
      render :show, status: :unprocessable_entity
    end
  end

  private
    # The current password guards the two things that would let someone else take the account over.
    def user_params
      attributes = params.expect(user: %i[name email_address password password_challenge weekly_digest]).compact_blank
      sensitive  = attributes[:password].present? ||
        (attributes.key?(:email_address) && attributes[:email_address].to_s.strip.downcase != Current.user.email_address)
      sensitive ? attributes.reverse_merge(password_challenge: "") : attributes.except(:password_challenge)
    end
end
