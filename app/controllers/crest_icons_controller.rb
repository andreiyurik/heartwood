class CrestIconsController < ApplicationController
  def show
    if Current.tree.crest_image.attached?
      redirect_to rails_representation_path(Current.tree.crest_image.variant(resize_to_fill: [ 64, 64 ]))
    elsif stale?(Current.tree)
      expires_in 1.day, public: false
      render plain: Tree::Card.new(Current.tree).icon_svg, content_type: "image/svg+xml"
    end
  end
end
