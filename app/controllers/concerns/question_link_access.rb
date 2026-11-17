# Pages behind a question's own link: the question and nothing else of the tree.
module QuestionLinkAccess
  extend ActiveSupport::Concern

  included do
    include SecretLink
    before_action :set_question_by_token
  end

  private
    def set_question_by_token
      @question = Question.find_by(token: params[:token]) or render "shared/expired", status: :not_found
    end
end
