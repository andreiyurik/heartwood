module User::PrivacyConsent
  extend ActiveSupport::Concern

  included do
    validates :privacy_consent, acceptance: { allow_nil: false }, on: :sign_up
    before_create :stamp_privacy_consent, if: :privacy_consent_given?
  end

  private
    def privacy_consent_given?
      ActiveModel::Type::Boolean.new.cast(privacy_consent)
    end

    def stamp_privacy_consent
      self.privacy_consented_at = Time.current
      self.privacy_consent_version = Legal::VERSION
    end
end
