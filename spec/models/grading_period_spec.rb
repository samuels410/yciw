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

require_relative '../spec_helper'

describe GradingPeriod do
  subject(:grading_period) { grading_period_group.grading_periods.build(params) }
  let(:grading_period_group) { account.grading_period_groups.create!(account: account) }
  let(:account) { Account.create! }
  let(:course) { Course.create! }
  let(:now) { Time.zone.now }

  let(:params) do
    {
      title: 'A Grading Period',
      start_date: now,
      end_date: 1.day.from_now(now)
    }
  end

  it { is_expected.to be_valid }

  it "requires a start_date" do
    grading_period =  GradingPeriod.new(params.except(:start_date))
    expect(grading_period).to_not be_valid
  end

  it "requires an end_date" do
    grading_period = GradingPeriod.new(params.except(:end_date))
    expect(grading_period).to_not be_valid
  end

  it "requires start_date to be before end_date" do
    subject.assign_attributes(start_date: Time.zone.now, end_date: 1.day.ago)
    is_expected.to_not be_valid
  end

  it "requires a title" do
    grading_period = GradingPeriod.new(params.except(:title))
    expect(grading_period).to_not be_valid
  end

  describe "#destroy" do
    before { subject.destroy }

    it "marks workflow as deleted" do
      expect(subject.workflow_state).to eq "deleted"
    end

    it "does not destroy" do
      expect(subject).to_not be_destroyed
    end
  end

  describe "#destroy_permanently!" do
    before { subject.destroy_permanently! }

    it { is_expected.to be_destroyed }
  end

  describe ".for" do
    context "when context is an account" do
      let(:account) { Account.new }
      let(:finder) { mock }

      it "delegates calls" do
        GradingPeriod::AccountGradingPeriodFinder.expects(:new).with(account).once.returns(finder)
        finder.expects(:grading_periods).once
        GradingPeriod.for(account)
      end
    end

    context "when context is a course" do
      let(:course) { Course.new }
      let(:finder) { mock }

      it "delegates calls" do
        GradingPeriod::CourseGradingPeriodFinder.expects(:new).with(course).once.returns(finder)
        finder.expects(:grading_periods).once
        GradingPeriod.for(course)
      end
    end
  end

  describe ".current_period_for" do
    let(:account) { Account.new }
    let(:not_current_grading_period) { mock }
    let(:current_grading_period) { mock }

    it "returns the current grading period given a context" do
      GradingPeriod.expects(:for).with(account).returns([not_current_grading_period, current_grading_period])
      not_current_grading_period.expects(:current?).returns(false)
      current_grading_period.expects(:current?).returns(true)
      expect(GradingPeriod.current_period_for(account)).to eq(current_grading_period)
    end

    it "returns nil if grading periods exist for the given context, but none are current" do
      GradingPeriod.expects(:for).with(account).returns([not_current_grading_period])
      not_current_grading_period.expects(:current?).returns(false)
      expect(GradingPeriod.current_period_for(account)).to be_nil
    end

    it "returns nil if no grading periods exist for the given context" do
      GradingPeriod.expects(:for).with(account).returns([])
      expect(GradingPeriod.current_period_for(account)).to be_nil
    end
  end

  describe ".context_find" do
    let(:account) { mock }
    let(:finder) { mock }
    let(:grading_period) { mock }
    let(:id) { 1 }

    it "delegates" do
      grading_period.expects(:id).returns(1)
      GradingPeriod.expects(:for).with(account).returns([grading_period])

      expect(GradingPeriod.context_find(account, id)).to eq grading_period
    end
  end

  describe "#assignments" do
    let!(:first_assignment)  { course.assignments.create!(due_at: first_grading_period.start_date + 1.second) }
    let!(:second_assignment) { course.assignments.create!(due_at: second_grading_period.start_date + 1.seconds) }
    let!(:third_assignment)  { course.assignments.create!(due_at: nil) }

    let(:first_grading_period) do
        grading_period_group.grading_periods.create!(
          title:      '1st period',
          start_date: 2.months.from_now(now),
          end_date:   3.months.from_now(now)
        )
    end
    let(:second_grading_period) do
      grading_period_group.grading_periods.create!(
        title:      '2nd period',
        start_date: 3.months.from_now(now),
        end_date:   4.months.from_now(now)
      )
    end
    let(:grading_period_group) { course.grading_period_groups.create! }

    it "filters the first grading period" do
      assignments = first_grading_period.assignments(course.assignments)
      expect(assignments).to eq [first_assignment]
    end

    it "filters assignments without a due_at into the last grading period" do
      assignments = second_grading_period.assignments(course.assignments)
      expect(assignments).to eq [second_assignment, third_assignment]
    end

    describe "when due at the same time as the edge of a period" do
      let!(:fourth_assignment)  { course.assignments.create!(due_at: third_grading_period.end_date + 0.005.seconds) }
      let!(:fifth_assignment) { course.assignments.create!(due_at: fourth_grading_period.start_date - 0.005.seconds) }

      let(:third_grading_period) do
        grading_period_group.grading_periods.create!(
          title:      '3rd period',
          start_date: 5.months.from_now(now),
          end_date:   6.months.from_now(now)
        )
      end

      let(:fourth_grading_period) do
        grading_period_group.grading_periods.create!(
          title:      '4th period',
          start_date: 7.months.from_now(now),
          end_date:   8.months.from_now(now)
        )
      end

      it "includes assignments if they are on the end date" do
        assignments = third_grading_period.assignments(course.assignments)
        expect(assignments).to include fourth_assignment
      end

      it "does NOT include assignments if they are on the start date" do
        assignments = fourth_grading_period.assignments(course.assignments)
        expect(assignments).to_not include fifth_assignment
      end
    end
  end

  describe "#current?" do
    subject(:grading_period) { GradingPeriod.new }

    it "returns false for a grading period in the past" do
      grading_period.assign_attributes(start_date: 2.months.ago,
                                       end_date:   1.month.ago)
      expect(grading_period).to_not be_current
    end

    it "returns true if the current time falls between the start date and end date (inclusive)" do
      grading_period.assign_attributes(start_date: 1.month.ago,
                                       end_date:   1.month.from_now)
      expect(grading_period).to be_current
    end

    it "returns false for a grading period in the future" do
      grading_period.assign_attributes(start_date: 1.month.from_now,
                                       end_date:   2.months.from_now)
      expect(grading_period).to_not be_current
    end
  end

  context 'given an existing grading_period' do
    let(:course) { Course.create! }
    let(:grading_period_group) { course.grading_period_groups.create! }
    let(:existing_grading_period) do
      grading_period_group.grading_periods.create!(
        title: 'a title',
        start_date: now,
        end_date: 2.days.from_now(now)
      )
    end

    describe '#overlapping?' do
      context 'given a new grading period with a start_date and an end_date' \
        'that overlaps with the existing grading_period' do
        subject { grading_period_group.grading_periods.build(start_date: start_date, end_date: end_date) }
        let(:start_date) { existing_grading_period.start_date }
        let(:end_date)   { existing_grading_period.end_date }
        it { is_expected.to be_overlapping }
      end

      context 'given a new grading period with a start_date that begins at the end_date existing grading_period' do
        subject { grading_period_group.grading_periods.build(start_date: start_date, end_date: end_date)}
        let(:start_date) { existing_grading_period.end_date }
        let(:end_date)   { existing_grading_period.end_date + 1.month }
        it { is_expected.to_not be_overlapping }
      end
    end

    it "after a grading period is persisted it continues to not overlap" do
      expect(existing_grading_period).to_not be_overlapping
    end
  end

  context "Soft deletion" do
    subject { grading_period_group.grading_periods }
    let(:creation_arguments) { [period_one, period_two] }
    let(:period_one) { { title: 'an title', start_date: 1.week.ago(now), end_date: 2.weeks.from_now(now) } }
    let(:period_two) { { title: 'an title', start_date: 2.weeks.from_now(now), end_date: 5.weeks.from_now(now) } }
    include_examples "soft deletion"
  end

  describe ".in_date_range?" do
    subject(:period) do
      grading_period_group.grading_periods.create start_date: 1.week.ago,
                                                  end_date:   2.weeks.from_now
    end

    it "returns true for a date in the period" do
      expect(period.in_date_range? 1.day.from_now).to be true
    end

    it "returns false for a date before the period" do
      expect(period.in_date_range? 8.days.ago).to be false
    end

    it "returns false for a date after the period" do
      expect(period.in_date_range? 15.days.from_now).to be false
    end
  end

  describe ".json_for" do
    it "returns a list sorted by date with is_last" do
      grading_period_group.grading_periods.create! start_date: 1.week.ago, end_date: 2.weeks.from_now, title: 'C'
      grading_period_group.grading_periods.create! start_date: 4.weeks.ago, end_date: 3.weeks.ago, title: 'A'
      grading_period_group.grading_periods.create! start_date: 3.weeks.ago, end_date: 2.weeks.ago, title: 'B'
      json = GradingPeriod.json_for(account, nil)
      expect(json.map { |el| el['title'] }).to eq %w(A B C)
      expect(json.map { |el| el['is_last'] }).to eq [false, false, true]
    end
  end
end
