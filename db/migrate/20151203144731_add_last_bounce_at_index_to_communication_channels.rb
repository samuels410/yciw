class AddLastBounceAtIndexToCommunicationChannels < ActiveRecord::Migration
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_index :communication_channels, :last_bounce_at, algorithm: :concurrently, where: 'bounce_count > 0'
  end
end

