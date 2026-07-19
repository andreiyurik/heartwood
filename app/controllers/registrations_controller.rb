# Open sign-up: create a User, sign them in, and welcome them. The owner tree is
# bootstrapped on the first authenticated request by TenantScoping. Passwordless
# magic-link auth (fizzy-style) was considered but rejected — see the auth model
# discussion: a self-hostable app shouldn't require SMTP just to log in.
class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  before_action :redirect_authenticated_user
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_registration_path, alert: t("flash.try_later") }

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    if @user.save
      start_new_session_for @user
      RegistrationMailer.with(locale: I18n.locale).welcome(@user).deliver_later
      redirect_to after_authentication_url, notice: t("registrations.flash.welcome", name: @user.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def redirect_authenticated_user
      redirect_to root_path if authenticated?
    end

    def registration_params
      params.expect(user: %i[name email_address password])
    end
end
