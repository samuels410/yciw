#
# Copyright (C) 2014 Instructure, Inc.
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

module Lti
  class ResourcePlacement < ActiveRecord::Base

    ACCOUNT_NAVIGATION = 'account_navigation'
    ASSIGNMENT_SELECTION = 'assignment_selection'
    COURSE_NAVIGATION = 'course_navigation'
    LINK_SELECTION = 'link_selection'
    POST_GRADES = 'post_grades'
    RESOURCE_SELECTION = 'resource_selection'

    DEFAULT_PLACEMENTS = [ASSIGNMENT_SELECTION, LINK_SELECTION].freeze

    PLACEMENT_LOOKUP = {
      'Canvas.placements.accountNavigation' => ACCOUNT_NAVIGATION,
      'Canvas.placements.assignmentSelection' => ASSIGNMENT_SELECTION,
      'Canvas.placements.courseNavigation' => COURSE_NAVIGATION,
      'Canvas.placements.linkSelection' => LINK_SELECTION,
      'Canvas.placements.postGrades' => POST_GRADES,
    }.freeze

    attr_accessible :placement, :message_handler, :resource_handler

    belongs_to :message_handler, class_name: 'Lti::MessageHandler'
    belongs_to :resource_handler, class_name: 'Lti::ResourceHandler'
    validates_presence_of :message_handler, :placement

    validates_inclusion_of :placement, :in => PLACEMENT_LOOKUP.values

  end
end
