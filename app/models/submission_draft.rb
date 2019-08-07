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

class SubmissionDraft < ActiveRecord::Base
  belongs_to :submission, inverse_of: :submission_drafts
  has_many :submission_draft_attachments, inverse_of: :submission_draft, dependent: :delete_all
  has_many :attachments, through: :submission_draft_attachments

  validates :submission, presence: true
  validates :submission_attempt, numericality: { only_integer: true }
  validates :submission, uniqueness: { scope: :submission_attempt }
  validate :submission_attempt_matches_submission

  def submission_attempt_matches_submission
    root_submission_attempt = self.submission&.attempt || 0
    this_submission_attempt = self.submission_attempt || 0
    if this_submission_attempt > root_submission_attempt
      err = 'submission draft attempt cannot be larger then the submission attempt'
      errors.add(:submission_draft_attempt, err)
    end
  end
  private :submission_attempt_matches_submission
end
