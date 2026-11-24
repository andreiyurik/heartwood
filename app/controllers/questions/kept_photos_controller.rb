class Questions::KeptPhotosController < ApplicationController
  include QuestionScoped
  before_action :require_can_edit

  def create
    answer = @question.answers.find(params[:answer_id])
    answer.keep_photo! if answer.photo.attached?
    redirect_to question_path(@question, anchor: dom_id(answer)), notice: t("answers.flash.photo_kept", name: @question.person.display_name)
  end
end
