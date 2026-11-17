module PersonScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_person
  end

  private
    def set_person
      @person = find_in_current_tree(:people, params[:person_id] || params[:id])
    end
end
