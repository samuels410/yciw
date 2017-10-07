#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../cassandra_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper')

describe "GradeChangeAudit API", type: :request do
  context "not configured" do
    before do
      allow(Canvas::Cassandra::DatabaseBuilder).to receive(:configured?).with('auditors').and_return(false)
      user_with_pseudonym(account: Account.default)
      @user.account_users.create(account: Account.default)
    end

    it "should 404" do
      raw_api_call(:get, "/api/v1/audit/grade_change/students/#{@user.id}", controller: :grade_change_audit_api, action: :for_student, student_id: @user.id.to_s, format: :json)
      assert_status(404)
    end
  end

  context "configured" do
    include_examples "cassandra audit logs"

    before do
      @request_id = SecureRandom.uuid
      allow(RequestContextGenerator).to receive_messages( :request_id => @request_id )

      @domain_root_account = Account.default
      @viewing_user = user_with_pseudonym(account: @domain_root_account)
      @account_user = @viewing_user.account_users.create(account: @domain_root_account)

      course_with_teacher(account: @domain_root_account, user: user_with_pseudonym(account: @domain_root_account))
      student_in_course(user: user_with_pseudonym(account: @domain_root_account))

      @assignment = @course.assignments.create!(title: 'Assignment', points_possible: 10)
      @submission = @assignment.grade_student(@student, grade: 8, grader: @teacher).first
      @event = Auditors::GradeChange.record(@submission)
    end

    def fetch_for_context(context, options={})
      type = context.class.to_s.downcase unless type = options.delete(:type)
      user = options.delete(:user) || @viewing_user
      id = Shard.global_id_for(context).to_s

      arguments = { controller: :grade_change_audit_api, action: "for_#{type}", "#{type}_id": id, format: :json }
      query_string = []

      if per_page = options.delete(:per_page)
        arguments[:per_page] = per_page.to_s
        query_string << "per_page=#{arguments[:per_page]}"
      end

      if start_time = options.delete(:start_time)
        arguments[:start_time] = start_time.iso8601
        query_string << "start_time=#{arguments[:start_time]}"
      end

      if end_time = options.delete(:end_time)
        arguments[:end_time] = end_time.iso8601
        query_string << "end_time=#{arguments[:end_time]}"
      end

      if account = options.delete(:account)
        arguments[:account_id] = Shard.global_id_for(account).to_s
        query_string << "account_id=#{arguments[:account_id]}"
      end

      path = "/api/v1/audit/grade_change/#{type.pluralize}/#{id}"
      path += "?" + query_string.join('&') if query_string.present?
      api_call_as_user(user, :get, path, arguments, {}, {}, options.slice(:expected_status))
    end

    def fetch_for_course_and_other_contexts(contexts, options={})
      expected_contexts = [:course, :assignment, :grader, :student].freeze
      sorted_contexts = contexts.select { |key,_| expected_contexts.include?(key) }.
        sort_by { |key, _| expected_contexts.index(key) }

      arguments = sorted_contexts.map { |key, value| ["#{key}_id".to_sym, value.id] }.to_h
      arguments.merge!({
        controller: :grade_change_audit_api,
        action: :for_course_and_other_parameters,
        format: :json
      })

      query_string = []

      per_page = options.delete(:per_page)
      if per_page
        arguments[:per_page] = per_page.to_s
        query_string << "per_page=#{arguments[:per_page]}"
      end

      start_time = options.delete(:start_time)
      if start_time
        arguments[:start_time] = start_time.iso8601
        query_string << "start_time=#{arguments[:start_time]}"
      end

      end_time = options.delete(:end_time)
      if end_time
        arguments[:end_time] = end_time.iso8601
        query_string << "end_time=#{arguments[:end_time]}"
      end

      account = options.delete(:account)
      if account
        arguments[:account_id] = Shard.global_id_for(account).to_s
        query_string << "account_id=#{arguments[:account_id]}"
      end

      user = options[:user] || @viewing_user

      path_args = sorted_contexts.map { |key, value| "#{key.to_s.pluralize}/#{value.id}" }.join('/')

      path = "/api/v1/audit/grade_change/#{path_args}"
      path += "?" + query_string.join('&') if query_string.present?
      api_call_as_user(user, :get, path, arguments, {}, {}, options.slice(:expected_status))
    end

    def expect_event_for_context(context, event, options={})
      json = options.delete(:json)
      json ||= fetch_for_context(context, options)
      expect(json['events'].map{ |e| [e['id'], e['event_type']] })
                    .to include([event.id, event.event_type])
      json
    end

    def expect_event_for_course_and_contexts(contexts, event, options={})
      json = options.delete(:json)
      json ||= fetch_for_course_and_other_contexts(contexts, options)
      expect(json['events'].map{ |e| [e['id'], e['event_type']] })
        .to include([event.id, event.event_type])
      json
    end

    def forbid_event_for_context(context, event, options={})
      json = options.delete(:json)
      json ||= fetch_for_context(context, options)
      expect(json['events'].map{ |e| [e['id'], e['event_type']] })
                    .not_to include([event.id, event.event_type])
      json
    end

    def forbid_event_for_course_and_contexts(contexts, event, options={})
      json = options.delete(:json)
      json ||= fetch_for_course_and_contexts(contexts, options)
      expect(json['events'].map{ |e| [e['id'], e['event_type']] })
        .not_to include([event.id, event.event_type])
      json
    end

    def test_course_and_contexts
      # course assignment
      contexts = { course: @course, assignment: @assignment }
      yield(contexts)
      # course assignment grader
      contexts[:grader] = @teacher
      yield(contexts)
      # course assignment grader student
      contexts[:student] = @student
      yield(contexts)
      # course assignment student
      contexts.delete(:grader)
      yield(contexts)
      # course student
      contexts.delete(:assignment)
      yield(contexts)
      # course grader
      contexts = { course: @course, grader: @teacher}
      yield(contexts)
      # course grader student
      contexts[:student] = @student
      yield(contexts)
    end

    context "nominal cases" do
      it "should include events at context endpoint" do
        expect_event_for_context(@assignment, @event)
        expect_event_for_context(@course, @event)
        expect_event_for_context(@student, @event, type: "student")
        expect_event_for_context(@teacher, @event, type: "grader")

        test_course_and_contexts do |contexts|
          expect_event_for_course_and_contexts(contexts, @event)
        end
      end
    end

    describe "arguments" do
      before do
        record = Auditors::GradeChange::Record.new(
          'created_at' => 1.day.ago,
          'submission' => @submission,
        )
        @event2 = Auditors::GradeChange::Stream.insert(record)
      end

      it "should recognize :start_time" do
        json = expect_event_for_context(@assignment, @event, start_time: 12.hours.ago)

        forbid_event_for_context(@assignment, @event2, start_time: 12.hours.ago, json: json)

        json = expect_event_for_context(@course, @event, start_time: 12.hours.ago)
        forbid_event_for_context(@course, @event2, start_time: 12.hours.ago, json: json)

        json = expect_event_for_context(@student, @event, type: "student", start_time: 12.hours.ago)
        forbid_event_for_context(@student, @event2, type: "student", start_time: 12.hours.ago, json: json)

        json = expect_event_for_context(@teacher, @event, type: "grader", start_time: 12.hours.ago)
        forbid_event_for_context(@teacher, @event2, type: "grader", start_time: 12.hours.ago, json: json)

        test_course_and_contexts do |contexts|
          json = expect_event_for_course_and_contexts(contexts, @event, start_time: 12.hours.ago)
          forbid_event_for_course_and_contexts(contexts, @event2, start_time: 12.hours.ago, json: json)
        end
      end

      it "should recognize :end_time" do
        json = expect_event_for_context(@assignment, @event2, end_time: 12.hours.ago)
        forbid_event_for_context(@assignment, @event, end_time: 12.hours.ago, json: json)

        json = forbid_event_for_context(@student, @event, type: "student", end_time: 12.hours.ago)
        expect_event_for_context(@student, @event2, type: "student", end_time: 12.hours.ago, json: json)

        json = expect_event_for_context(@course, @event2, end_time: 12.hours.ago)
        forbid_event_for_context(@course, @event, end_time: 12.hours.ago, json: json)

        json = expect_event_for_context(@teacher, @event2, type: "grader", end_time: 12.hours.ago)
        forbid_event_for_context(@teacher, @event, type: "grader", end_time: 12.hours.ago, json: json)

        test_course_and_contexts do |contexts|
          json = expect_event_for_course_and_contexts(contexts, @event2, end_time: 12.hours.ago)
          forbid_event_for_course_and_contexts(contexts, @event, end_time: 12.hours.ago, json: json)
        end
      end
    end

    context "deleted entities" do
      it "should 404 for inactive assignments" do
        @assignment.destroy
        fetch_for_context(@assignment, expected_status: 404)
      end

      it "should allow inactive assignments when used with a course" do
        @assignment.destroy
        fetcher = lambda do |contexts|
          fetch_for_course_and_other_contexts(contexts, expected_status: 200)
        end
        contexts = {course: @course, assignment: @assignment}
        fetcher.call(contexts)
        contexts[:grader] = @teacher
        fetcher.call(contexts)
        contexts[:student] = @student
        fetcher.call(contexts)
        contexts.delete(:grader)
        fetcher.call(contexts)
      end

      it "should allow inactive courses" do
        @course.destroy
        fetch_for_context(@course, expected_status: 200)
        test_course_and_contexts do |contexts|
          fetch_for_course_and_other_contexts(contexts, expected_status: 200)
        end
      end

      it "should 404 for inactive students" do
        @student.destroy
        fetch_for_context(@student, expected_status: 404, type: "student")
      end

      it "should allow inactive students when used with a course" do
        @student.destroy
        fetcher = lambda do |contexts|
          fetch_for_course_and_other_contexts(contexts, expected_status: 200)
        end
        contexts = {course: @course, assignment: @assignment, grader: @teacher, student: @student}
        fetcher.call(contexts)
        contexts.delete(:grader)
        fetcher.call(contexts)
        contexts.delete(:assignment)
        fetcher.call(contexts)
        contexts = {course: @course, student: @student}
        fetcher.call(contexts)
      end

      it "should 404 for inactive grader" do
        @teacher.destroy
        fetch_for_context(@teacher, expected_status: 404, type: "grader")
      end

      it "should allow inactive graders when used with a course" do
        @teacher.destroy
        fetcher = lambda do |contexts|
          fetch_for_course_and_other_contexts(contexts, expected_status: 200)
        end
        contexts = {course: @course, assignment: @assignment, grader: @teacher, student: @student}
        fetcher.call(contexts)
        contexts.delete(:student)
        fetcher.call(contexts)
        contexts.delete(:assignment)
        fetcher.call(contexts)
        contexts[:student] = @student
        fetcher.call(contexts)
      end
    end

    describe "courses not found" do
      context "for_course" do
        let(:nonexistent_course) { -1 }
        let(:params) do
          {
            assignment_id: @assignment.id,
            course_id: nonexistent_course,
            controller: :grade_change_audit_api,
            action: :for_course,
            format: :json
          }
        end
        let(:path) { "/api/v1/audit/grade_change/courses/#{nonexistent_course}" }

        it "returns a 404 when admin" do
          api_call_as_user(@viewing_user, :get, path, params, {}, {}, expected_status: 404)
        end

        it "returns a 401 when teacher" do
          api_call_as_user(@teacher, :get, path, params, {}, {}, expected_status: 401)
        end

        it "returns a 401 when not a teacher nor admin" do
          user = user_model
          api_call_as_user(user, :get, path, params, {}, {}, expected_status: 401)
        end
      end

      context "for_course_and_other_parameters" do
        let(:nonexistent_course) { -1 }
        let(:params) do
          {
            assignment_id: @assignment.id,
            course_id: nonexistent_course,
            controller: :grade_change_audit_api,
            action: :for_course_and_other_parameters,
            format: :json
          }
        end
        let(:path) { "/api/v1/audit/grade_change/courses/#{nonexistent_course}/assignments/#{@assignment.id}" }

        it "returns a 404 when admin" do
          api_call_as_user(@viewing_user, :get, path, params, {}, {}, expected_status: 404)
        end

        it "returns a 401 when teacher" do
          api_call_as_user(@teacher, :get, path, params, {}, {}, expected_status: 401)
        end

        it "returns a 401 when not teacher nor admin" do
          user = user_model
          api_call_as_user(user, :get, path, params, {}, {}, expected_status: 401)
        end
      end
    end

    describe "permissions" do
      it "should not authorize the endpoints with no permissions" do
        @user, @viewing_user = @user, user_model

        fetch_for_context(@course, expected_status: 401)
        fetch_for_context(@assignment, expected_status: 401)
        fetch_for_context(@student, expected_status: 401, type: "student")
        fetch_for_context(@teacher, expected_status: 401, type: "grader")
        test_course_and_contexts do |contexts|
          fetch_for_course_and_other_contexts(contexts, expected_status: 401)
        end
      end

      it "should not authorize the endpoints with :view_grade_changes and :manage_grades permissions revoked" do
        RoleOverride.manage_role_override(@account_user.account, @account_user.role,
          :view_grade_changes.to_s, override: false)
        RoleOverride.manage_role_override(@account_user.account, @account_user.role,
          :manage_grades.to_s, override: false)

        fetch_for_context(@course, expected_status: 401)
        fetch_for_context(@assignment, expected_status: 401)
        fetch_for_context(@student, expected_status: 401, type: "student")
        fetch_for_context(@teacher, expected_status: 401, type: "grader")
        test_course_and_contexts do |contexts|
          fetch_for_course_and_other_contexts(contexts, expected_status: 401)
        end
      end

      it "should not allow other account models" do
        new_root_account = Account.create!(name: 'New Account')
        allow(LoadAccount).to receive(:default_domain_root_account).and_return(new_root_account)
        @viewing_user = user_with_pseudonym(account: new_root_account)

        fetch_for_context(@course, expected_status: 401)
        fetch_for_context(@assignment, expected_status: 401)
        fetch_for_context(@student, expected_status: 401, type: "student")
        fetch_for_context(@teacher, expected_status: 401, type: "grader")
        test_course_and_contexts do |contexts|
          fetch_for_course_and_other_contexts(contexts, expected_status: 401)
        end
      end

      context "for teachers" do
        it "returns a 401 on for_assignment" do
          fetch_for_context(@assignment, expected_status: 401, user: @teacher)
        end

        it "returns a 401 on for_student" do
          fetch_for_context(@student, expected_status: 401, type: "student", user: @teacher)
        end

        it "returns a 401 on for_grader" do
          fetch_for_context(@teacher, expected_status: 401, type: "grader", user: @teacher)
        end

        it "returns a 200 on for_course" do
          fetch_for_context(@course, expected_status: 200, user: @teacher)
        end

        it "returns a 200 on for_course_and_other_parameters" do
          test_course_and_contexts do |context|
            fetch_for_course_and_other_contexts(context, expected_status: 200, user: @teacher)
          end
        end

        it "returns a 401 on for_course when not teacher in that course" do
          other_teacher = User.create!
          Course.create!.enroll_teacher(other_teacher).accept!
          fetch_for_context(@course, expected_status: 401, user: other_teacher)
        end

        it "returns a 401 on for_course_and_other_parameters when not teacher in that course" do
          other_teacher = User.create!
          Course.create!.enroll_teacher(other_teacher).accept!
          test_course_and_contexts do |context|
            fetch_for_course_and_other_contexts(context, expected_status: 401, user: other_teacher)
          end
        end
      end

      context "sharding" do
        specs_require_sharding

        before do
          @new_root_account = @shard2.activate{ Account.create!(name: 'New Account') }
          allow(LoadAccount).to receive(:default_domain_root_account).and_return(@new_root_account)
          allow(@new_root_account).to receive(:grants_right?).and_return(true)
          @viewing_user = user_with_pseudonym(account: @new_root_account)
        end

        it "should 404 if nothing matches the type" do
          fetch_for_context(@student, expected_status: 404, type: "student")
          fetch_for_context(@teacher, expected_status: 404, type: "grader")
        end

        it "should work for teachers" do
          course_with_teacher(account: @new_root_account, user: @teacher)
          fetch_for_context(@teacher, expected_status: 200, type: "grader")
        end

        it "should work for students" do
          course_with_student(account: @new_root_account, user: @student)
          fetch_for_context(@student, expected_status: 200, type: "student")
        end
      end
    end

    describe "pagination" do
      before do
        Auditors::GradeChange.record(@submission)
        Auditors::GradeChange.record(@submission)
        @json = fetch_for_context(@student, per_page: 2, type: "student")
      end

      it "should only return one page of results" do
        expect(@json['events'].size).to eq 2
      end

      it "should have pagination headers" do
        expect(response.headers['Link']).to match(/rel="next"/)
      end
    end
  end
end
