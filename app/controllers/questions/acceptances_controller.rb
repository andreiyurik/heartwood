class Questions::AcceptancesController < ApplicationController
  include QuestionScoped
  before_action :require_can_edit, :set_answer

  def new
  end

  def create
    @question.accept(@answer, into: params[:into], text: params[:text].to_s.strip, by: Current.user)
    redirect_to @question.person, notice: t("questions.flash.accepted")
  rescue ArgumentError, ActiveRecord::RecordInvalid
    redirect_to @question, alert: t("questions.flash.not_accepted")
  end

  private
    def set_answer
      @answer = @question.answers.find(params[:answer_id])
    end
end
