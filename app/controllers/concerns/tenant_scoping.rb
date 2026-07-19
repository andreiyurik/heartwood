module TenantScoping
  extend ActiveSupport::Concern

  included do
    before_action :set_current_tree
  end

  private

  def set_current_tree
    return unless Current.user

    membership = Current.user.tree_memberships.first || bootstrap_owner_tree
    Current.tree = membership.tree
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
