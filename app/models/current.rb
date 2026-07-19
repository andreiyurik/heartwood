class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :tree
  delegate :user, to: :session, allow_nil: true
end
