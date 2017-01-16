class AddModeratorFlagToGroupMemberships < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :group_memberships, :moderator, :boolean
  end

  def self.down
    remove_column :group_memberships, :moderator
  end
end
