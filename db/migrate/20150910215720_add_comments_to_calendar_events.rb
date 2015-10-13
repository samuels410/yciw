class AddCommentsToCalendarEvents < ActiveRecord::Migration
  tag :predeploy

  def up
    add_column :calendar_events, :comments, :text
  end

  def down
    remove_column :calendar_events, :comments
  end
end
