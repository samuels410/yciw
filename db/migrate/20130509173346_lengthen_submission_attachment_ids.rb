class LengthenSubmissionAttachmentIds < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    change_column :submissions, :attachment_ids, :text
  end

  def self.down
    change_column :submissions, :attachment_ids, :string, :limit => 255
  end
end
