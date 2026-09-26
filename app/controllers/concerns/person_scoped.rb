module PersonScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_person
  end

  private
    def set_person
      @person = Current.tree.people.visible_to(Current.user).find(params[:person_id] || params[:id])
    end
end
