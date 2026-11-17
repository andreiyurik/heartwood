class QuestionsController < ApplicationController
  include QuestionScoped
  skip_before_action :set_question, only: :index
  before_action :require_can_edit, only: :destroy

  def index
    questions = Current.tree.questions.latest.includes(:person, :asker, :answers, photo: { image_attachment: :blob })
    @open   = questions.open
    @closed = questions.closed.limit(30)
    fresh_when etag: [ Current.tree.questions.maximum(:updated_at), Current.tree.questions.count, Current.tree.people.maximum(:updated_at) ]
  end

  def show
  end

  def destroy
    @question.destroy!
    redirect_to @question.person, notice: t("questions.flash.destroyed")
  end
end
