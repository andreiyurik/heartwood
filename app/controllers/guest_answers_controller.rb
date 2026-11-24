class GuestAnswersController < ApplicationController
  include QuestionLinkAccess
  before_action :redirect_members_to_the_question

  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to question_link_path(params[:token]), alert: t("guest_answers.too_many") }

  def new
    @answer = @question.answers.build(author_name: Current.user&.name)
  end

  def create
    @answer = @question.answers.build(params.expect(answer: %i[body author_name photo]).merge(user: Current.user))

    if @question.closed?
      redirect_to question_link_path(@question.token)
    elsif @answer.save
      redirect_to question_link_path(@question.token), flash: { answered: true }
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def redirect_members_to_the_question
      redirect_to question_path(@question) if Current.user&.trees&.exists?(@question.tree_id)
    end
end
