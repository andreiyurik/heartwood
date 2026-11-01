class Shared::TreesController < ApplicationController
  include SharedAccess

  def show
    @root = @tree.root_person
    return unless @root

    @graph = Person::TreeGraph.new(@root, mode: "descendants", depth: ClanTreesController::CLAN_DEPTH, ghosts: false,
               viewer: nil, avatar_url: ->(avatar) { rails_blob_path(avatar, only_path: true) }).build.except(:persons)
  end
end
