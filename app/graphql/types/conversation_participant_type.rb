# frozen_string_literal: true

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
#

module Types
  class ConversationParticipantType < ApplicationObjectType
    graphql_name 'ConversationParticipant'

    implements Interfaces::TimestampInterface

    global_id_field :id
    field :_id, ID, "legacy canvas id", method: :id, null: false
    field :user_id, ID, null: false
    field :workflow_state, String, null: false
    field :label, String, null: true

    field :user, UserType, null: false
    def user
      load_association(:user).then do |u|
        # This is necessary because the user association doesn't contain all the attributes
        # we might want after creating a conversation. Doing the following load off of the
        # ID will get us the full user object and all attributes we might need.
        Loaders::IDLoader.for(User).load(u.id)
      end
    end

    field :conversation, ConversationType, null: false
    def conversation
      load_association(:conversation)
    end
  end
end
