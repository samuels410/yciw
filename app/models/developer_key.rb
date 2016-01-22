#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require 'aws-sdk'

class DeveloperKey < ActiveRecord::Base
  include CustomValidations
  include Workflow

  belongs_to :user
  belongs_to :account
  has_many :page_views
  has_many :access_tokens
  has_many :context_external_tools, :primary_key => 'tool_id', :foreign_key => 'tool_id'

  attr_accessible :api_key, :name, :user, :account, :icon_url, :redirect_uri, :tool_id, :email, :event, :auto_expire_tokens

  before_create :generate_api_key
  before_create :set_auto_expire_tokens
  before_save :nullify_empty_tool_id

  validates_as_url :redirect_uri

  scope :nondeleted, -> { where("workflow_state<>'deleted'") }

  workflow do
    state :active do
      event :deactivate, transitions_to: :inactive
    end
    state :inactive do
      event :activate, transitions_to: :active
    end
    state :deleted
  end

  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.save
  end

  def nullify_empty_tool_id
    self.tool_id = nil if tool_id.blank?
    self.icon_url = nil if icon_url.blank?
  end

  def generate_api_key(overwrite=false)
    self.api_key = CanvasSlug.generate(nil, 64) if overwrite || !self.api_key
  end

  def set_auto_expire_tokens
    self.auto_expire_tokens = true if self.respond_to?(:auto_expire_tokens=)
  end

  def self.default
    get_special_key("User-Generated")
  end

  def authorized_for_account?(target_account)
    return true unless account_id
    account_ids = target_account.account_chain.map{|acct| acct.global_id}
    account_ids.include? account.global_id
  end

  def account_name
    account.try(:name)
  end

  def self.get_special_key(default_key_name)
    Shard.birth.activate do
      @special_keys ||= {}

      if Rails.env.test?
        # TODO: we have to do this because tests run in transactions
        return @special_keys[default_key_name] = DeveloperKey.where(name: default_key_name).first_or_create
      end

      key = @special_keys[default_key_name]
      return key if key
      if (key_id = Setting.get("#{default_key_name}_developer_key_id", nil)) && key_id.present?
        key = DeveloperKey.where(id: key_id).first
      end
      return @special_keys[default_key_name] = key if key
      key = DeveloperKey.create!(:name => default_key_name)
      Setting.set("#{default_key_name}_developer_key_id", key.id)
      return @special_keys[default_key_name] = key
    end
  end

  # verify that the given uri has the same domain as this key's
  # redirect_uri domain.
  def redirect_domain_matches?(redirect_uri)
    self_domain = URI.parse(self.redirect_uri).host
    other_domain = URI.parse(redirect_uri).host
    return self_domain.present? && other_domain.present? && (self_domain == other_domain || other_domain.end_with?(".#{self_domain}"))
  rescue URI::Error
    return false
  end

  # for now, only one AWS account for SNS is supported
  def self.sns
    if !defined?(@sns)
      settings = ConfigFile.load('sns')
      @sns = nil
      @sns = AWS::SNS.new(settings) if settings
    end
    @sns
  end
end
