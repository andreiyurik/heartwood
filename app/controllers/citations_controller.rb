class CitationsController < ApplicationController
  before_action :set_person_and_event

  def new
    @citation = Citation.new
    @source   = Source.new
  end

  def create
    source = Current.tree.sources.find_or_initialize_by(title: source_params[:title].strip) do |s|
      s.url           = source_params[:url].presence
      s.citation_text = source_params[:citation_text].presence
    end

    if source.new_record?
      unless source.save
        @citation = Citation.new
        @source   = source
        render :new, status: :unprocessable_entity and return
      end
    end

    @citation = @event.citations.create!(source: source)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to person_path(@person, tab: "sources") }
    end
  end

  def destroy
    @citation = @event.citations.find(params[:id])
    @citation.destroy!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to person_path(@person, tab: "sources") }
    end
  end

  private

  def set_person_and_event
    @person = Current.tree.people.find(params[:person_id])
    @event  = @person.events.find(params[:event_id])
  end

  def source_params
    params.require(:source).permit(:title, :url, :citation_text)
  end
end
