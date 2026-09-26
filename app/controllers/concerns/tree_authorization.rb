module TreeAuthorization
  extend ActiveSupport::Concern

  private
    def require_can_edit
      head :forbidden unless Current.membership&.can_edit?
    end

    def require_owner
      head :forbidden unless Current.membership&.owner?
    end
end
