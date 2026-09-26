class CitationsController < ApplicationController
  include PersonScoped
  before_action :set_event
  before_action :require_can_edit, only: %i[new create destroy]

  def new
    @citation = Citation.new
    @source   = Source.new
  end

  def create
    @event.cite(source_params, citation_params)
    redirect_back_or_to person_path(@person, tab: "sources"), status: :see_other
  rescue ActiveRecord::RecordInvalid => error
    @citation = Citation.new
    @source   = error.record
    render :new, status: :unprocessable_entity
  end

  def destroy
    @event.citations.find(params[:id]).destroy!
    redirect_back_or_to person_path(@person, tab: "sources"), status: :see_other
  end

  private

  def set_event
    @event = @person.events.find(params[:event_id])
  end

  def source_params
    params.expect(source: %i[title url citation_text author repository source_type])
  end

  def citation_params
    params.fetch(:citation, {}).permit(:page, :text, :date, :confidence)
  end
end
