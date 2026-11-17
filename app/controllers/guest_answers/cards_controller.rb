class GuestAnswers::CardsController < ApplicationController
  include QuestionLinkAccess, TreeCard

  def show
    send_card @question.tree
  end
end
