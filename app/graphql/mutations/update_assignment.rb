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

class Mutations::AssignmentOverrideCreateOrUpdate < GraphQL::Schema::InputObject
  argument :id, ID, required: false
  argument :due_at, Types::DateTimeType, required: false
  argument :lock_at, Types::DateTimeType, required: false
  argument :unlock_at, Types::DateTimeType, required: false

  argument :section_id, ID, required: false
  argument :group_id, ID, required: false
  argument :student_ids, [ID], required: false
end

class Mutations::AssignmentModeratedGradingUpdate < GraphQL::Schema::InputObject
  argument :enabled, Boolean, required: false
  argument :grader_count, Int, required: false
  argument :grader_comments_visible_to_graders, Boolean, required: false
  argument :grader_names_visible_to_final_grader, Boolean, required: false
  argument :graders_anonymous_to_graders, Boolean, required: false
  argument :final_grader_id, ID, required: false
end

class Mutations::AssignmentPeerReviewsUpdate < GraphQL::Schema::InputObject
  argument :enabled, Boolean, required: false
  argument :count, Int, required: false
  argument :due_at, Types::DateTimeType, required: false
  argument :intra_reviews, Boolean, required: false
  argument :anonymous_reviews, Boolean, required: false
  argument :automatic_reviews, Boolean, required: false
end

class Mutations::UpdateAssignment < Mutations::BaseMutation

  # we are required to wrap the update method with a proxy class because
  # we are required to include `Api` for instance methods within the module.
  # the main problem is that including the `Api` module conflicts with the
  # `Mutations::BaseMutation` class. so we have to segregate the two.
  #
  # probably a good idea to segregate anyways so we dont accidentally include
  # processing we dont want.
  class ApiProxy
    include Api
    include Api::V1::Assignment

    def initialize(request, working_assignment, session, current_user)
      @request = request
      @working_assignment = working_assignment
      @session = session
      @current_user = current_user
    end

    attr_reader :session

    def context
      @working_assignment.context
    end

    def grading_periods?
      @working_assignment.context.try(:grading_periods?)
    end

    def strong_anything
      ArbitraryStrongishParams::ANYTHING
    end

    def value_to_boolean(value)
      Canvas::Plugin.value_to_boolean(value)
    end

    def process_incoming_html_content(html)
      Api::Html::Content.process_incoming(html)
    end

    def load_root_account
      @domain_root_account = @request.env['canvas.domain_root_account'] || LoadAccount.default_domain_root_account
    end
  end

  graphql_name "UpdateAssignment"

  # input arguments
  argument :id, ID, required: true
  argument :name, String, required: false
  argument :state, Types::AssignmentType::AssignmentStateType, required: false
  argument :due_at, Types::DateTimeType, required: false
  argument :lock_at, Types::DateTimeType, required: false
  argument :unlock_at, Types::DateTimeType, required: false
  argument :description, String, required: false
  argument :assignment_overrides, [Mutations::AssignmentOverrideCreateOrUpdate], required: false
  argument :position, Int, required: false
  argument :points_possible, Float, required: false
  argument :grading_type, Types::AssignmentType::AssignmentGradingType, required: false
  argument :allowed_extensions, [String], required: false
  argument :assignment_group_id, ID, required: false
  argument :group_set_id, ID, required: false
  argument :allowed_attempts, Int, required: false
  argument :muted, Boolean, required: false
  argument :only_visible_to_overrides, Boolean, required: false
  argument :submission_types, [Types::AssignmentType::AssignmentSubmissionType], required: false
  argument :peer_reviews, Mutations::AssignmentPeerReviewsUpdate, required: false
  argument :moderated_grading, Mutations::AssignmentModeratedGradingUpdate, required: false
  argument :grade_group_students_individually, Boolean, required: false
  argument :omit_from_final_grade, Boolean, required: false
  argument :anonymous_instructor_annotations, Boolean, required: false
  argument :post_to_sis, Boolean, required: false
  argument :anonymous_grading, Boolean,
           "requires anonymous_marking course feature to be set to true",
           required: false
  argument :module_ids, [ID], required: false

  # the return data if the update is successful
  field :assignment, Types::AssignmentType, null: true

  def resolve(input:)
    assignment_id = GraphQLHelpers.parse_relay_or_legacy_id(input[:id], "Assignment")

    begin
      @working_assignment = Assignment.find(assignment_id)
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, "assignment not found: #{assignment_id}"
    end

    # check permissions asap
    raise GraphQL::ExecutionError, "insufficient permission" unless @working_assignment.grants_right? current_user, :update

    update_proxy = ApiProxy.new(context[:request], @working_assignment, context[:session], current_user)

    # to use the update_api_assignment method, we have to modify some of the
    # input. first, update_api_assignment doesnt expect a :state key. instead,
    # it expects a :published key of boolean type.
    # also, if we are required to transition to restored or destroyed, then we
    # need to handle those as well.
    input_hash = input.to_h
    other_update_on_assignment = false
    if input_hash.key? :state
      asked_state = input_hash.delete :state
      case asked_state
      when "unpublished"
        input_hash[:published] = false
        other_update_on_assignment = :ensure_restored
      when "published"
        input_hash[:published] = true
        other_update_on_assignment = :ensure_restored
      when "deleted"
        other_update_on_assignment = :ensure_destroyed
      else
        raise "unable to handle state change: #{asked_state}"
      end
    end

    # prepare the overrides if there are any
    if input_hash.key? :assignment_overrides
      update_proxy.load_root_account
      input_hash[:assignment_overrides].each do |override|
        if override[:id].blank?
          override.delete :id
        else
          override[:id] = GraphQLHelpers.parse_relay_or_legacy_id(override[:id], "AssignmentOverride")
        end
        override[:course_section_id] = GraphQLHelpers.parse_relay_or_legacy_id(override[:section_id], "Section") if override.key? :section_id
        override[:group_id] = GraphQLHelpers.parse_relay_or_legacy_id(override[:group_id], "Group") if override.key? :group_id
        override[:student_ids] = override[:student_ids].map { |id| GraphQLHelpers.parse_relay_or_legacy_id(id, "User") } if override.key? :student_ids
      end
    end

    # prepare moderated grading
    if input_hash.key? :moderated_grading
      moderated_grading = input_hash.delete(:moderated_grading)
      input_hash[:moderated_grading] = moderated_grading[:enabled] if moderated_grading.key? :enabled
      input_hash = input_hash.merge(moderated_grading.slice(:grader_count, :grader_comments_visible_to_graders,
                                                            :grader_names_visible_to_final_grader, :graders_anonymous_to_graders))
      if moderated_grading.key? :final_grader_id
        input_hash[:final_grader_id] = GraphQLHelpers.parse_relay_or_legacy_id(moderated_grading[:final_grader_id], "User")
      end
    end

    # prepare peer reviews
    if input_hash.key? :peer_reviews
      peer_reviews = input_hash.delete(:peer_reviews)
      input_hash[:peer_reviews] = peer_reviews[:enabled] if peer_reviews.key? :enabled
      input_hash[:peer_review_count] = peer_reviews[:count] if peer_reviews.key? :count
      input_hash[:intra_group_peer_reviews] = peer_reviews[:intra_reviews] if peer_reviews.key? :intra_reviews
      input_hash[:anonymous_peer_reviews] = peer_reviews[:anonymous_reviews] if peer_reviews.key? :anonymous_reviews
      input_hash[:automatic_peer_reviews] = peer_reviews[:automatic_reviews] if peer_reviews.key? :automatic_reviews

      # this should be peer_reviews_due_at, but its not permitted in the backend and peer_reviews_assign_at
      # is transformed into peer_reviews_due_at. that's probably a bug, but just to keep this update resilient
      # well get it working and if the bug needs to be addressed, we can later.
      input_hash[:peer_reviews_assign_at] = peer_reviews[:due_at]
    end

    # prepare other ids
    if input_hash.key? :assignment_group_id
      input_hash[:assignment_group_id] = GraphQLHelpers.parse_relay_or_legacy_id(input_hash[:assignment_group_id], "AssignmentGroup")
    end
    if input_hash.key? :group_set_id
      input_hash[:group_category_id] = GraphQLHelpers.parse_relay_or_legacy_id(input_hash.delete(:group_set_id), "GroupSet")
    end
    module_ids = nil
    if input_hash.key? :module_ids
      module_ids = input_hash.delete(:module_ids).map { |id| GraphQLHelpers.parse_relay_or_legacy_id(id, "Module") }.map(&:to_i)
    end


    # make sure to do other required updates
    self.send(other_update_on_assignment) if other_update_on_assignment

    # ensure the assignment is part of all required modules
    ensure_modules(module_ids) if module_ids

    # normal update now
    @working_assignment.content_being_saved_by(current_user)
    @working_assignment.updating_user = current_user
    result = update_proxy.update_api_assignment(@working_assignment, ActionController::Parameters.new(input_hash), current_user, @working_assignment.context)

    # return the result
    if [:ok, :created].include? result
      { assignment: @working_assignment }
    else
      { errors: @working_assignment.errors.entries }
    end
  end

  def ensure_modules(required_module_ids)
    content_tags = ContentTag.find(@working_assignment.context_module_tag_ids)
    current_module_ids = content_tags.map(&:context_module_id).uniq

    required_module_ids = required_module_ids.to_set
    current_module_ids = current_module_ids.to_set

    # we dont need to do anything if the current and required are the same.
    return if required_module_ids == current_module_ids

    # first, add all modules that are missing
    module_ids_to_add = (required_module_ids - current_module_ids).to_a
    unless module_ids_to_add.empty?
      ContextModule.find(module_ids_to_add).each do |context_module|
        context_module.add_item(:id => @working_assignment.id, :type => 'assignment')
      end
    end

    # now remove all _tags_ that are not required
    (current_module_ids - required_module_ids).to_set.each do |module_id_to_remove|
      # assignments can be part of multiple modules, so we have to search through all the tags
      # and if context_module_id is the module to remove, then we need to delete the tag
      content_tags.each do |tag|
        if tag.context_module_id == module_id_to_remove
          tag.destroy
        end
      end
    end

    # we need to reload the assignment so things get returned correctly
    @working_assignment.reload
  end

  def ensure_destroyed
    # check for permissions no matter what
    raise GraphQL::ExecutionError, "insufficient permission" unless @working_assignment.grants_right? current_user, :delete

    # if we are already destroyed, then dont do anything
    return if @working_assignment.workflow_state == "deleted"

    # actually destroy now.
    DueDateCacher.with_executing_user(@current_user) do
      @working_assignment.destroy
    end
  end

  def ensure_restored
    raise GraphQL::ExecutionError, "insufficient permission" unless @working_assignment.grants_right? current_user, :delete
    # if we are already not destroyed, then dont do anything
    return if @working_assignment.workflow_state != "deleted"

    @working_assignment.restore
  end
end
