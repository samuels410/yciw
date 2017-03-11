class AddDiscussionTopicsThreadedFlag < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :discussion_topics, :threaded, :boolean
  end

  def self.down
    remove_column :discussion_topics, :threaded
  end
end
