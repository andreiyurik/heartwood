class CommentsController < ApplicationController
  include PersonScoped
  before_action :set_comment, only: %i[edit update destroy]
  before_action :require_author, only: %i[edit update]

  def create
    comment = @person.comments.create!(comment_params.merge(user: Current.user))
    redirect_to person_path(@person, anchor: dom_id(comment))
  rescue ActiveRecord::RecordInvalid
    redirect_to person_path(@person, anchor: "comments"), alert: t("comments.flash.blank")
  end

  def edit
  end

  def update
    @comment.update!(comment_params)
    redirect_to person_path(@person, anchor: dom_id(@comment))
  end

  def destroy
    if @comment.deletable_by?(Current.user)
      @comment.destroy!
      redirect_to person_path(@person, anchor: "comments"), status: :see_other
    else
      head :forbidden
    end
  end

  private
    def set_comment
      @comment = @person.comments.find(params[:id])
    end

    def require_author
      head :forbidden unless @comment.editable_by?(Current.user)
    end

    def comment_params
      params.expect(comment: [ :body ])
    end
end
