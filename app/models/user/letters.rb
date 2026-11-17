# The letters a member can switch off, each with its own one-click unsubscribe token.
module User::Letters
  extend ActiveSupport::Concern

  KINDS = { "digest" => :weekly_digest, "answers" => :answer_emails }.freeze

  included do
    KINDS.each_key { generates_token_for :"#{it}_unsubscribe" }
  end

  class_methods do
    def find_by_unsubscribe_token(kind, token)
      find_by_token_for(:"#{kind}_unsubscribe", token) if KINDS.key?(kind)
    end
  end

  def unsubscribe_token(kind) = generate_token_for(:"#{kind}_unsubscribe")

  def receives?(kind) = public_send(KINDS.fetch(kind))

  def unsubscribe(kind)
    update!(KINDS.fetch(kind) => false)
  end
end
