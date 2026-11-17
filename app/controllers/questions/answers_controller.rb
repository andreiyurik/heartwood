class Questions::AnswersController < ApplicationController
  include QuestionScoped

  def create
    answer = @question.answers.create!(params.expect(answer: [ :body ]).merge(user: Current.user))
    redirect_to question_path(@question, anchor: dom_id(answer))
  rescue ActiveRecord::RecordInvalid
    redirect_to @question, alert: t("answers.flash.blank")
  end

  def destroy
    answer = @question.answers.find(params[:id])
    if Current.membership.can_edit? || answer.user == Current.user
      answer.destroy!
      redirect_to @question, notice: t("answers.flash.destroyed")
    else
      head :forbidden
    end
  end
end
