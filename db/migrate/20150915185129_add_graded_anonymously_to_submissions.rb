class AddGradedAnonymouslyToSubmissions < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :submissions, :graded_anonymously, :boolean
  end
end
