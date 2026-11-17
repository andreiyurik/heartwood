class Questions::ClosuresController < ApplicationController
  include QuestionScoped
  before_action :require_can_edit

  def create
    @question.close(by: Current.user)
    redirect_to @question, notice: t("questions.flash.closed")
  end
end
