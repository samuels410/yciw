class AddTimestampsToGroupCategories < ActiveRecord::Migration
  tag :predeploy

  def change
    change_table(:group_categories) do |t|
      t.timestamps
    end
  end
end
