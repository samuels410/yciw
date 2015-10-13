class UpdateToolProxySharedSecret < ActiveRecord::Migration
  tag :predeploy

  def up
    change_column :lti_tool_proxies, :shared_secret, :text
  end

  def down
    change_column :lti_tool_proxies, :shared_secret, :string
  end
end
