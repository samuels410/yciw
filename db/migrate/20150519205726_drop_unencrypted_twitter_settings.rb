class DropUnencryptedTwitterSettings < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    PluginSetting.where(name: 'twitter').each do |ps|
      ps.settings.delete(:api_key)
      ps.settings.delete(:secret_key)
      ps.save!
    end
  end
end
