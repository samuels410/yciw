#
# Copyright (C) 2019 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require_relative '../graphql_spec_helper'

RSpec.describe Mutations::CreateSubmission do
  before(:once) do
    course_with_student(active_all: true)
    @assignment = @course.assignments.create!(
      title: 'Example Assignment',
      submission_types: 'online_upload'
    )
    @attachment1 = attachment_with_context(@student)
    @attachment2 = attachment_with_context(@student)
  end

  def mutation_str(
    assignment_id: @assignment.id,
    submission_type: 'online_upload',
    body: nil,
    file_ids: []
  )
    <<~GQL
      mutation {
        createSubmission(input: {
          assignmentId: "#{assignment_id}"
          submissionType: #{submission_type}
          #{"body: \"#{body}\"" if body}
          fileIds: #{file_ids}
        }) {
          submission {
            _id
            attempt
            attachments {
              _id
              displayName
            }
            body
          }
          errors {
            attribute
            message
          }
        }
      }
    GQL
  end

  def run_mutation(opts = {}, current_user = @student)
    result = CanvasSchema.execute(
      mutation_str(opts),
      context: {
        current_user: current_user,
        request: ActionDispatch::TestRequest.create
      }
    )
    result.to_h.with_indifferent_access
  end

  it 'creates a new submission' do
    result = run_mutation(file_ids: [@attachment1.id, @attachment2.id])
    expect(
      result.dig(:data, :createSubmission, :submission, :_id)
    ).to eq Submission.last.id.to_s
  end

  context 'read permissions check' do
    it 'returns an error if the assignment is unpublished' do
      @assignment.unpublish!
      result = run_mutation
      expect(result.dig(:errors, 0, :message)).to eq 'not found'
    end
  end

  context 'submit permissions check' do
    it 'returns an error if the assignment is locked' do
      @assignment.update!(lock_at: 1.day.ago)
      result = run_mutation
      expect(result.dig(:errors, 0, :message)).to eq 'not found'
    end
  end

  context 'when the submission_type is an online_upload' do
    it 'returns an error if there are no attachments' do
      @assignment.update!(submission_types: 'online_upload')
      result = run_mutation(submission_type: 'online_upload')
      expect(result.dig(:data, :createSubmission, :errors, 0, :message)).to eq 'You must attach at least one file to this assignment'
    end

    it 'returns an error if any of the file_ids are not found' do
      @assignment.update!(submission_types: 'online_upload')
      result = run_mutation(submission_type: 'online_upload', file_ids: [1,2,3])
      expect(result.dig(:data, :createSubmission, :errors, 0, :message)).to eq 'No attachments found for the following ids: ["1", "2", "3"]'
    end

    it 'returns an error if the returned attachment does not have an allowed file extension' do
      @assignment.update!(submission_types: 'online_upload', allowed_extensions: 'allowed')
      result = run_mutation(submission_type: 'online_upload', file_ids: [@attachment1.id, @attachment2.id])
      expect(result.dig(:data, :createSubmission, :errors, 0, :message)).to eq 'Invalid file type'
    end

    it 'stores the correct attachments on the submission' do
      @assignment.update!(submission_types: 'online_upload')
      result = run_mutation(submission_type: 'online_upload', file_ids: [@attachment1.id, @attachment2.id])
      submission = Submission.find(result.dig(:data, :createSubmission, :submission, :_id))

      expect(submission.workflow_state).to eq 'submitted'

      ids = submission.attachment_ids.split(',')
      expect(ids.include?(result.dig(:data, :createSubmission, :submission, :attachments, 0, :_id))).to be true
      expect(ids.include?(result.dig(:data, :createSubmission, :submission, :attachments, 1, :_id))).to be true
    end
  end

  context 'when the submission_type is an online_text_entry' do
    it 'returns an error if the body is not provided' do
      @assignment.update!(submission_types: 'online_text_entry')
      result = run_mutation(submission_type: 'online_text_entry')
      expect(result.dig(:data, :createSubmission, :errors, 0, :message)).to eq 'Text entry submission cannot be empty'
    end

    it 'returns an error if the body is empty' do
      @assignment.update!(submission_types: 'online_text_entry')
      result = run_mutation(submission_type: 'online_text_entry', body: '')
      expect(result.dig(:data, :createSubmission, :errors, 0, :message)).to eq 'Text entry submission cannot be empty'
    end

    it 'saves the body to the submission' do
      result = run_mutation(submission_type: 'online_text_entry', body: 'thundercougarfalconbird')
      @assignment.update!(submission_types: 'online_text_entry')
      submission = Submission.find(result.dig(:data, :createSubmission, :submission, :_id))

      expect(submission.workflow_state).to eq 'submitted'
      expect(result.dig(:data, :createSubmission, :submission, :body)).to eq('thundercougarfalconbird')
    end
  end

  it 'respects assignment overrides for the given user' do
    @assignment.update!(lock_at: 1.day.ago)
    create_adhoc_override_for_assignment(@assignment, @student, {lock_at: 1.day.from_now})
    result = run_mutation(file_ids: [@attachment1.id, @attachment2.id])
    expect(
      result.dig(:data, :createSubmission, :submission, :_id)
    ).to eq Submission.last.id.to_s
  end

  it 'can do resubmissions' do
    (1..3).each do |i|
      result = run_mutation(file_ids: [@attachment1.id, @attachment2.id])
      expect(
        result.dig(:data, :createSubmission, :submission, :attempt)
      ).to eq i
    end
  end

  it 'returns a graceful error if the assignment is not found' do
    result = run_mutation(assignment_id: 12345)
    expect(result.dig(:errors, 0, :message)).to eq 'not found'
  end

  it 'returns a graceful error if model validation failed' do
    @assignment.update!(allowed_attempts: 1)
    Submission.find_by(user_id: @student.id).update!(attempt: 1)
    result = run_mutation(file_ids: [@attachment1.id, @attachment2.id])
    expect(
      result.dig(:data, :createSubmission, :errors, 0, :message)
    ).to eq 'you have reached the maximum number of allowed attempts for this assignment'
  end
end
