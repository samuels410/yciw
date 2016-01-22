class UpdateSubmittedAtForDiscussionTopics < ActiveRecord::Migration
  tag :predeploy

  def self.up
    Submission.where(:submission_type => "discussion_topic").update_all("submitted_at = created_at")
  end

  def self.down
  end
end
