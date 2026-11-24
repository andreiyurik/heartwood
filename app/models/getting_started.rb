# The first three steps of a new tree (docs/features/getting-started.md). Reads the tree, stores nothing.
class GettingStarted
  Step = Data.define(:name, :done) do
    alias_method :done?, :done
  end

  def initialize(tree)
    @tree = tree
  end

  def steps
    @steps ||= [
      Step.new(:yourself, people.exists?),
      Step.new(:parents, three_generations?),
      Step.new(:ask, @tree.questions.exists? || @tree.tree_memberships.where.not(role: "owner").exists?)
    ]
  end

  def done? = steps.all?(&:done?)
  def next_step = steps.find { !it.done? }
  def done_count = steps.count(&:done?)

  def parents_for
    people.where.not(id: FamilyChild.select(:person_id)).order(:id).first
  end

  def ask_about
    people.where.not(id: Event.where(eventable_type: "Person", kind: "BIRT").select(:eventable_id)).order(:id).last ||
      people.order(:id).last
  end

  private
    def people = @tree.people

    # Someone whose parent has a parent.
    def three_generations?
      FamilyChild.where(tree: @tree)
        .joins("JOIN family_partners parents ON parents.family_id = family_children.family_id")
        .joins("JOIN family_children grandparents_child ON grandparents_child.person_id = parents.person_id")
        .exists?
    end
end
