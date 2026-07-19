class ExportsController < ApplicationController
  def create
    ged = Gedcom::Writer.new(Current.tree, user: Current.user).to_gedcom
    send_data ged, filename: "tree.ged", type: "text/plain", disposition: "attachment"
  end
end
