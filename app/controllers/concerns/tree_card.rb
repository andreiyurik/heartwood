module TreeCard
  private
    # Messengers refetch a preview rarely; an hour keeps a changed crest from lingering.
    def send_card(tree)
      expires_in 1.hour, public: true
      if stale?(etag: [ tree, tree.crest_image.blob, I18n.locale ])
        send_data Tree::Card.new(tree).png, type: "image/png", disposition: "inline"
      end
    end
end
