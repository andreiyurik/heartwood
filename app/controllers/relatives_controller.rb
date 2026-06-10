# Adds a relative (parent / child / partner) to a Person, delegating the graph
# wiring to the domain methods on Person. See docs/features/person-profile.md.
class RelativesController < ApplicationController
  RELATIONS = %w[parent child partner].freeze

  before_action :set_person
  before_action :set_relation

  def new
    @relative = Person.new
  end

  def create
    @relative = @person.public_send("add_#{@relation}", relative_params)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @person, notice: "#{@relation.capitalize} added." }
    end
  end

  private

  def set_person
    @person = Person.find(params[:person_id])
  end

  # Guard the relation against the whitelist before any public_send.
  def set_relation
    @relation = params[:relation].to_s
    head :unprocessable_entity unless RELATIONS.include?(@relation)
  end

  def relative_params
    params.expect(person: %i[given_names surname name_prefix name_suffix nickname sex])
  end
end
