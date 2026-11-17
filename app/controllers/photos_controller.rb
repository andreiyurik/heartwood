class PhotosController < ApplicationController
  include PersonScoped
  before_action :require_can_edit
  before_action :set_photo, only: %i[edit update destroy]

  def create
    photos = Array(params[:photos]).compact_blank.map { @person.photos.build(image: it) }

    if photos.any? && photos.all?(&:valid?)
      photos.each(&:save!)
      redirect_to person_path(@person, anchor: "memories"), notice: t("photos.flash.created", count: photos.size)
    else
      redirect_to person_path(@person, anchor: "memories"),
        alert: photos.flat_map { it.errors.full_messages }.first || t("photos.flash.none")
    end
  end

  def edit
  end

  def update
    @photo.update!(params.expect(photo: %i[caption taken]))
    redirect_to person_path(@person, anchor: dom_id(@photo)), status: :see_other
  end

  def destroy
    @photo.destroy!
    redirect_to person_path(@person, anchor: "memories"), status: :see_other, notice: t("photos.flash.destroyed")
  end

  private
    def set_photo
      @photo = @person.photos.find(params[:id])
    end
end
