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

require_relative '../common'
require_relative '../helpers/blueprint_common'


shared_context "blueprint sidebar context" do
  def sync_button
    f('.bcs__migration-sync__button button')
  end

  def unsynced_changes_link
    f('.bcs__content button#mcUnsyncedChangesBtn')
  end

  def blueprint_open_sidebar_button
    f('.blueprint__root .bcs__wrapper .bcs__trigger')
  end

  def sync_modal_send_notification_checkbox
    fj("span:contains('Send Notification')", f('.bcs__modal-content-wrapper'))
  end

  def sync_modal_add_message_checkbox
    fj("span:contains('Add a Message')", f('.bcs__modal-content-wrapper'))
  end

  def sync_modal_message_text_box
    f("textarea", f('.bcs__modal-content-wrapper'))
  end

  def send_notification_checkbox
    f('.bcs__history-settings')
      .find_element(:xpath, "//span[text()[contains(., 'Send Notification')]]")
  end

  def add_message_checkbox
    f('.bcs__history-notification__add-message')
      .find_element(:xpath, "//label/span/span[text()[contains(., 'Add a Message')]]")
  end

  def notification_message_text_box
    f('.bcs__history-notification__add-message')
      .find_element(:xpath, "//label/span/span/span/textarea")
  end

  def character_count
    f('.bcs__history-notification__add-message')
      .find_element(:xpath, "span")
  end

  def modal_sync_button
    f('#unsynced_changes_modal_sync .bcs__migration-sync__button')
  end

  def open_blueprint_sidebar
    get "/courses/#{@master.id}"
    blueprint_open_sidebar_button.click
  end

  def bcs_content_panel
    f('.bcs__content')
  end
end


describe "master courses sidebar" do
  include_context "in-process server selenium tests"
  include_context "blueprint sidebar context"
  include BlueprintCourseCommon


  before :once do
    Account.default.enable_feature!(:master_courses)
    @master = course_factory(active_all: true)
    @master_teacher = @teacher
    @template = MasterCourses::MasterTemplate.set_as_master_course(@master)
    @minion = @template.add_child_course!(course_factory(name: "Minion", active_all: true)).child_course

    # setup some stuff
    @file = attachment_model(context: @master, display_name: 'Some File')
    @assignment = @master.assignments.create! title: 'Blah', points_possible: 10
    run_master_course_migration(@master)

    # now push some incremental changes
    Timecop.freeze(2.seconds.from_now) do
      @page = @master.wiki_pages.create! title: 'Unicorn'
      page_tag = @template.content_tag_for(@page)
      page_tag.restrictions = @template.default_restrictions
      page_tag.save!
      @quiz = @master.quizzes.create! title: 'TestQuiz'
      @file = attachment_model(context: @master, display_name: 'Some File')
      @file.update(display_name: 'I Can Rename Files Too')
      @assignment.destroy
    end
  end

  describe "as a master course teacher" do
    before :each do
      user_session(@master_teacher)
    end

    it "should show sidebar trigger tab" do
     get "/courses/#{@master.id}"
     expect(blueprint_open_sidebar_button).to be_displayed
    end

    it "should show sidebar when trigger is clicked" do
      get "/courses/#{@master.id}"
      blueprint_open_sidebar_button.click
      expect(bcs_content_panel).to be_displayed
    end

    it "should not show the Associations button" do
      get "/courses/#{@master.id}"
      blueprint_open_sidebar_button.click
      expect(bcs_content_panel).not_to contain_css('button#mcSidebarAsscBtn')
    end

    it "should show Sync History modal when button is clicked" do
      get "/courses/#{@master.id}"
      blueprint_open_sidebar_button.click
      f('button#mcSyncHistoryBtn').click
      expect(f('div[aria-label="Sync History"]')).to be_displayed
      expect(f('#application')).to have_attribute('aria-hidden', 'true')
    end

    it "should show Unsynced Changes modal when button is clicked" do
      get "/courses/#{@master.id}"
      blueprint_open_sidebar_button.click
      wait_for_ajaximations
      f('button#mcUnsyncedChangesBtn').click
      wait_for_ajaximations
      expect(f('div[aria-label="Unsynced Changes"]')).to be_displayed
      expect(f('#application')).to have_attribute('aria-hidden', 'true')
    end

    it "should not show the tutorial sidebar button" do
      get "/courses/#{@master.id}"
      expect(f('body')).not_to contain_css('.TutorialToggleHolder button')
    end
  end


  describe "as a master course admin" do

    before :once do
      account_admin_user(active_all: true)
    end

    before :each do
      user_session(@admin)
    end

    it "should show the Associations button" do
      get "/courses/#{@master.id}"
      blueprint_open_sidebar_button.click
      expect(bcs_content_panel).to contain_css('button#mcSidebarAsscBtn')
    end

    it "should show Associations modal when button is clicked" do
      get "/courses/#{@master.id}"
      blueprint_open_sidebar_button.click
      f('button#mcSidebarAsscBtn').click
      expect(f('div[aria-label="Associations"]')).to be_displayed
    end

    it "limits notification message to 140 characters", priority: "2", test_id: 3186725 do
      msg = '1234567890123456789012345678901234567890123456789012345678901234567890'
      open_blueprint_sidebar
      send_notification_checkbox.click
      add_message_checkbox.click
      notification_message_text_box.send_keys(msg+msg+"A")
      expect(character_count).to include_text('(140/140)')
      expect(notification_message_text_box).not_to have_value('A')
    end


    context "before sync" do

      it "shows sync button and options before sync", priority: "2", test_id: 3186721 do
        open_blueprint_sidebar
        bcs_content = bcs_content_panel
        expect(bcs_content).to include_text("Unsynced Changes")
        expect(bcs_content).to contain_css('.bcs__row-right-content')
        expect(bcs_content).to include_text("Include Course Settings")
        expect(bcs_content).to include_text("Send Notification")
        expect(bcs_content).to contain_css('.bcs__migration-sync__button')
      end

      it "shows sync options in modal", priority: "2", test_id: 3186721 do
        open_blueprint_sidebar
        unsynced_changes_link.click
        bcs_content = bcs_content_panel
        expect(bcs_content).to include_text("Unsynced Changes")
        expect(bcs_content).to contain_css('.bcs__row-right-content')
        expect(bcs_content).to include_text("Include Course Settings")
        expect(bcs_content).to include_text("Send Notification")
        expect(bcs_content).to contain_css('.bcs__migration-sync__button')
      end
    end


    context "after sync" do
      before :each do
        open_blueprint_sidebar
        send_notification_checkbox.click
        add_message_checkbox.click
        notification_message_text_box.send_keys("sync that!")
        sync_button.click
        run_jobs
      end

      it "removes sync button after sync", priority: "2", test_id: 3186726 do
        refresh_page
        open_blueprint_sidebar
        test_var = false
        begin
          sync_button
        rescue
          test_var = true
        end
        expect(test_var).to be_truthy, "Sync button should not appear"
        expect(bcs_content_panel).not_to contain_css('button#mcUnsyncedChangesBtn')
      end

      it "removes notification options after sync", priority: "2", test_id: 3256295 do
        refresh_page
        open_blueprint_sidebar
        test_var = false
        begin
          unsynced_changes_link
        rescue
          test_var = true
        end
        expect(test_var).to be_truthy, "Unsynced changes link should not appear"
        bcs_content = bcs_content_panel
        expect(bcs_content).not_to include_text("Include Course Settings")
        expect(bcs_content).not_to include_text("Send Notification")
        expect(bcs_content).not_to contain_css('bcs__row-right-content')
        expect(bcs_content).not_to include_text("Add a Message")
        expect(bcs_content).not_to contain_css('.bcs__history-notification__message')
      end
    end

    it "closes modal after sync", priority: "2", test_id: 3186727 do
      open_blueprint_sidebar
      unsynced_changes_link.click
      sync_modal_send_notification_checkbox.click
      sync_modal_add_message_checkbox.click
      sync_modal_message_text_box.send_keys("sync that!")
      modal_sync_button.click
      run_jobs
      expect(f('.bcs__content')).not_to contain_css('.bcs__content button#mcUnsyncedChangesBtn')
    end
  end
end
