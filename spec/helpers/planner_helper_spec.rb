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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PlannerHelper do
  include PlannerHelper

  describe "#formatted_planner_date" do
    it 'should create errors for bad dates' do
      expect {formatted_planner_date('start_date', '123-456-789')}.to raise_error(PlannerHelper::InvalidDates)
      expect {formatted_planner_date('end_date', '9876-5-4321')}.to raise_error(PlannerHelper::InvalidDates)
    end
  end

  context "mark-done and planner-complete synchronization" do
    before(:once) do
      student_in_course(active_all: true)
      @module1 = @course.context_modules.create!(:name => "module1")
      @assignment = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"], :points_possible => 42)
      @assignment.publish
      @wiki_page = @course.wiki_pages.create!(:title => "my page")
      @wiki_page.publish

      # add assignment as a completion requirement in one module
      @assignment_tag = @module1.add_item(:id => @assignment.id, :type => 'assignment')
      @wiki_page_tag = @module1.add_item(:id => @wiki_page.id, :type => 'wiki_page')
      @module1.completion_requirements = {
        @assignment_tag.id => { :type => 'must_mark_done' },
        @wiki_page_tag.id => { :type => 'must_mark_done' }
      }
      @module1.save!
    end

    describe "#sync_module_requirement_done" do
        it "sets module requirement as done when completed in planner for assignment" do
          planner_override_model({"plannable": @assignment, "marked_complete": true})
          sync_module_requirement_done(@assignment, @user, true)
          progression = @module1.find_or_create_progression(@user)
          expect(progression.finished_item?(@assignment_tag)).to eq true
        end

        it "sets module requirement as not done when un-completed in planner for assignment" do
          @assignment_tag.context_module_action(@user, :done)
          planner_override_model({"plannable": @assignment, "marked_complete": false})
          sync_module_requirement_done(@assignment, @user, false)
          progression = @module1.find_or_create_progression(@user)
          expect(progression.finished_item?(@assignment_tag)).to eq false
        end

        it "sets module requirement as done when completed in planner for wiki page" do
          planner_override_model({"plannable": @wiki_page, "marked_complete": true})
          sync_module_requirement_done(@wiki_page, @user, true)
          progression = @module1.find_or_create_progression(@user)
          expect(progression.finished_item?(@wiki_page_tag)).to eq true
        end

        it "sets module requirement as not done when un-completed in planner for wiki page" do
          @wiki_page_tag.context_module_action(@user, :done)
          planner_override_model({"plannable": @wiki_page, "marked_complete": false})
          sync_module_requirement_done(@wiki_page, @user, false)
          progression = @module1.find_or_create_progression(@user)
          expect(progression.finished_item?(@wiki_page_tag)).to eq false
        end

        it "catches error if tried on non-module object types" do
          expect { sync_module_requirement_done(@user, @user, true) }.not_to raise_error
        end
    end

    describe "#sync_planner_completion" do
      it "updates existing override for assignment" do
        planner_override_model({"plannable": @assignment,
                                "marked_complete": false,
                                "dismissed": false})

        override = sync_planner_completion(@assignment, @user, true)
        expect(override.marked_complete).to eq true
        expect(override.dismissed).to eq true

        override = sync_planner_completion(@assignment, @user, false)
        expect(override.marked_complete).to eq false
        expect(override.dismissed).to eq false
      end

      it "creates new override if none exists for assignment" do
        override = sync_planner_completion(@assignment, @user, true)
        expect(override.marked_complete).to eq true
        expect(override.dismissed).to eq true
      end

      it "updates existing override for wiki page" do
        planner_override_model({"plannable": @wiki_page,
                                "marked_complete": false,
                                "dismissed": false})

        override = sync_planner_completion(@wiki_page, @user, true)
        expect(override.marked_complete).to eq true
        expect(override.dismissed).to eq true

        override = sync_planner_completion(@wiki_page, @user, false)
        expect(override.marked_complete).to eq false
        expect(override.dismissed).to eq false
      end

      it "creates new override if none exists for wiki page" do
        override = sync_planner_completion(@wiki_page, @user, true)
        expect(override.marked_complete).to eq true
        expect(override.dismissed).to eq true
      end

      it "does not throw error if tried on object type not valid for override" do
        expect { sync_planner_completion(@user, @user, true) }.not_to raise_error
      end

      it "does nothing if mark-doneable in zero modules" do
        @module1.completion_requirements = {}
        @module1.save!
        override = sync_planner_completion(@assignment, @user, true)
        expect(override).to eq nil
      end

      it "does nothing if mark-doneable in multiple modules" do
        @module2 = @course.context_modules.create!(:name => "module1")
        @assignment_tag2 = @module2.add_item(:id => @assignment.id, :type => 'assignment')
        @module2.completion_requirements = {
          @assignment_tag2.id => { :type => 'must_mark_done' }
        }
        @module2.save!
        override = sync_planner_completion(@assignment, @user, true)
        expect(override).to eq nil
      end
    end
  end
  context "on a submission" do
    before(:once) do
      student_in_course(active_all: true)
      @assignment = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"], :points_possible => 42)
      @assignment.publish
      
      @discussion_assignment = @course.assignments.create!(title: 'graded discussion assignment', due_at: 1.day.from_now, points_possible: 10)
      @discussion = @course.discussion_topics.create!(assignment: @discussion_assignment, title: 'graded discussion')
      @discussion.publish

      @quiz = generate_quiz(@course)
      @quiz2 = generate_quiz(@course)

      @assignment_po = planner_override_model(user: @student, plannable: @assignment, marked_complete: false)
      @discussion_po = planner_override_model(user: @student, plannable: @discussion, marked_complete: false)
      @quiz_po = planner_override_model(user: @student, plannable: @quiz, marked_complete: false)
      @quiz2_po = planner_override_model(user: @student, plannable: @quiz2, marked_complete: false)
    end
 
    describe "#completes_planner_item_for_submission" do
      it "completes an assignment override" do
        @assignment.submit_homework(@student, body: 'hello world')
        @assignment_po.reload
        expect(@assignment_po.marked_complete).to be_truthy
      end

      it "completes a discussion override" do
        @discussion.reply_from(:user => @student, :text => "reply")
        @discussion_po.reload
        expect(@discussion_po.marked_complete).to be_truthy
      end

      it "completes a quiz override" do
        qsub = generate_quiz_submission(@quiz, student: @student)
        qsub.submission.save!
        @quiz_po.reload
        expect(@quiz_po.marked_complete).to be_truthy
      end

      it "completes an autograded quiz override" do
        qsub = graded_submission(@quiz2, @student)
        @quiz2_po.reload
        expect(@quiz2_po.marked_complete).to be_truthy
      end
    end

    describe "#complete_planner_item_for_quiz_submission" do
      it "completes an ungraded survey override" do
        survey = @course.quizzes.create!(:title => "survey", :due_at => 1.day.from_now, :quiz_type => "survey")
        survey_po = planner_override_model(user: @student, plannable: survey, marked_complete: false)
        sub = survey.generate_submission(@user)
        Quizzes::SubmissionGrader.new(sub).grade_submission
        survey_po.reload
        expect(survey_po.marked_complete).to be_truthy
      end

      it "creates completed override when ungraded survey is submitted" do
        survey = @course.quizzes.create!(:title => "survey", :due_at => 1.day.from_now, :quiz_type => "survey")
        sub = survey.generate_submission(@user)
        Quizzes::SubmissionGrader.new(sub).grade_submission
        survey_po = PlannerOverride.find_by(user: @student, plannable: survey)
        expect(survey_po.marked_complete).to be_truthy
      end
    end
  end
end
