class ConversationMessageContext < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :conversation_messages, :context_id, :integer, :limit => 8
    add_column :conversation_messages, :context_type, :string
  end

  def self.down
    remove_column :conversation_messages, :context_id
    remove_column :conversation_messages, :context_type
  end
end
