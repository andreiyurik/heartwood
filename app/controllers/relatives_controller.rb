class RelativesController < ApplicationController
  # A whitelist, so no user input reaches public_send as a method name.
  RELATION_METHODS = {
    "parent"  => :add_parent,
    "child"   => :add_child,
    "partner" => :add_partner
  }.freeze

  include PersonScoped
  before_action :set_relation
  before_action :require_can_edit, only: %i[new create]

  def new
    @relative = Person.new
  end

  def create
    @relative = @person.public_send(RELATION_METHODS.fetch(@relation), relative_source)
    # From the tree's panel, land back on the tree page; url_from rejects foreign hosts.
    if (return_url = url_from(params[:return_to]))
      redirect_to return_url, notice: t("family.flash.#{@relation}_added")
    else
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @person, notice: t("family.flash.#{@relation}_added") }
      end
    end
  end

  private

  def relative_source
    if params[:existing_person_id].present?
      Current.tree.people.find(params[:existing_person_id])
    else
      relative_params
    end
  end

  def set_relation
    @relation = params[:relation].to_s
    head :unprocessable_entity unless RELATION_METHODS.key?(@relation)
  end

  def relative_params
    params.expect(person: %i[given_names surname name_prefix name_suffix nickname sex])
  end
end
