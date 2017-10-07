#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../../common'
class Gradezilla
  class GradeDetailTray
    class << self
      include SeleniumDependencies

      # selectors
      def avatar
        f("#SubmissionTray__Avatar")
      end

      def student_name
        f("#SubmissionTray__StudentName")
      end

      def status_radio_button(type)
        fj("label[data-reactid*='#{type}']")
      end

      def status_radio_button_input(type)
        fj("input[value=#{type}]")
      end

      def late_by_input_css
        ".SubmissionTray__RadioInput input[id*='NumberInput']"
      end

      def late_by_hours
        fj("label:contains('Hours late')")
      end

      def late_by_days
        fj("label:contains('Days late')")
      end

      def close_tray_X
        fj("button[data-reactid*='closeButton']")
      end

      def late_penalty_text
        f("#late-penalty-value").text
      end

      def final_grade_text
        f("#final-grade-value").text
      end

      def speedgrader_link
        fj("a:contains('SpeedGrader')")
      end

      # to-do's ---start
      def assignment_link(assignment_name)
        fj("a:contains('#{assignment_name}')")
      end

      def navigate_to_next_student
        fj(".student_nav button:contains('>')")
      end

      def navigate_to_previous_student
        fj(".student_nav button:contains('<')")
      end

      def navigate_to_next_assignment
        fj(".right-arrow-button-container button")
      end

      def navigate_to_previous_assignment
        fj(".left-arrow-button-container button")
      end

      def grade_input
        "#grade-input"
      end

      # to-do's ---end

      # methods
      def change_status_to(type)
        status_radio_button(type).click
      end

      def is_radio_button_selected(type)
        status_radio_button_input(type).selected?
      end

      def fetch_late_by_value
        fj(late_by_input_css)['value']
      end

      def edit_late_by_input(value)
        fj(late_by_input_css).click

        new_value = fj(late_by_input_css)
        set_value(new_value, value)
        new_value.send_keys(:return)

        # shifting focus from input = saving the changes
        driver.execute_script('$(".SubmissionTray__RadioInput input[value=\'late\']").focus()')
      end

      def edit_grade_input(new_grade)
        fj(grade_input).click

        edit_grade = fj(grade_input)
        set_value(edit_grade, new_grade)

        edit_grade.send_keys(:return)
      end

    end
  end
end
