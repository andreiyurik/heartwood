class DigestMailer < ApplicationMailer
  helper :application

  def weekly(membership, since: WeeklyDigest::WINDOW.ago)
    @digest = WeeklyDigest.new(membership, since: since)
    @user   = membership.user
    @unsubscribe_url = digest_unsubscribe_url(@user.generate_token_for(:digest_unsubscribe))

    headers "List-Unsubscribe" => "<#{@unsubscribe_url}>", "List-Unsubscribe-Post" => "List-Unsubscribe=One-Click"

    I18n.with_locale(@user.locale.presence || I18n.default_locale) do
      mail to: @user.email_address, subject: t("digests.subject", tree: membership.tree.name)
    end
  end
end
