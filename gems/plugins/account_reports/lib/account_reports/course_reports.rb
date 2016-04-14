#
# Copyright (C) 2013 - 2014 Instructure, Inc.
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

require 'account_reports/report_helper'

module AccountReports

  class CourseReports
    include ReportHelper

    def initialize(account_report)
      @account_report = account_report
      extra_text_term(@account_report)
    end

    def default_courses
      root_account.all_courses.
        select([:id, :sis_source_id, :name, :course_code, :start_at,
                :conclude_at, :restrict_enrollments_to_course_dates])
    end

    def recently_deleted
      csv(default_courses.where("workflow_state = 'deleted' AND updated_at > ?",
                                30.days.ago))
    end

    def public_courses
      csv(default_courses.active.where(is_public: true))
    end

    def unpublished_courses
      csv(default_courses.where(:workflow_state => ['claimed', 'created']))
    end

    def course_storage
      courses = root_account.all_courses.active.preload(:account)
      courses = add_course_sub_account_scope(courses)
      courses = add_term_scope(courses)

      filename = AccountReports.generate_file(@account_report)
      CSV.open(filename, "w") do |csv|
        headers = []
        headers << I18n.t('id')
        headers << I18n.t('sis id')
        headers << I18n.t('short name')
        headers << I18n.t('name')
        headers << I18n.t('account id')
        headers << I18n.t('account sis id')
        headers << I18n.t('account name')
        headers << I18n.t('storage used in MB')
        csv << headers

        Shackles.activate(:slave) do
          @total = courses.count(:all)
          i = 0

          courses.find_each do |c|
            row = []
            row << c.id
            row << c.sis_source_id
            row << c.course_code
            row << c.name
            row << c.account_id
            row << c.account.sis_source_id
            row << c.account.name
            row << c.storage_quota_used_mb.round(2)
            csv << row
            i += 1
            if i % 5 == 0
              Shackles.activate(:master) do
                @account_report.update_attribute(:progress, (i.to_f/@total)*100)
              end
            end
          end
        end
      end
      send_report(filename)

    end

    def csv(courses)
      courses = add_course_sub_account_scope(courses)
      courses = add_term_scope(courses)

      filename = AccountReports.generate_file(@account_report)
      CSV.open(filename, "w") do |csv|
        headers = []
        headers << I18n.t('#account_reports.report_header_id', 'id')
        headers << I18n.t('#account_reports.report_header_sis_id', 'sis id')
        headers << I18n.t('#account_reports.report_header_short_name', 'short name')
        headers << I18n.t('#account_reports.report_header_name', 'name')
        headers << I18n.t('#account_reports.report_header_start_date', 'start date')
        headers << I18n.t('#account_reports.report_header_end_date', 'end date')
        csv << headers
        Shackles.activate(:slave) do
          @total = courses.count(:all)
          i = 0

          courses.find_each do |c|
            row = []
            row << c.id
            row << c.sis_source_id
            row << c.course_code
            row << c.name

            if c.restrict_enrollments_to_course_dates
              row << default_timezone_format(c.start_at)
              row << default_timezone_format(c.conclude_at)
            else
              row << nil
              row << nil
            end

            csv << row
            i += 1
            if i % 5 == 0
              Shackles.activate(:master) do
                @account_report.update_attribute(:progress, (i.to_f/@total)*100)
              end
            end

          end
        end
      end
      send_report(filename)

    end

    def unused_courses()
      file = AccountReports.generate_file(@account_report)
      CSV.open(file, "w") do |csv|
        courses = root_account.all_courses.active.
          select("courses.id, courses.name, courses.course_code,
                  courses.sis_source_id, courses.created_at,
             CASE WHEN courses.workflow_state = 'claimed' THEN 'unpublished'
                  WHEN courses.workflow_state = 'created' THEN 'unpublished'
                  WHEN courses.workflow_state = 'completed' THEN 'concluded'
                  WHEN courses.workflow_state = 'available' THEN 'active'
              END AS course_state").
          where("NOT EXISTS (SELECT NULL
                             FROM #{Assignment.quoted_table_name} a
                             WHERE a.context_id = courses.id
                               AND a.context_type = 'Course'
                               AND a.workflow_state <> 'deleted')
             AND NOT EXISTS (SELECT NULL
                             FROM #{Attachment.quoted_table_name} at
                             WHERE at.context_id = courses.id
                               AND at.context_type = 'Course'
                               AND at.file_state <> 'deleted')
             AND NOT EXISTS (SELECT NULL
                             FROM #{DiscussionTopic.quoted_table_name} d
                             WHERE d.context_id = courses.id
                               AND d.context_type = 'Course'
                               AND d.workflow_state <> 'deleted')
             AND NOT EXISTS (SELECT NULL
                             FROM #{ContextModule.quoted_table_name} m
                             WHERE m.context_id = courses.id
                               AND m.context_type = 'Course'
                               AND m.workflow_state <> 'deleted')
             AND NOT EXISTS (SELECT NULL
                             FROM #{Quizzes::Quiz.quoted_table_name} q
                             WHERE q.context_id = courses.id
                               AND q.context_type = 'Course'
                               AND q.workflow_state <> 'deleted')
             AND NOT EXISTS (SELECT NULL
                             FROM #{WikiPage.quoted_table_name} w
                             WHERE w.wiki_id = courses.wiki_id
                               AND w.workflow_state <> 'deleted')")

        courses = add_term_scope(courses)
        courses = add_course_sub_account_scope(courses)

        headers = []
        headers << I18n.t('#account_reports.report_header_course_id', 'course id')
        headers << I18n.t('#account_reports.report_header_course_sis_id', 'course sis id')
        headers << I18n.t('#account_reports.report_header_short_name', 'short name')
        headers << I18n.t('#account_reports.report_header_long_name', 'long name')
        headers << I18n.t('#account_reports.report_header_status', 'status')
        headers << I18n.t('#account_reports.report_header_created_at', 'created at')
        csv << headers

        Shackles.activate(:slave) do
          courses.find_each do |c|
            row = []
            row << c["id"]
            row << c["sis_source_id"]
            row << c["course_code"]
            row << c["name"]
            row << c["course_state"]
            row << default_timezone_format(c["created_at"])
            csv << row
          end
        end
      end

      send_report(file)
    end
  end

end
