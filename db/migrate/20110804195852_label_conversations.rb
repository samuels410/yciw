class LabelConversations < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :conversation_participants, :label, :string
  end

  def self.down
    remove_column :conversation_participants, :label
  end
end
