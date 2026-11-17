module QuestionScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_question
  end

  private
    def set_question
      @question = Current.tree.questions.find(params[:question_id] || params[:id])
    end
end
