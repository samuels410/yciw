# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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
module Types
  class LearningOutcomeGroupType < ApplicationObjectType
    description 'Learning Outcome Group'

    implements GraphQL::Types::Relay::Node
    implements Interfaces::LegacyIDInterface

    global_id_field :id

    field :parent_outcome_group, Types::LearningOutcomeGroupType, null: true
    field :child_groups, Types::LearningOutcomeGroupType.connection_type,
          null: true,
          method: :child_outcome_groups
    field :context_id, Integer, null: true
    field :context_type, String, null: true
    field :title, String, null: false
    field :description, String, null: true
    field :vendor_guid, String, null: true

    field :can_edit, Boolean, null: false
    def can_edit
      if object.context_id
        return object.context.grants_right?(current_user, session, :manage_outcomes)
      end

      Account.site_admin.grants_right?(current_user, session, :manage_global_outcomes)
    end

    field :child_groups_count, Integer, null: false
    def child_groups_count
      # Not Implemented yet
      0
    end

    field :outcomes_count, Integer, null: false
    def outcomes_count
      # Not Implemented yet
      0
    end

    field :outcomes, Types::ContentTagConnection, null: false
    def outcomes
      object.child_outcome_links.active.order_by_outcome_title
    end
  end
end
