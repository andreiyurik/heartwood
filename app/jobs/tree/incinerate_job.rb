class Tree::IncinerateJob < ApplicationJob
  queue_as :default

  def perform(tree)
    tree.incinerate
  end
end
