class AccountsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :destroy,
             with: -> { redirect_to account_path, alert: t("flash.try_later") }

  def show
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
end
