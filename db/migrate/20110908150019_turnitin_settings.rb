class TurnitinSettings < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :assignments, :turnitin_settings, :text
  end

  def self.down
    remove_column :assignments, :turnitin_settings
  end
end
