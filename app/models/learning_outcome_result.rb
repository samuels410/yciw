#
# Copyright (C) 2011 Instructure, Inc.
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

class LearningOutcomeResult < ActiveRecord::Base
  belongs_to :user
  belongs_to :learning_outcome
  belongs_to :alignment, :class_name => 'ContentTag', :foreign_key => :content_tag_id
  belongs_to :association_object, polymorphic:
      [:rubric_association, :assignment,
       { quiz: 'Quizzes::Quiz', assessment: 'LiveAssessments::Assessment' }],
      polymorphic_prefix: :association,
      foreign_type: :association_type, foreign_key: :association_id
  belongs_to :artifact, polymorphic:
      [:rubric_assessment, :submission,
       { quiz_submission: 'Quizzes::QuizSubmission', live_assessments_submission: 'LiveAssessments::Submission' }],
      polymorphic_prefix: true
  belongs_to :associated_asset, polymorphic:
      [:assessment_question, :assignment,
       { quiz: 'Quizzes::Quiz', assessment: 'LiveAssessments::Assessment' }],
      polymorphic_prefix: true
  belongs_to :context, polymorphic: [:course]
  has_many :learning_outcome_question_results, dependent: :destroy
  simply_versioned

  before_save :infer_defaults

  attr_accessible :learning_outcome, :user, :association_object, :alignment, :associated_asset

  def infer_defaults
    self.learning_outcome_id = self.alignment.learning_outcome_id
    self.context_code = "#{self.context_type.underscore}_#{self.context_id}" rescue nil
    self.original_score ||= self.score
    self.original_possible ||= self.possible
    self.original_mastery = self.mastery if self.original_mastery == nil
    calculate_percent!
    true
  end

  def calculate_percent!
    if self.score && self.possible
      self.percent = self.score.to_f / self.possible.to_f
    end
    self.percent = nil if self.percent && !self.percent.to_f.finite?
  end

  def assignment
    if self.association_object.is_a?(Assignment)
      self.association_object
    elsif self.artifact.is_a?(RubricAssessment)
      self.artifact.rubric_association.association_object
    else
      nil
    end
  end

  def save_to_version(attempt)
    current_version = self.versions.current.try(:model)
    if current_version.try(:attempt) && attempt < current_version.attempt
      versions = self.versions.sort_by(&:created_at).reverse.select{|v| v.model.attempt == attempt}
      if !versions.empty?
        versions.each do |version|
          version_data = YAML::load(version.yaml)
          version_data["score"] = self.score
          version_data["mastery"] = self.mastery
          version_data["possible"] = self.possible
          version_data["attempt"] = self.attempt
          version_data["title"] = self.title
          version.yaml = version_data.to_yaml
          version.save
        end
      else
        save
      end
    else
      save
    end
  end

  def submitted_or_assessed_at
    submitted_at || assessed_at
  end

  scope :for_context_codes, lambda { |codes|
    if codes == 'all'
      all
    else
      where(:context_code => codes)
    end
  }
  scope :for_user, lambda { |user| where(:user_id => user) }
  scope :custom_ordering, lambda { |param|
    orders = {
      'recent' => "assessed_at DESC",
      'highest' => "score DESC",
      'oldest' => "score ASC",
      'default' => "assessed_at DESC"
    }
    order_clause = orders[param] || orders['default']
    order(order_clause)
  }
  scope :for_outcome_ids, lambda { |ids| where(:learning_outcome_id => ids) }
  scope :for_association, lambda { |association| where(:association_type => association.class.to_s, :association_id => association.id) }
  scope :for_associated_asset, lambda { |associated_asset| where(:associated_asset_type => associated_asset.class.to_s, :associated_asset_id => associated_asset.id) }
  scope :active, lambda { where("content_tags.workflow_state <> 'deleted'").joins(:alignment) }
end
