class AddLastInlineViewToAttachments < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :attachments, :last_inline_view, :datetime
  end

  def self.down
    remove_column :attachments, :last_inline_view
  end
end
