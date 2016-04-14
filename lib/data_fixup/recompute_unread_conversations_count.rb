module DataFixup::RecomputeUnreadConversationsCount
  def self.run
    # Include "last_message_at IS NOT NULL" to prevent it from counting unread deleted messages.
    User.find_ids_in_batches do |ids|
      User.connection.execute(User.send(:sanitize_sql_array, [<<-SQL, ids]))
        UPDATE #{User.quoted_table_name} u SET unread_conversations_count = (
          SELECT COUNT(*)
          FROM #{ConversationParticipant.quoted_table_name} p
          WHERE p.workflow_state = 'unread'
            AND p.user_id = u.id
            AND p.last_message_at IS NOT NULL
        )
        WHERE id IN (?)
      SQL
    end
  end
end