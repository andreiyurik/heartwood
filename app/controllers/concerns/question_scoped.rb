module QuestionScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_question
  end

  private
    def set_question
      @question = find_in_current_tree(:questions, params[:question_id] || params[:id])
    end
end
