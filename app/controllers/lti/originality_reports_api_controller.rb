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

module Lti
# @API Originality Reports
# **LTI API for OriginalityReports (Must use <a href="jwt_access_tokens.html">JWT access tokens</a> with this API).**
#
# Originality reports may be used by external tools providing plagiarism
# detection services to give an originality score to an assignment
# submission's file. An originality report has an associated
# file ID (the file submitted by the student) and an originality score
# between 0 and 100.
#
# Note that when creating or updating an originality report a
# `tool_setting[resource_type_code]` may be specified as part of the originality report.
# This parameter should be used if the tool provider wishes to display
# originality reports as LTI launches.
#
# The value of `tool_setting[resource_type_code]` should be a
# resource_handler's "resource_type" code. Canvas will lookup the resource
# handler specified and do a launch to the message with the type
# "basic-lti-launch-request" using its "path". If the optional
# `tool_setting[resource_url]` parameter is provided, Canvas
# will use this URL instead of the message's `path` but will
# still send all the parameters specified by the message. When using the
# `tool_setting[resource_url]` the `tool_setting[resource_type_code]` must also be
# specified.
#
# @model ToolSetting
#     {
#       "id": "ToolSetting",
#       "description": "",
#       "properties": {
#          "resource_type_code": {
#            "description": "the resource type code of the resource handler to use to display originality reports",
#            "example": "originality_reports",
#            "type": "string"
#          },
#          "resource_url": {
#            "description": "a URL that may be used to override the launch URL inferred by the specified resource_type_code. If used a 'resource_type_code' must also be specified.",
#            "example": "http://www.test.com/originality_report",
#            "type": "string"
#          }
#       }
#     }
#
# @model OriginalityReport
#     {
#       "id": "OriginalityReport",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "The id of the OriginalityReport",
#           "example": "4",
#           "type": "integer"
#         },
#         "file_id": {
#           "description": "The id of the file receiving the originality score",
#           "example": "8",
#           "type": "integer"
#         },
#         "originality_score": {
#           "description": "A number between 0 and 100 representing the originality score",
#           "example": "0.16",
#           "type": "number"
#         },
#         "originality_report_file_id": {
#           "description": "The ID of the file within Canvas containing the originality report document (if provided)",
#           "example": "23",
#           "type": "integer"
#         },
#         "originality_report_url": {
#           "description": "A non-LTI launch URL where the originality score of the file may be found.",
#           "example": "http://www.example.com/report",
#           "type": "string"
#         },
#         "tool_setting": {
#            "description": "A ToolSetting object containing optional 'resource_type_code' and 'resource_url'",
#            "type": "ToolSetting"
#         }
#       }
#     }
  class OriginalityReportsApiController < ApplicationController
    include Lti::Ims::AccessTokenHelper

    ORIGINALITY_REPORT_SERVICE = 'vnd.Canvas.OriginalityReport'.freeze

    SERVICE_DEFINITIONS = [
      {
        id: ORIGINALITY_REPORT_SERVICE,
        endpoint: 'api/lti/assignments/{assignment_id}/submissions/{submission_id}/originality_report',
        format: ['application/json'].freeze,
        action: ['POST', 'PUT', 'GET'].freeze
      }.freeze
    ].freeze

    skip_before_action :load_user
    before_action :authorized_lti2_tool, :plagiarism_feature_flag_enabled
    before_action :attachment_in_context, only: [:create]
    before_action :report_in_context, only: [:update, :show]

    # @API Create an Originality Report
    # Create a new OriginalityReport for the specified file
    #
    # @argument originality_report[file_id] [Required, Integer]
    #   The id of the file being given an originality score.
    #
    # @argument originality_report[originality_score] [Required, Float]
    #   A number between 0 and 100 representing the measure of the
    #   specified file's originality.
    #
    # @argument originality_report[originality_report_url] [String]
    #   The URL where the originality report for the specified
    #   file may be found.
    #
    # @argument originality_report[originality_report_file_id] [Integer]
    #    The ID of the file within Canvas that contains the originality
    #    report for the submitted file provided in the request URL.
    #
    # @argument originality_report[tool_setting][resource_type_code] [String]
    #   The resource type code of the resource handler Canvas should use for the
    #   LTI launch for viewing originality reports. If set Canvas will launch
    #   to the message with type 'basic-lti-launch-request' in the specified
    #   resource handler rather than using the originality_report_url.
    #
    # @argument originality_report[tool_setting][resource_url] [String]
    #   The URL Canvas should launch to when showing an LTI originality report.
    #   Note that this value is inferred from the specified resource handler's
    #   message "path" value (See `resource_type_code`) unless
    #   it is specified. If this parameter is used a `resource_type_code`
    #   must also be specified.
    #
    # @argument originality_report[workflow_state] [String]
    #   May be set to "pending", "error", or "scored". If an originality score
    #   is provided a workflow state of "scored" will be inferred.
    #
    # @returns OriginalityReport
    def create
      render_unauthorized_action and return unless tool_proxy_associated?
      @report = OriginalityReport.create!(create_report_params)
      render json: api_json(@report, @current_user, session), status: :created
    rescue ActiveRecord::RecordInvalid
      return render json: @report.errors, status: :bad_request
    rescue ActiveRecord::RecordNotUnique
      return render json: {error: {message: I18n.t('the specified file with file_id already has an originality report'),
                                   type: 'RecordNotUnique'}}, status: :bad_request
    end

    # @API Edit an Originality Report
    # Modify an existing originality report
    #
    # @argument originality_report[originality_score] [Float]
    #   A number between 0 and 100 representing the measure of the
    #   specified file's originality.
    #
    # @argument originality_report[originality_report_url] [String]
    #   The URL where the originality report for the specified
    #   file may be found.
    #
    # @argument originality_report[originality_report_file_id] [Integer]
    #    The ID of the file within Canvas that contains the originality
    #    report for the submitted file provided in the request URL.
    #
    # @argument originality_report[tool_setting][resource_type_code] [String]
    #   The resource type code of the resource handler Canvas should use for the
    #   LTI launch for viewing originality reports. If set Canvas will launch
    #   to the message with type 'basic-lti-launch-request' in the specified
    #   resource handler rather than using the originality_report_url.
    #
    # @argument originality_report[tool_setting][resource_url] [String]
    #   The URL Canvas should launch to when showing an LTI originality report.
    #   Note that this value is inferred from the specified resource handler's
    #   message "path" value (See `resource_type_code`) unless
    #   it is specified. If this parameter is used a `resource_type_code`
    #   must also be specified.
    #
    # @argument originality_report[workflow_state] [String]
    #   May be set to "pending", "error", or "scored". If an originality score
    #   is provided a workflow state of "scored" will be inferred.
    #
    # @returns OriginalityReport
    def update
      render_unauthorized_action and return unless tool_proxy_associated?
      if @report.update_attributes(update_report_params)
        render json: api_json(@report, @current_user, session)
      else
        render json: @report.errors, status: :bad_request
      end
    end

    # @API Show an Originality Report
    # Get a single originality report
    #
    # @returns OriginalityReport
    def show
      render_unauthorized_action and return unless tool_proxy_associated?
      render json: api_json(@report, @current_user, session)
    end

    def lti2_service_name
      ORIGINALITY_REPORT_SERVICE
    end

    private

    def link_id(tool_setting_params)
      resource_type_code = tool_setting_params&.dig('resource_type_code')
      if resource_type_code.present?
        rh = tool_proxy.resources.find_by(resource_type_code: resource_type_code)
        resource_link_id(rh, tool_setting_params['resource_url'])
      end
    end

    def resource_link_id(resource_handler, lti_url = nil)
      tool_setting = resource_handler.find_or_create_tool_setting(resource_url: lti_url,
                                                                  link_fragment: link_fragment,
                                                                  context: attachment_association)
      tool_setting.resource_link_id
    end

    def link_fragment
      Lti::Asset.global_context_id_for(submission)
    end

    def tool_proxy_associated?
      PermissionChecker.authorized_lti2_action?(tool: tool_proxy, context: assignment)
    end

    def plagiarism_feature_flag_enabled
      render_unauthorized_action unless assignment.context.root_account.feature_enabled?(:plagiarism_detection_platform)
    end

    def create_attributes
      [:originality_score,
       :file_id,
       :originality_report_file_id,
       :originality_report_url,
       :workflow_state,
       tool_setting: %i(resource_url resource_type_code)].freeze
    end

    def update_attributes
      [:originality_report_file_id,
       :originality_report_url,
       :originality_score,
       :workflow_state,
       tool_setting: %i(resource_url resource_type_code)].freeze
    end

    def assignment
      @_assignment ||= Assignment.find(params[:assignment_id])
    end

    def submission
      @_submission ||= begin
        if params[:file_id].present?
          AttachmentAssociation.find_by(attachment_id: params[:file_id])&.context
        else
          Submission.active.find(params[:submission_id])
        end
      end
    end

    def attachment
      @_attachment ||= begin
        attachment = Attachment.find(params[:file_id]) if params[:file_id].present?
        if attachment.blank? && params.require(:originality_report)[:file_id].present?
          attachment = Attachment.find(params.require(:originality_report)[:file_id])
        end
        attachment
      end
    end

    def attachment_association
      @_attachment_association ||= begin
        file = @report&.attachment || attachment
        file.attachment_associations.find { |a| a.context == submission }
      end
    end

    def create_report_params
      @_create_report_params ||= begin
        report_attributes = params.require(:originality_report).permit(create_attributes).to_unsafe_h.merge(
          {submission_id: params.require(:submission_id)}
        )
        report_attributes['link_id'] = link_id(report_attributes.delete('tool_setting'))
        report_attributes
      end
    end

    def update_report_params
      @_update_report_params ||= begin
        report_attributes = params.require(:originality_report).permit(update_attributes)
        report_attributes['link_id'] = link_id(report_attributes.delete('tool_setting'))
        report_attributes
      end
    end

    def attachment_in_context
      verify_submission_attachment(attachment, submission)
    end

    def report_in_context
      @report = OriginalityReport.find_by(id: params[:id]) || OriginalityReport.find_by!(attachment_id: attachment&.id)
      verify_submission_attachment(@report.attachment, submission)
    end

    def verify_submission_attachment(attachment, submission)
      head :not_found and return unless attachment.present? && submission.present?
      unless submission.assignment == assignment && submission.attachments.include?(attachment)
        head :unauthorized
      end
    end

    # @!appendix Originality Report UI Locations
    #
    # {include:file:doc/api/originality_report_appendix.md}
  end
end
