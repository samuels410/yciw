class AddSubmissionCachedDueDate < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :submissions, :cached_due_date, :datetime
  end

  def self.down
    remove_column :submissions, :cached_due_date
  end
end
