class IncreaseFolderNameSize < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    change_column :folders, :full_name, :text
  end

  def self.down
    change_column :folders, :full_name, :string
  end
end
