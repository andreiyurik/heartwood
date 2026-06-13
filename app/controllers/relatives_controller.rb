# Adds a relative (parent / child / partner) to a Person, delegating the graph
# wiring to the domain methods on Person. See docs/features/person-profile.md.
class RelativesController < ApplicationController
  RELATIONS = %w[parent child partner].freeze

  before_action :set_person
  before_action :set_relation

  def new
    @relative = Person.new
  end

  # Combobox lookup: people in this tree who could be linked as @relation,
  # excluding the focus person and anyone already in that relation.
  def search
    @matches = candidate_people
  end

  def create
    @relative = @person.public_send("add_#{@relation}", relative_source)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @person, notice: t("family.flash.#{@relation}_added") }
    end
  end

  private

  def set_person
    @person = Current.tree.people.find(params[:person_id])
  end

  # Link an existing person (tree-scoped — 404 across tenants) when one is
  # picked from the combobox; otherwise build a new person from the form.
  def relative_source
    if params[:existing_person_id].present?
      Current.tree.people.find(params[:existing_person_id])
    else
      relative_params
    end
  end

  # Guard the relation against the whitelist before any public_send.
  def set_relation
    @relation = params[:relation].to_s
    head :unprocessable_entity unless RELATIONS.include?(@relation)
  end

  def relative_params
    params.expect(person: %i[given_names surname name_prefix name_suffix nickname sex])
  end

  def candidate_people
    query = params[:q].to_s.strip
    return Person.none if query.blank?

    Current.tree.people
           .search(query, user: Current.user)
           .where.not(id: excluded_ids)
           .order(:surname, :given_names)
           .limit(8)
  end

  # The focus person plus anyone already linked in this relation — they should
  # not show up as fresh candidates.
  def excluded_ids
    already = case @relation
              when "parent"  then @person.parents
              when "child"   then @person.children
              when "partner" then @person.partners
              else []
              end
    [ @person.id, *already.map(&:id) ]
  end
end
