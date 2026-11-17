class EditsController < ApplicationController
  def index
    @edits = Current.tree.edits.sorted.includes(:user, :reverted_by, :person, :subject).limit(200)
    fresh_when etag: [ Current.tree.edits.maximum(:updated_at), Current.tree.edits.count ]
  end
end
