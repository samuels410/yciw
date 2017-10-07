#
# Copyright (C) 2014 - present Instructure, Inc.
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

group :test do
  gem 'rails-dom-testing', '2.0.3'
  gem 'rails-controller-testing', '1.0.2'

  gem 'gergich', '0.1.15', require: false
  gem 'dotenv', '2.2.1', require: false
  gem 'testingbot', require: false
  gem 'brakeman', require: false
  gem 'simplecov', '0.14.1', require: false, github: 'jenseng/simplecov', ref: '78c1171e98b7227f6bdd8f76f4c14666fd7fc5ea'
    gem 'docile', '1.1.5', require: false
  gem 'simplecov-rcov', '0.2.3', require: false
  gem 'puma', '3.9.1'

  gem 'rspec', '3.6.0'
  gem 'rspec_around_all', '0.2.0'
  gem 'rspec-rails', '3.6.0'
  gem 'rspec-collection_matchers', '1.1.3'
  gem 'shoulda-matchers', '3.1.2'

  gem 'rubocop-canvas', require: false, path: 'gems/rubocop-canvas'
    gem 'rubocop', '0.49.1', require: false
      gem 'rainbow', '2.2.2', require: false
  gem 'rubocop-rspec', '1.15.1', require: false

  gem 'once-ler', '0.1.2'

  # Keep this gem synced with docker-compose/seleniumff/Dockerfile
  gem 'selenium-webdriver', '2.53.4'
    gem 'childprocess', '0.7.1', require: false
    gem 'websocket', '1.2.4', require: false
  gem 'chromedriver-helper', require: false
  gem 'selinimum', '0.0.1', require: false, path: 'gems/selinimum'
  gem 'test-queue', github: 'jenseng/test-queue', ref: '1b92ebbca70705599c78a1bad5b16d6a37f741f2', require: false
  gem 'testrailtagging', '0.3.8.3', require: false

  gem 'webmock', '3.0.1', require: false
    gem 'crack', '0.4.3', require: false
  gem 'timecop', '0.9.1'
  gem 'jira_ref_parser', '1.0.1'
  gem 'headless', '2.3.1', require: false
  gem 'escape_code', '0.2', require: false
  gem 'hashdiff', '0.3.4'
  gem 'luminosity_contrast', '0.2.1'
end
