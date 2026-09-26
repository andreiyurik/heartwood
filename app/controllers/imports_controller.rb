class ImportsController < ApplicationController
  before_action :require_can_edit, only: %i[new create]

  def new
    @import = Current.tree.imports.new
  end

  def create
    @import = Current.tree.imports.new(import_params.merge(user: Current.user))

    if @import.save
      ImportJob.perform_later(@import)
      redirect_to import_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @import = Current.tree.imports.order(:created_at).last
    redirect_to new_import_path unless @import
  end

  private
    def import_params
      params.expect(import: [ :file ])
    end
end
