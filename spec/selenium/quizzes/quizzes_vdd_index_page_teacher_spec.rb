require File.expand_path(File.dirname(__FILE__) + '/../helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/assignment_overrides')

describe 'viewing a quiz with variable due dates on the quizzes index page' do
  include AssignmentOverridesSeleniumHelper
  include_context 'in-process server selenium tests'

  context 'as a teacher in both sections' do
    before(:all) { prepare_vdd_scenario_for_teacher }

    before(:each) do
      user_session(@teacher1)
      get "/courses/#{@course.id}/quizzes"
    end

    it 'shows the due dates for Section A', priority: "1", test_id: 282167 do
      validate_vdd_quiz_tooltip_dates('.date-due', "Everyone else\n#{format_date_for_view(@due_at_a)}")
    end

    it 'shows the due dates for Section B', priority: "1", test_id: 315661 do
      validate_vdd_quiz_tooltip_dates('.date-due', "#{@section_b.name}\n#{format_date_for_view(@due_at_b)}")
    end

    it 'shows the availability dates for Section A', priority: "1", test_id: 282393 do
      validate_vdd_quiz_tooltip_dates('.date-available', "Everyone else\nAvailable until #{format_date_for_view(@lock_at_a)}")
    end

    it 'shows the availability dates for Section B', priority: "1", test_id: 315663 do
      validate_vdd_quiz_tooltip_dates('.date-available', "#{@section_b.name}\nNot available until #{format_date_for_view(@unlock_at_b)}")
    end
  end
end