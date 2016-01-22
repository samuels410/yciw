class AddGradingStandardsVersion < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :grading_standards, :version, :integer
  end

  def self.down
    remove_column :grading_standards, :version
  end
end
