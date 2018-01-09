#
# Copyright (C) 2013 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe DueDateCacher do
  before(:once) do
    course_with_student(:active_all => true)
    assignment_model(:course => @course)
  end

  describe ".recompute" do
    before do
      @instance = double('instance', :recompute => nil)
      @new_expectation = expect(DueDateCacher).to receive(:new).and_return(@instance)
    end

    it "should wrap assignment in an array" do
      @new_expectation.with(@course, [@assignment.id])
      DueDateCacher.recompute(@assignment)
    end

    it "should delegate to an instance" do
      expect(@instance).to receive(:recompute)
      DueDateCacher.recompute(@assignment)
    end

    it "should queue a delayed job in an assignment-specific singleton in production" do
      expect(@instance).to receive(:send_later_if_production_enqueue_args).
        with(:recompute, singleton: "cached_due_date:calculator:Assignment:#{@assignment.global_id}")
      DueDateCacher.recompute(@assignment)
    end
  end

  describe ".recompute_course" do
    before do
      @assignments = [@assignment]
      @assignments << assignment_model(:course => @course)
      @instance = double('instance', :recompute => nil)
      @new_expectation = expect(DueDateCacher).to receive(:new).and_return(@instance)
    end

    it "should pass along the whole array" do
      @new_expectation.with(@course, @assignments)
      DueDateCacher.recompute_course(@course, @assignments)
    end

    it "should default to all assignments in the context" do
      @new_expectation.with(@course, match_array(@assignments.map(&:id)))
      DueDateCacher.recompute_course(@course)
    end

    it "should delegate to an instance" do
      expect(@instance).to receive(:recompute)
      DueDateCacher.recompute_course(@course, @assignments)
    end

    it "should queue a delayed job in a singleton in production if assignments.nil" do
      expect(@instance).to receive(:send_later_if_production_enqueue_args).
          with(:recompute, singleton: "cached_due_date:calculator:Course:#{@course.global_id}")
      DueDateCacher.recompute_course(@course)
    end

    it "should queue a delayed job without a singleton if assignments is passed" do
      expect(@instance).to receive(:send_later_if_production_enqueue_args).with(:recompute, {})
      DueDateCacher.recompute_course(@course, @assignments)
    end

    it "should operate on a course id" do
      expect(@instance).to receive(:send_later_if_production_enqueue_args).
          with(:recompute, singleton: "cached_due_date:calculator:Course:#{@course.global_id}")
      @new_expectation.with(@course, match_array(@assignments.map(&:id).sort))
      DueDateCacher.recompute_course(@course.id)
    end
  end

  describe "#recompute" do
    before do
      @cacher = DueDateCacher.new(@course, [@assignment])
      submission_model(:assignment => @assignment, :user => @student)
      Submission.update_all(:cached_due_date => nil)
    end

    context 'without existing submissions' do
      it "should create submissions for enrollments that are not overridden" do
        Submission.destroy_all
        expect { @cacher.recompute }.to change {
          Submission.active.where(assignment_id: @assignment.id).count
        }.from(0).to(1)
      end

      it "should delete submissions for enrollments that are deleted" do
        @course.student_enrollments.update_all(workflow_state: 'deleted')

        expect { @cacher.recompute }.to change {
          Submission.active.where(assignment_id: @assignment.id).count
        }.from(1).to(0)
      end

      it "should create submissions for enrollments that are overridden" do
        assignment_override_model(assignment: @assignment, set: @course.default_section)
        @override.override_due_at(@assignment.due_at + 1.day)
        @override.save!
        Submission.destroy_all

        expect { @cacher.recompute }.to change {
          Submission.active.where(assignment_id: @assignment.id).count
        }.from(0).to(1)
      end

      it "should not create submissions for enrollments that are not assigned" do
        @assignment1 = @assignment
        @assignment2 = assignment_model(course: @course)
        @assignment2.only_visible_to_overrides = true
        @assignment2.save!

        Submission.destroy_all

        expect { DueDateCacher.recompute_course(@course) }.to change {
          Submission.active.count
        }.from(0).to(1)
      end

      it "does not create submissions for concluded enrollments" do
        student2 = user_factory
        @course.enroll_student(student2, enrollment_state: 'active')
        student2.enrollments.find_by(course: @course).conclude
        expect { DueDateCacher.recompute_course(@course) }.not_to change {
          Submission.active.where(user_id: student2.id).count
        }
      end
    end

    it "should not create another submission for enrollments that have a submission" do
      expect { @cacher.recompute }.not_to change {
        Submission.active.where(assignment_id: @assignment.id).count
      }
    end

    it "should not create another submission for enrollments that have a submission, even with an overridden" do
      assignment_override_model(assignment: @assignment, set: @course.default_section)
      @override.override_due_at(@assignment.due_at + 1.day)
      @override.save!

      expect { @cacher.recompute }.not_to change {
        Submission.active.where(assignment_id: @assignment.id).count
      }
    end

    it "should delete submissions for enrollments that are no longer assigned" do
      @assignment.only_visible_to_overrides = true

      expect { @assignment.save! }.to change {
        Submission.active.count
      }.from(1).to(0)
    end

    it "does not delete submissions for concluded enrollments" do
      student2 = user_factory
      @course.enroll_student(student2, enrollment_state: 'active')
      submission_model(assignment: @assignment, user: student2)
      student2.enrollments.find_by(course: @course).conclude

      @assignment.only_visible_to_overrides = true
      expect { @assignment.save! }.not_to change {
        Submission.active.where(user_id: student2.id).count
      }
    end

    it "should restore submissions for enrollments that are assigned again" do
      @assignment.submit_homework(@student, submission_type: :online_url, url: 'http://instructure.com')
      @assignment.only_visible_to_overrides = true
      @assignment.save!
      expect(Submission.first.workflow_state).to eq 'deleted'

      @assignment.only_visible_to_overrides = false
      expect { @assignment.save! }.to change {
        Submission.active.count
      }.from(0).to(1)
      expect(Submission.first.workflow_state).to eq 'submitted'
    end

    context "no overrides" do
      it "should set the cached_due_date to the assignment due_at" do
        @assignment.due_at += 1.day
        @assignment.save!

        @cacher.recompute
        expect(@submission.reload.cached_due_date).to eq @assignment.due_at.change(sec: 0)
      end

      it "should set the cached_due_date to nil if the assignment has no due_at" do
        @assignment.due_at = nil
        @assignment.save!

        @cacher.recompute
        expect(@submission.reload.cached_due_date).to be_nil
      end

      it "does not update submissions for students with concluded enrollments" do
        student2 = user_factory
        @course.enroll_student(student2, enrollment_state: 'active')
        submission2 = submission_model(assignment: @assignment, user: student2)
        submission2.update_attributes(cached_due_date: nil)
        student2.enrollments.find_by(course: @course).conclude

        DueDateCacher.new(@course, [@assignment]).recompute
        expect(submission2.reload.cached_due_date).to be nil
      end
    end

    context "one applicable override" do
      before do
        assignment_override_model(
          :assignment => @assignment,
          :set => @course.default_section)
      end

      it "should prefer override's due_at over assignment's due_at" do
        @override.override_due_at(@assignment.due_at - 1.day)
        @override.save!

        @cacher.recompute
        expect(@submission.reload.cached_due_date).to eq @override.due_at.change(sec: 0)
      end

      it "should prefer override's due_at over assignment's nil" do
        @override.override_due_at(@assignment.due_at - 1.day)
        @override.save!

        @assignment.due_at = nil
        @assignment.save!

        @cacher.recompute
        expect(@submission.reload.cached_due_date).to eq @override.due_at.change(sec: 0)
      end

      it "should prefer override's nil over assignment's due_at" do
        @override.override_due_at(nil)
        @override.save!

        @cacher.recompute
        expect(@submission.reload.cached_due_date).to eq @override.due_at
      end

      it "should not apply override if it doesn't override due_at" do
        @override.clear_due_at_override
        @override.save!

        @cacher.recompute
        expect(@submission.reload.cached_due_date).to eq @assignment.due_at.change(sec: 0)
      end

      it "does not update submissions for students with concluded enrollments" do
        student2 = user_factory
        @course.enroll_student(student2, enrollment_state: 'active')
        submission2 = submission_model(assignment: @assignment, user: student2)
        submission2.update_attributes(cached_due_date: nil)
        student2.enrollments.find_by(course: @course).conclude

        DueDateCacher.new(@course, [@assignment]).recompute
        expect(submission2.reload.cached_due_date).to be nil
      end
    end

    context "adhoc override" do
      before do
        @student1 = @student
        @student2 = user_factory
        @course.enroll_student(@student2, :enrollment_state => 'active')

        assignment_override_model(
          :assignment => @assignment,
          :due_at => @assignment.due_at + 1.day)
        @override.assignment_override_students.create!(:user => @student2)

        @submission1 = @submission
        @submission2 = submission_model(:assignment => @assignment, :user => @student2)
        Submission.update_all(:cached_due_date => nil)
      end

      it "should apply to students in the adhoc set" do
        @cacher.recompute
        expect(@submission2.reload.cached_due_date).to eq @override.due_at.change(sec: 0)
      end

      it "should not apply to students not in the adhoc set" do
        @cacher.recompute
        expect(@submission1.reload.cached_due_date).to eq @assignment.due_at.change(sec: 0)
      end

      it "does not update submissions for students with concluded enrollments" do
        @student2.enrollments.find_by(course: @course).conclude
        DueDateCacher.new(@course, [@assignment]).recompute
        expect(@submission2.reload.cached_due_date).to be nil
      end
    end

    context "section override" do
      before do
        @student1 = @student
        @student2 = user_factory

        add_section('second section')
        @course.enroll_student(@student2, :enrollment_state => 'active', :section => @course_section)

        assignment_override_model(
          :assignment => @assignment,
          :due_at => @assignment.due_at + 1.day,
          :set => @course_section)

        @submission1 = @submission
        @submission2 = submission_model(:assignment => @assignment, :user => @student2)
        Submission.update_all(:cached_due_date => nil)

        @cacher.recompute
      end

      it "should apply to students in that section" do
        expect(@submission2.reload.cached_due_date).to eq @override.due_at.change(sec: 0)
      end

      it "should not apply to students in other sections" do
        expect(@submission1.reload.cached_due_date).to eq @assignment.due_at.change(sec: 0)
      end

      it "should not apply to non-active enrollments in that section" do
        @course.enroll_student(@student1,
          :enrollment_state => 'deleted',
          :section => @course_section,
          :allow_multiple_enrollments => true)
        expect(@submission1.reload.cached_due_date).to eq @assignment.due_at.change(sec: 0)
      end
    end

    context "group override" do
      before do
        @student1 = @student
        @student2 = user_factory
        @course.enroll_student(@student2, :enrollment_state => 'active')

        @assignment.group_category = group_category
        @assignment.save!

        group_with_user(
          :group_context => @course,
          :group_category => @assignment.group_category,
          :user => @student2,
          :active_all => true)

        assignment_override_model(
          :assignment => @assignment,
          :due_at => @assignment.due_at + 1.day,
          :set => @group)

        @submission1 = @submission
        @submission2 = submission_model(:assignment => @assignment, :user => @student2)
        Submission.update_all(:cached_due_date => nil)
      end

      it "should apply to students in that group" do
        @cacher.recompute
        expect(@submission2.reload.cached_due_date).to eq @override.due_at.change(sec: 0)
      end

      it "should not apply to students not in the group" do
        @cacher.recompute
        expect(@submission1.reload.cached_due_date).to eq @assignment.due_at.change(sec: 0)
      end

      it "should not apply to non-active memberships in that group" do
        @cacher.recompute
        @group.add_user(@student1, 'deleted')
        expect(@submission1.reload.cached_due_date).to eq @assignment.due_at.change(sec: 0)
      end

      it "does not update submissions for students with concluded enrollments" do
        @student2.enrollments.find_by(course: @course).conclude
        DueDateCacher.new(@course, [@assignment]).recompute
        expect(@submission2.reload.cached_due_date).to be nil
      end
    end

    context "multiple overrides" do
      before do
        add_section('second section')
        multiple_student_enrollment(@student, @course_section)

        @override1 = assignment_override_model(
          :assignment => @assignment,
          :due_at => @assignment.due_at + 1.day,
          :set => @course.default_section)

        @override2 = assignment_override_model(
          :assignment => @assignment,
          :due_at => @assignment.due_at + 1.day,
          :set => @course_section)
      end

      it "should prefer first override's due_at if latest" do
        @override1.override_due_at(@assignment.due_at + 2.days)
        @override1.save!

        @cacher.recompute
        expect(@submission.reload.cached_due_date).to eq @override1.due_at.change(sec: 0)
      end

      it "should prefer second override's due_at if latest" do
        @override2.override_due_at(@assignment.due_at + 2.days)
        @override2.save!

        @cacher.recompute
        expect(@submission.reload.cached_due_date).to eq @override2.due_at.change(sec: 0)
      end

      it "should be nil if first override's nil" do
        @override1.override_due_at(nil)
        @override1.save!

        @cacher.recompute
        expect(@submission.reload.cached_due_date).to be_nil
      end

      it "should be nil if second override's nil" do
        @override2.override_due_at(nil)
        @override2.save!

        @cacher.recompute
        expect(@submission.reload.cached_due_date).to be_nil
      end
    end

    context "multiple submissions with selective overrides" do
      before do
        @student1 = @student
        @student2 = user_factory
        @student3 = user_factory

        add_section('second section')
        @course.enroll_student(@student2, :enrollment_state => 'active', :section => @course_section)
        @course.enroll_student(@student3, :enrollment_state => 'active')
        multiple_student_enrollment(@student3, @course_section)

        @override1 = assignment_override_model(
          :assignment => @assignment,
          :due_at => @assignment.due_at + 2.days,
          :set => @course.default_section)

        @override2 = assignment_override_model(
          :assignment => @assignment,
          :due_at => @assignment.due_at + 2.days,
          :set => @course_section)

        @submission1 = @submission
        @submission2 = submission_model(:assignment => @assignment, :user => @student2)
        @submission3 = submission_model(:assignment => @assignment, :user => @student3)
        Submission.update_all(:cached_due_date => nil)
      end

      it "should use first override where second doesn't apply" do
        @override1.override_due_at(@assignment.due_at + 1.day)
        @override1.save!

        @cacher.recompute
        expect(@submission1.reload.cached_due_date).to eq @override1.due_at.change(sec: 0)
      end

      it "should use second override where the first doesn't apply" do
        @override2.override_due_at(@assignment.due_at + 1.day)
        @override2.save!

        @cacher.recompute
        expect(@submission2.reload.cached_due_date).to eq @override2.due_at.change(sec: 0)
      end

      it "should use the best override where both apply" do
        @override1.override_due_at(@assignment.due_at + 1.day)
        @override1.save!

        @cacher.recompute
        expect(@submission2.reload.cached_due_date).to eq @override2.due_at.change(sec: 0)
      end
    end

    context "multiple assignments, only one overridden" do
      before do
        @assignment1 = @assignment
        @assignment2 = assignment_model(:course => @course)

        assignment_override_model(
          :assignment => @assignment1,
          :due_at => @assignment1.due_at + 1.day)
        @override.assignment_override_students.create!(:user => @student)

        @submission1 = @submission
        @submission2 = submission_model(:assignment => @assignment2, :user => @student)
        Submission.update_all(:cached_due_date => nil)

        DueDateCacher.new(@course, [@assignment1, @assignment2]).recompute
      end

      it "should apply to submission on the overridden assignment" do
        expect(@submission1.reload.cached_due_date).to eq @override.due_at.change(sec: 0)
      end

      it "should not apply to apply to submission on the other assignment" do
        expect(@submission2.reload.cached_due_date).to eq @assignment.due_at.change(sec: 0)
      end
    end

    it 'kicks off a LatePolicyApplicator job on completion when called with a single assignment' do
      expect(LatePolicyApplicator).to receive(:for_assignment).with(@assignment)

      @cacher.recompute
    end

    it 'does not kick off a LatePolicyApplicator job when called with multiple assignments' do
      @assignment1 = @assignment
      @assignment2 = assignment_model(course: @course)

      expect(LatePolicyApplicator).not_to receive(:for_assignment)

      DueDateCacher.new(@course, [@assignment1, @assignment2]).recompute
    end
  end
end
