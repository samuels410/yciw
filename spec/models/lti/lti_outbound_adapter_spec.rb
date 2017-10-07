#
# Copyright (C) 2014 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Lti::LtiOutboundAdapter do
  let(:url) { '/launch/url' }
  let(:account) { Account.new }
  let(:return_url) { '/return/url' }
  let(:user) { User.new }
  let(:resource_type) { :lti_launch_type }
  let(:tool_url) { 'http://www.tool.com/launch/url?firstname=rory' }

  let(:tool) {
    ContextExternalTool.new.tap do |tool|
      allow(tool).to receive(:id).and_return('tool_id')
      tool.url = tool_url
    end
  }

  let(:user) { User.create! }

  let(:context) {
    Course.new.tap do |course|
      allow(course).to receive(:id).and_return('course_id')
      course.root_account = account
      course.account = account
    end
  }

  let(:assignment) {
    Assignment.new.tap do |assignment|
      allow(assignment).to receive(:id).and_return('assignment_id')
    end
  }

  let(:subject) { adapter }
  let(:adapter) { Lti::LtiOutboundAdapter.new(tool, user, context) }
  let(:lti_consumer_instance) { LtiOutbound::LTIConsumerInstance.new }
  let(:lti_context) {
    LtiOutbound::LTIContext.new.tap do |lti_context|
      lti_context.consumer_instance = lti_consumer_instance
    end
  }
  let(:lti_user) { LtiOutbound::LTIUser.new }
  let(:lti_tool) { LtiOutbound::LTITool.new }
  let(:lti_assignment) { LtiOutbound::LTIAssignment.new }
  let(:controller) do
    request_mock = double('request')
    allow(request_mock).to receive(:host).and_return('/my/url')
    allow(request_mock).to receive(:scheme).and_return('https')
    m = double('controller')
    allow(m).to receive(:request).and_return(request_mock)
    allow(m).to receive(:logged_in_user).and_return(@user || user)
    m
  end
  let(:variable_expander)do
    Lti::VariableExpander.new(account, context, controller, current_user: user )
  end

  before(:each) do
    allow_any_instance_of(Lti::LtiContextCreator).to receive(:convert).and_return(lti_context)
    allow_any_instance_of(Lti::LtiUserCreator).to receive(:convert).and_return(lti_user)
    allow_any_instance_of(Lti::LtiToolCreator).to receive(:convert).and_return(lti_tool)
    allow_any_instance_of(Lti::LtiAssignmentCreator).to receive(:convert).and_return(lti_assignment)
  end

  describe "#prepare_tool_launch" do
    it "passes the return_url through" do
      expect(LtiOutbound::ToolLaunch).to receive(:new) { |options| expect(options[:return_url]).to eq return_url }

      adapter.prepare_tool_launch(return_url, variable_expander)
    end

    it "generates the outgoing_email_address" do
      allow(HostUrl).to receive(:outgoing_email_address).and_return('email@email.com')
      expect(LtiOutbound::ToolLaunch).to receive(:new) { |options| expect(options[:outgoing_email_address]).to eq 'email@email.com' }

      adapter.prepare_tool_launch(return_url, variable_expander)
    end

    context "launch url" do
      it "gets the launch url from the tool" do
        expect(LtiOutbound::ToolLaunch).to receive(:new) { |options| expect(options[:url]).to eq tool.url }

        adapter.prepare_tool_launch(return_url, variable_expander)
      end

      it "gets the launch url from the tool settings when resource_type is specified" do
        expect(tool).to receive(:extension_setting).with(resource_type, :url).and_return('/resource/launch/url')
        expect(LtiOutbound::ToolLaunch).to receive(:new) { |options| expect(options[:url]).to eq '/resource/launch/url' }

        adapter.prepare_tool_launch(return_url, variable_expander, resource_type: resource_type)
      end

      it "passes the launch url through when provided" do
        expect(LtiOutbound::ToolLaunch).to receive(:new) { |options| expect(options[:url]).to eq url }

        adapter.prepare_tool_launch(return_url, variable_expander, launch_url: url)
      end
    end

    it "accepts selected html" do
      expect(LtiOutbound::ToolLaunch).to receive(:new) { |options| expect(options[:selected_html]).to eq '<div>something</div>' }

      adapter.prepare_tool_launch(return_url, variable_expander, selected_html: '<div>something</div>')
    end

    context "link code" do
      it "generates the link_code when excluded" do
        generated_link_code = 'abc123'
        tool = ContextExternalTool.new
        allow(tool).to receive(:opaque_identifier_for).and_return(generated_link_code)
        adapter = Lti::LtiOutboundAdapter.new(tool, user, context)

        expect(LtiOutbound::ToolLaunch).to receive(:new) { |options| expect(options[:link_code]).to eq generated_link_code }

        adapter.prepare_tool_launch(return_url, variable_expander)
      end

      it "passes the link_code through when provided" do
        link_code = 'link_code'
        expect(LtiOutbound::ToolLaunch).to receive(:new) { |options| expect(options[:link_code]).to eq link_code }

        adapter.prepare_tool_launch(return_url, variable_expander, link_code: link_code)
      end
    end

    context "resource_type" do
      it "passes the resource_type through when provided" do
        expect(LtiOutbound::ToolLaunch).to receive(:new) { |options| expect(options[:resource_type]).to eq :lti_launch_type }

        adapter.prepare_tool_launch(return_url, variable_expander, resource_type: resource_type)
      end
    end

    context "lti outbound object creation" do
      it "creates an lti_context" do
        expect(LtiOutbound::ToolLaunch).to receive(:new) { |options| expect(options[:context]).to eq lti_context }

        adapter.prepare_tool_launch(return_url, variable_expander)
      end

      it "creates an lti_user" do
        expect(LtiOutbound::ToolLaunch).to receive(:new) { |options| expect(options[:user]).to eq lti_user }

        adapter.prepare_tool_launch(return_url, variable_expander)
      end

      it "creates an lti_tool" do
        expect(LtiOutbound::ToolLaunch).to receive(:new) { |options| expect(options[:tool]).to eq lti_tool }

        adapter.prepare_tool_launch(return_url, variable_expander)
      end
    end
  end

  context "link_params" do
    let(:link_params) {{ext: {lti_assignment_id: "1234"}}}

    it "passes through the secure_parameters when provided" do
      expect(LtiOutbound::ToolLaunch).to receive(:new) { |options| expect(options[:link_params]).to eq link_params }
      adapter.prepare_tool_launch(return_url, variable_expander, {link_params: link_params})
    end

  end

  describe "#launch_url" do
    it "returns the launch url from the prepared tool launch" do
      tool_launch = double('tool launch', url: '/launch/url')
      allow(LtiOutbound::ToolLaunch).to receive(:new).and_return(tool_launch)
      adapter.prepare_tool_launch(return_url, variable_expander)

      expect(adapter.launch_url).to eq '/launch/url'
    end

    it "raises a not prepared error if the tool launch has not been prepared" do
      expect { adapter.launch_url }.to raise_error(RuntimeError, 'Called launch_url before calling prepare_tool_launch')
    end
  end

  describe "#generate_post_payload" do
    it "calls generate on the tool launch" do
      tool_launch = double('tool launch')
      expect(tool_launch).to receive_messages(generate: {})
      allow(tool_launch).to receive_messages(url: "http://example.com/launch")
      allow(LtiOutbound::ToolLaunch).to receive(:new).and_return(tool_launch)
      adapter.prepare_tool_launch(return_url, variable_expander)
      adapter.generate_post_payload
    end

    it "does not copy query params to the post body if oauth_compliant tool setting is enabled" do
      allow(account).to receive(:all_account_users_for).with(user).and_return([])
      tool.settings = {oauth_compliant: true}
      adapter.prepare_tool_launch(return_url, variable_expander)
      payload = adapter.generate_post_payload
      expect(payload['firstname']).to be_nil
    end

    it "includes the 'ext_lti_assignment_id' if the optional assignment parameter is present" do
      assignment.update_attributes(lti_context_id: SecureRandom.uuid)
      adapter.prepare_tool_launch(return_url, variable_expander)
      payload = adapter.generate_post_payload(assignment: assignment)
      expect(payload['ext_lti_assignment_id']).to eq assignment.lti_context_id
    end

    it "does not include the 'ext_lti_assignment_id' if the optional assignment parameter is absent" do
      adapter.prepare_tool_launch(return_url, variable_expander)
      payload = adapter.generate_post_payload(assignment: assignment)
      expect(payload.keys).not_to include 'ext_lti_assignment_id'
    end

    it "raises a not prepared error if the tool launch has not been prepared" do
      expect { adapter.generate_post_payload }.to raise_error(RuntimeError, 'Called generate_post_payload before calling prepare_tool_launch')
    end
  end

  describe "#generate_post_payload_for_assignment" do
    let(:outcome_service_url) { '/outcome/service' }
    let(:legacy_outcome_service_url) { '/legacy/service' }
    let(:lti_turnitin_outcomes_placement_url) { 'turnitin/outcomes/placement' }
    let(:tool_launch) { double('tool launch', generate: {}, url: "http://example.com/launch") }

    before(:each) do
      allow(LtiOutbound::ToolLaunch).to receive(:new).and_return(tool_launch)
    end

    it "includes the 'ext_lti_assignment_id' parameter" do
      assignment.update_attributes(lti_context_id: SecureRandom.uuid)
      adapter.prepare_tool_launch(return_url, variable_expander)
      expect(tool_launch).to receive(:for_assignment!).with(lti_assignment, outcome_service_url, legacy_outcome_service_url, lti_turnitin_outcomes_placement_url)
      payload = adapter.generate_post_payload_for_assignment(assignment, outcome_service_url, legacy_outcome_service_url, lti_turnitin_outcomes_placement_url)
      expect(payload['ext_lti_assignment_id']).to eq assignment.lti_context_id
    end

    it "creates an lti_assignment" do
      adapter.prepare_tool_launch(return_url, variable_expander)

      expect(tool_launch).to receive(:for_assignment!).with(lti_assignment, outcome_service_url, legacy_outcome_service_url, lti_turnitin_outcomes_placement_url)

      adapter.generate_post_payload_for_assignment(assignment, outcome_service_url, legacy_outcome_service_url, lti_turnitin_outcomes_placement_url)
    end

    it "generates the correct source_id for the assignment" do
      generated_sha = 'generated_sha'
      allow(Canvas::Security).to receive(:hmac_sha1).and_return(generated_sha)
      source_id = "tool_id-course_id-assignment_id-#{user.id}-#{generated_sha}"
      allow(tool_launch).to receive(:for_assignment!)
      assignment_creator = double
      allow(assignment_creator).to receive(:convert).and_return(tool_launch)
      adapter.prepare_tool_launch(return_url, variable_expander)

      expect(Lti::LtiAssignmentCreator).to receive(:new).with(assignment, source_id).and_return(assignment_creator)

      adapter.generate_post_payload_for_assignment(assignment, outcome_service_url, legacy_outcome_service_url, lti_turnitin_outcomes_placement_url)
    end

    it "raises a not prepared error if the tool launch has not been prepared" do
      expect {
        adapter.generate_post_payload_for_assignment(assignment, outcome_service_url, legacy_outcome_service_url, lti_turnitin_outcomes_placement_url)
      }.to raise_error(RuntimeError, 'Called generate_post_payload_for_assignment before calling prepare_tool_launch')
    end

  end

  describe "#generate_post_payload_for_homework_submission" do
    it "creates an lti_assignment" do
      tool_launch = double('tool launch', generate: {}, url: "http://example.com/launch")
      allow(LtiOutbound::ToolLaunch).to receive(:new).and_return(tool_launch)
      adapter.prepare_tool_launch(return_url, variable_expander)

      expect(tool_launch).to receive(:for_homework_submission!).with(lti_assignment)

      adapter.generate_post_payload_for_homework_submission(assignment)
    end

    it "raises a not prepared error if the tool launch has not been prepared" do
      expect {
        adapter.generate_post_payload_for_homework_submission(assignment)
      }.to raise_error(RuntimeError, 'Called generate_post_payload_for_homework_submission before calling prepare_tool_launch')
    end
  end

  describe ".consumer_instance_class" do
    around do |example|
      orig_class = Lti::LtiOutboundAdapter.consumer_instance_class
      example.run
      Lti::LtiOutboundAdapter.consumer_instance_class = orig_class
    end

    it "returns the custom instance class if defined" do
      some_class = Class.new
      Lti::LtiOutboundAdapter.consumer_instance_class = some_class

      expect(Lti::LtiOutboundAdapter.consumer_instance_class).to eq some_class
    end

    it "returns the LtiOutbound::LTIConsumerInstance if none defined" do
      Lti::LtiOutboundAdapter.consumer_instance_class = nil
      expect(Lti::LtiOutboundAdapter.consumer_instance_class).to eq LtiOutbound::LTIConsumerInstance
    end
  end
end
