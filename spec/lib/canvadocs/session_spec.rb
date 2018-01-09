#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative '../../spec_helper'

describe Canvadocs::Session do
  def submissions
    [@submission]
  end
  describe ".observing?" do
    include Canvadocs::Session
    it "should return true if the user is acting as an observer" do
      course = course_factory(active_all: true)
      student = user_factory(active_all: true, active_state: 'active')
      observer = user_factory(active_all: true, active_state: 'active')
      assignment = course.assignments.create!(title: 'assignment 1', name: 'assignment 1')
      section = course.course_sections.create!(name: 'Section A')
      observer_enrollment = course.enroll_user(
        observer,
        'ObserverEnrollment',
        enrollment_state: 'active',
        section: section
      )
      observer_enrollment.update!(associated_user_id: student.id)
      assignment.update_attributes(submission_types: 'online_upload')
      @submission = submission_model(user: student, course: course, assignment: assignment)
      expect(observing?(observer)).to eq true
    end
    it "should return false if the user is not an observer" do
      course = course_factory(active_all: true)
      student = user_factory(active_all: true, active_state: 'active')
      not_observer = user_factory(active_all: true, active_state: 'active')
      assignment = course.assignments.create!(title: 'assignment 1', name: 'assignment 1')
      section = course.course_sections.create!(name: 'Section A')
      course.enroll_user(
        not_observer,
        'StudentEnrollment',
        enrollment_state: 'active',
        section: section
      )
      assignment.update!(submission_types: 'online_upload')
      @submission = submission_model(user: student, course: course, assignment: assignment)
      expect(observing?(not_observer)).to eq false
    end
  end
  describe ".canvadoc_permissions_for_user" do
    include Canvadocs::Session
    it "should return read permissions for observers" do
      course = course_factory(active_all: true)
      student = user_factory(active_all: true, active_state: 'active')
      observer = user_factory(active_all: true, active_state: 'active')
      assignment = course.assignments.create!(title: 'assignment 1', name: 'assignment 1')
      section = course.course_sections.create!(name: 'Section A')
      observer_enrollment = course.enroll_user(
        observer,
        'ObserverEnrollment',
        enrollment_state: 'active',
        section: section
      )
      observer_enrollment.update!(associated_user_id: student.id)
      assignment.update_attributes(submission_types: 'online_upload')
      @submission = submission_model(user: student, course: course, assignment: assignment)
      permissions = canvadoc_permissions_for_user(observer, true)
      expect(permissions[:permissions]).to eq "read"
    end
    it "should return readwrite permissions for owner" do
      course = course_factory(active_all: true)
      student = user_factory(active_all: true, active_state: 'active')
      assignment = course.assignments.create!(title: 'assignment 1', name: 'assignment 1')
      assignment.update_attributes(submission_types: 'online_upload')
      @submission = submission_model(user: student, course: course, assignment: assignment)
      permissions = canvadoc_permissions_for_user(student, true)
      expect(permissions[:permissions]).to eq "readwrite"
    end
  end
end
