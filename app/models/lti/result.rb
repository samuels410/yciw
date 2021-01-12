# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

class Lti::Result < ApplicationRecord
  include Canvas::SoftDeletable

  GRADING_PROGRESS_TYPES = %w[FullyGraded Pending PendingManual Failed NotReady].freeze
  ACCEPT_GIVEN_SCORE_TYPES = %w[FullyGraded PendingManual].freeze
  ACTIVITY_PROGRESS_TYPES = %w[Initialized Started InProgress Submitted Completed].freeze

  AGS_EXT_SUBMISSION = 'https://canvas.instructure.com/lti/submission'.freeze

  self.record_timestamps = false

  validates :line_item, :user, presence: true
  validates :result_maximum, presence: true, unless: proc { |r| r.result_score.blank? }
  validates :result_score, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :result_maximum, numericality: { greater_than: 0 }, allow_nil: true
  validates :activity_progress,
            inclusion: { in: ACTIVITY_PROGRESS_TYPES },
            allow_nil: true
  validates :grading_progress,
            inclusion: { in: GRADING_PROGRESS_TYPES },
            allow_nil: true

  belongs_to :submission, inverse_of: :lti_result
  belongs_to :user, inverse_of: :lti_results
  belongs_to :line_item, inverse_of: :results, foreign_key: :lti_line_item_id, class_name: 'Lti::LineItem'
  belongs_to :root_account, class_name: 'Account'
  has_one :assignment, through: :submission

  before_save :set_root_account

  # Returns the result_score scaled to the
  # result_maximum. This is required because
  # a user can update a score manually in the UI.
  #
  # In the future it may be worthwhile to persist
  # the scaled score on the result in an after_save
  # callback on submission. Doing so would reuquire
  # working out some performance issues.
  def scaled_result_score
    raw_result_score = read_attribute(:result_score)

    return raw_result_score if raw_result_score.blank? || submission.blank?

    # A negative grader_id indicates that no manual
    # adjustments were made by a Canvas user to the result.
    # If that's the case, we can just return the result_score
    # without additional scaling
    return raw_result_score if submission.grader_id.blank? || submission.grader_id < 0

    # We can also return the result_score if the assignment
    # has zero points possible
    return raw_result_score if assignment.points_possible&.zero?

    # The result was manually updated by a Canvas user.
    # Because the result_maximum may not be the same as the
    # assignment's points possible, we need to scale the
    # result_score to the result_maximum
    (raw_result_score * result_maximum) / assignment.points_possible.to_f
  end
  alias result_score scaled_result_score

  private

  def set_root_account
    self.root_account_id ||= self.submission&.root_account_id || self.line_item&.root_account_id
  end
end
