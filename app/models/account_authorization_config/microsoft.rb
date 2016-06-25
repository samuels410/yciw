#
# Copyright (C) 2015 Instructure, Inc.
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

class AccountAuthorizationConfig::Microsoft < AccountAuthorizationConfig::OpenIDConnect
  include AccountAuthorizationConfig::PluginSettings
  self.plugin = :microsoft
  plugin_settings :application_id, application_secret: :application_secret_dec

  SENSITIVE_PARAMS = [ :application_secret ].freeze

  def self.singleton?
    false
  end

  # Rename db fields
  alias_method :application_id=, :client_id=
  alias_method :application_id, :client_id

  alias_method :application_secret=, :client_secret=
  alias_method :application_secret, :client_secret

  def client_id
    self.class.globally_configured? ? application_id : super
  end

  def client_secret
    self.class.globally_configured? ? application_secret : super
  end

  def tenant=(val)
    self.auth_filter = val
  end

  def tenant
    auth_filter
  end

  def self.recognized_params
    [:tenant, :login_attribute, :jit_provisioning].freeze
  end

  def self.login_attributes
    ['sub'.freeze, 'email'.freeze, 'oid'.freeze, 'preferred_username'.freeze].freeze
  end
  validates :login_attribute, inclusion: login_attributes

  def login_attribute
    super || 'id'.freeze
  end

  protected

  def authorize_url
    "https://login.microsoftonline.com/#{tenant_value}/oauth2/v2.0/authorize"
  end

  def token_url
    "https://login.microsoftonline.com/#{tenant_value}/oauth2/v2.0/token"
  end

  def scope
    result = []
    result << 'profile' if ['oid', 'preferred_username'].include?(login_attribute)
    result << 'email' if login_attribute == 'email'.freeze
    result.join(' ')
  end

  def tenant_value
    tenant.presence || 'common'
  end

end
