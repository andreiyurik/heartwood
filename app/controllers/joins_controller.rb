# Joining a tree via its shareable invite link — once-campfire's join-code
# mechanic, adapted per-tree. Deliberately requires authentication like any
# other controller (no allow_unauthenticated_access): an unauthenticated
# visitor is bounced through the existing sign-in-or-register flow and lands
# back here afterward via Authentication#after_authentication_url. See
# [[collaboration]].
class JoinsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_tree

  def new
    if Current.user
      if Current.user.tree_memberships.exists?(tree: @tree)
        switch_to(@tree)
        redirect_to root_path, notice: t("joins.flash.already_member", tree: @tree.name)
      end
    else
      session[:return_to_after_authenticating] = request.url
      @user = User.new
    end
  end

  def create
    if Current.user
      Current.user.tree_memberships.find_or_create_by!(tree: @tree) { |m| m.role = "editor" }
      switch_to(@tree)
    else
      user = User.sign_up!(user_params, join: @tree)
      start_new_session_for user
      RegistrationMailer.with(locale: I18n.locale).welcome(user).deliver_later
      session.delete(:return_to_after_authenticating)
      switch_to(@tree)
    end
    redirect_to root_path, notice: t("joins.flash.joined", tree: @tree.name)
  rescue ActiveRecord::RecordInvalid => error
    @user = error.record
    render :new, status: :unprocessable_entity
  end

  private
    def set_tree
      @tree = Tree.find_by!(join_code: params[:join_code])
    end

    def user_params
      params.expect(user: %i[name email_address password])
    end

    def switch_to(tree)
      Current.session.update!(current_tree: tree)
    end
end
