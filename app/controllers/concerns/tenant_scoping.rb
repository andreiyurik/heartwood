module TenantScoping
  extend ActiveSupport::Concern

  included do
    before_action :set_current_tree
  end

  private

  def set_current_tree
    return unless Current.user

    membership = resolve_membership
    Current.tree = membership.tree
    Current.membership = membership
  end

  # Falls back to the oldest membership, then bootstraps a tree if there is none.
  def resolve_membership
    if (tree_id = Current.session.current_tree_id)
      membership = Current.user.tree_memberships.find_by(tree_id: tree_id)
      return membership if membership
    end

    Current.user.tree_memberships.first || bootstrap_owner_tree
  end

  def bootstrap_owner_tree
    ActiveRecord::Base.transaction do
      tree = Tree.create!(name: I18n.t("trees.default_name"))
      TreeMembership.create!(user: Current.user, tree: tree, role: "owner")
    end
  rescue ActiveRecord::RecordNotUnique
    Current.user.tree_memberships.first
  end
end
