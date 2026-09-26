class HintsController < ApplicationController
  def index
    @hints = Current.tree.duplicate_hints.pending
                    .includes(:person_a, :person_b)
                    .order(score: :desc, id: :asc)
  end
end
