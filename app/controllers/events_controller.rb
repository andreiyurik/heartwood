# A Person's life events (birth, death, occupation, ...). Polymorphic Event rows;
# this controller scopes them to a Person. See docs/domain/event.md.
class EventsController < ApplicationController
  before_action :set_person
  before_action :set_event, only: %i[edit update destroy]

  def new
    @event = @person.events.new(kind: params[:kind])
  end

  def edit
  end

  def create
    @event = @person.events.new(event_params)
    if @event.save
      respond_to_change :created
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @event.update(event_params)
      respond_to_change :updated
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy!
    respond_to_change :destroyed
  end

  private

  def set_person
    @person = Current.tree.people.find(params[:person_id])
  end

  def set_event
    @event = @person.events.find(params[:id])
  end

  def event_params
    params.expect(event: %i[kind date_raw value])
  end

  # Both create/update/destroy refresh the events box (turbo) or redirect (html).
  def respond_to_change(key)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @person, notice: t("events.flash.#{key}") }
    end
  end
end
