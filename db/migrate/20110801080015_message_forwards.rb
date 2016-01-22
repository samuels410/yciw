class MessageForwards < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :conversation_messages, :forwarded_message_ids, :text
  end

  def self.down
    remove_column :conversation_messages, :forwarded_message_ids
  end
end
