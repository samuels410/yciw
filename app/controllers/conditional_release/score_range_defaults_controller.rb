#
# Copyright (C) 2016 Instructure, Inc.
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

module ConditionalRelease
  class ScoreRangeDefaultsController < ApplicationController
    def index
      get_context
      enabled = @context.feature_enabled?(:conditional_release) &&
        ConditionalRelease::Service.enabled?
      unless enabled
        return render template: 'shared/errors/404_message', status: :not_found
      end

      render locals: {
        cr_app_url: ConditionalRelease::Service.configure_defaults_url,
      }
    end
  end
end
