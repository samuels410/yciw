/*
 * Copyright (C) 2020 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

export default class AssignmentGroupsLoader {
  constructor({dispatch, gradebook, performanceControls}) {
    this._dispatch = dispatch
    this._gradebook = gradebook
    this._performanceControls = performanceControls
  }

  loadAssignmentGroups() {
    const courseId = this._gradebook.course.id
    const url = `/api/v1/courses/${courseId}/assignment_groups`

    const params = {
      exclude_assignment_submission_types: ['wiki_page'],
      exclude_response_fields: ['description', 'in_closed_grading_period', 'needs_grading_count'],
      include: [
        'assignment_group_id',
        'assignment_visibility',
        'assignments',
        'grades_published',
        'module_ids',
        'post_manually'
      ],
      override_assignment_dates: false,
      per_page: this._performanceControls.assignmentGroupsPerPage
    }

    return this._dispatch.getDepaginated(url, params).then(assignmentGroups => {
      this._gradebook.updateAssignmentGroups(assignmentGroups)
    })
  }
}
