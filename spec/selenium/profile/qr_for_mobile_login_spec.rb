#
# Copyright (C) 2020 - present Instructure, Inc.
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
require_relative '../common'

describe 'QR for mobile login' do
  include_context 'in-process server selenium tests'

  def check_base64_encoded_png_image(element)
    expect(element).to be_displayed
    expect(element.tag_name).to eq 'img'

    data_url = element.attribute('src')
    byte_string = Base64.decode64(data_url.sub(%r{data\:image\/png\;base64\, }, ''))

    Tempfile.open('qr.png', encoding: 'ascii-8bit') do |file|
      file.write(byte_string)
      expect(file.size).to be > 0
    end
  end

  before :once do
    @account = Account.default
    @account.enable_feature! :mobile_qr_login

    dev_key =
      DeveloperKey.create!(
        account_id: @account.id,
        name: 'QR for Mobile Login',
        redirect_uris: 'https://sso.canvaslms.com/canvas/login',
        workflow_state: 'active'
      )

    @account.settings[:ios_mobile_sso_developer_key_id] = dev_key.global_id
    @account.save!
    account_domain = @account.account_domains.new(host: 'sso.canvaslms.com')
    account_domain.save!(validate: false)
  end

  before { user_logged_in }

  context 'from global nav account profile' do
    it 'should bring up modal with generated QR code' do
      get '/'
      f('#global_nav_profile_link').click
      find_button('QR for Mobile Login').click
      qr_code = f("img[data-testid='qr-code-image']")
      check_base64_encoded_png_image(qr_code)
    end
  end

  # TODO: USERS-458 will make this available
  # context 'from profile settings' do
  #   it 'should bring up modal with generated QR code' do
  #     get '/profile'
  #     find_button('QR for Mobile Login').click
  #     qr_code = f("img[data-testid='qr-code-image']")
  #     check_base64_encoded_png_image(qr_code)
  #   end
  # end
end
