class EditsController < ApplicationController
  def index
    @edits = Current.tree.edits.sorted.includes(:user, :reverted_by, :person, :subject).limit(200)
  end
end
