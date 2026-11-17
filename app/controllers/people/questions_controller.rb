class People::QuestionsController < ApplicationController
  include PersonScoped
  before_action :require_can_edit

  def new
    @question = @person.questions.build(photo: photo)
  end

  def create
    @question = @person.questions.build(question_params.merge(asker: Current.user, photo: photo))
    if @question.save
      redirect_to @question
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def photo
      photo_id = params[:photo_id] || params.dig(:question, :photo_id)
      @person.photos.find(photo_id) if photo_id.present?
    end

    def question_params
      params.expect(question: [ :body ])
    end
end
