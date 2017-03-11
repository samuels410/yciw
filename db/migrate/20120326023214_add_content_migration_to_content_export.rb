class AddContentMigrationToContentExport < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :content_exports, :content_migration_id, :integer, :limit => 8
  end

  def self.down
    remove_column :content_exports, :content_migration_id
  end
end
