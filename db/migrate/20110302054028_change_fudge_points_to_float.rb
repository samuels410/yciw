class ChangeFudgePointsToFloat < ActiveRecord::Migration
  tag :predeploy

  def self.up
    change_column :quiz_submissions, :fudge_points, :float
  end

  def self.down
    change_column :quiz_submissions, :fudge_points, :integer
  end
end
