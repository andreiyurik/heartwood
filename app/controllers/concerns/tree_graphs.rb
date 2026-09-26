module TreeGraphs
  private
    def build_tree_graph(person, mode:, depth:, ghosts: true)
      result = Person::TreeGraph.new(person, mode:, depth:, ghosts:, viewer: Current.user,
                 avatar_url: ->(avatar) { rails_blob_path(avatar, only_path: true) }).build

      @mode    = result[:mode]
      @graph   = result.except(:persons)
      @persons = result[:persons]
    end
end
