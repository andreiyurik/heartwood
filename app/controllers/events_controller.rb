class EventsController < ApplicationController
  include PersonScoped
  before_action :set_event, only: %i[edit update destroy]
  before_action :require_can_edit, only: %i[new create edit update destroy]

  def new
    @event = @person.events.new(kind: params[:kind])
  end

  def edit
  end

  def create
    @event = @person.events.new(event_params)
    if @event.save
      redirect_to person_path(@person, anchor: dom_id(@event)), status: :see_other, notice: t("events.flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @event.update(event_params)
      redirect_to person_path(@person, anchor: dom_id(@event)), status: :see_other, notice: t("events.flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy!
    redirect_back_or_to @person, status: :see_other, notice: t("events.flash.destroyed")
  end

  private

  def set_event
    @event = @person.events.find(params[:id])
  end

  def event_params
    params.expect(event: %i[kind date_raw value place_name place_latitude place_longitude])
  end
end
