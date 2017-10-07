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

require_relative '../common'
require_relative '../helpers/announcements_common'
require_relative '../helpers/conferences_common'
require_relative '../helpers/course_common'
require_relative '../helpers/discussions_common'
require_relative '../helpers/files_common'
require_relative '../helpers/google_drive_common'
require_relative '../helpers/groups_common'
require_relative '../helpers/groups_shared_examples'
require_relative '../helpers/wiki_and_tiny_common'

describe "groups" do
  include_context "in-process server selenium tests"
  include AnnouncementsCommon
  include ConferencesCommon
  include CourseCommon
  include DiscussionsCommon
  include FilesCommon
  include GoogleDriveCommon
  include GroupsCommon
  include WikiAndTinyCommon

  setup_group_page_urls

  context "as a student" do
    before :once do
      @student = User.create!(name: "Student 1")
      @teacher = User.create!(name: "Teacher 1")
      course_with_student({user: @student, :active_course => true, :active_enrollment => true})
      enable_all_rcs @course.account
      @course.enroll_teacher(@teacher).accept!
      group_test_setup(4,1,1)
      # adds all students to the group
      add_users_to_group(@students + [@student],@testgroup.first)
    end

    before :each do
      user_session(@student)
      stub_rcs_config
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "announcements page" do
      it "should not allow group members to edit someone else's announcement", priority: "1", test_id: 327111 do
        create_group_announcement_manually("Announcement by #{@user.name}",'sup')
        user_session(@students.first)
        get announcements_page
        expect(ff('.discussion-topic').size).to eq 1
        f('.discussion-title').click
        expect(f("#content")).not_to contain_css('.edit-btn')
      end

      it "should allow all group members to see announcements", priority: "1", test_id: 273613 do
        @announcement = @testgroup.first.announcements.create!(title: 'Group Announcement', message: 'Group',user: @teacher)
        # Verifying with a few different group members should be enough to ensure all group members can see it
        verify_member_sees_announcement

        user_session(@students.first)
        verify_member_sees_announcement
      end
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "discussions page" do
      it "should allow discussions to be created within a group", priority: "1", test_id: 273615 do
        get discussions_page
        expect_new_page_load { f('#new-discussion-btn').click }
        # This creates the discussion and also tests its creation
        edit_topic('from a student', 'tell me a story')
      end

      it "should have two options when creating a discussion", priority: "1", test_id: 273617 do
        get discussions_page
        expect_new_page_load { f('#new-discussion-btn').click }
        expect(f('#threaded')).to be_displayed
        expect(f('#allow_rating')).to be_displayed
        # Shouldn't be Enable Podcast Feed option
        expect(f("#content")).not_to contain_css('#podcast_enabled')
      end
    end

    #-------------------------------------------------------------------------------------------------------------------
    describe "pages page" do
      it "should only allow group members to access pages", priority: "1", test_id: 315331 do
        get pages_page
        expect(f('.new_page')).to be_displayed
        verify_no_course_user_access(pages_page)
      end
    end
  end
end
