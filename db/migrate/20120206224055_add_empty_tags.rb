class AddEmptyTags < ActiveRecord::Migration
  tag :predeploy

  def self.up
    Conversation.where(tags: nil).update_all(tags: '')
    ConversationParticipant.where(tags: nil).update_all(tags: '')
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
