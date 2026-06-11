class AddTreeToDomainTables < ActiveRecord::Migration[8.1]
  def up
    # Add nullable tree_id columns first so backfill can run
    %i[people families family_partners family_children events].each do |table|
      add_reference table, :tree, null: true, foreign_key: true, index: true
    end

    # Backfill: assign all existing rows to a bootstrap tree owned by the first user.
    # Uses raw SQL to avoid model-level dependencies during migrations.
    first_user_id = select_value("SELECT id FROM users ORDER BY id LIMIT 1")

    if first_user_id
      now = Time.current.strftime("%Y-%m-%d %H:%M:%S")
      execute("INSERT INTO trees (name, created_at, updated_at) VALUES ('My Tree', '#{now}', '#{now}')")
      tree_id = select_value("SELECT MAX(id) FROM trees")
      execute("INSERT INTO tree_memberships (tree_id, user_id, role, created_at, updated_at) " \
              "VALUES (#{tree_id}, #{first_user_id}, 'owner', '#{now}', '#{now}')")

      %w[people families family_partners family_children events].each do |table|
        execute("UPDATE #{table} SET tree_id = #{tree_id}")
      end
    end

    # Now enforce null: false (safe — all rows are backfilled or table is empty)
    %i[people families family_partners family_children events].each do |table|
      change_column_null table, :tree_id, false
    end
  end

  def down
    %i[people families family_partners family_children events].each do |table|
      remove_reference table, :tree
    end
  end
end
