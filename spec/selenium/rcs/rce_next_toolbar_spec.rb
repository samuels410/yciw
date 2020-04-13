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

require_relative '../helpers/wiki_and_tiny_common'
require_relative 'pages/rcs_sidebar_page'
require_relative '../test_setup/common_helper_methods/custom_selenium_actions'
require_relative 'pages/rce_next_page'

describe "RCE Next toolbar features" do
  include_context "in-process server selenium tests"
  include WikiAndTinyCommon
  include RCSSidebarPage
  include CustomSeleniumActions
  include RCENextPage

  context "WYSIWYG generic as a teacher" do

    before(:each) do
      course_with_teacher_logged_in
      Account.default.enable_feature!(:rce_enhancements)
      stub_rcs_config
    end

    def create_wiki_page_with_text(page_title)
      @course.wiki_pages.create!(title: page_title, body: "<p>The sleeper must awaken.</p>")
    end

    it "should add bullet lists" do
      rce_wysiwyg_state_setup(@course)

      click_list_toggle_button
      click_bullet_list_button

      in_frame rce_page_body_ifr_id do
        expect(ff('#tinymce li').length).to eq 3
      end
    end

    it "should remove bullet lists" do
      text = "<ul><li>1</li><li>2</li><li>3</li></ul>"
      rce_wysiwyg_state_setup(@course, text, html: true)

      # editor window needs focus in chrome to enable bullet list button
      click_editor_window if driver.browser == :chrome

      click_list_toggle_button
      click_bullet_list_button

      in_frame rce_page_body_ifr_id do
        expect(wiki_body).not_to contain_css('li')
      end
    end

    it "should add numbered lists", priority: "1", test_id: 307625 do
      skip('Unskip in CORE-2636')
      wysiwyg_state_setup(@course)

      click_list_toggle_button
      click_numbered_list_button

      in_frame rce_page_body_ifr_id do
        expect(ff('#tinymce li').length).to eq 3
      end
    end

    it "should remove numbered lists", priority: "1", test_id: 537619 do
      skip('Unskip in CORE-2636')
      text = "<ol><li>1</li><li>2</li><li>3</li></ol>"
      wysiwyg_state_setup(@course, text, html: true)

      # editor window needs focus in chrome to enable number list button
      click_editor_window if driver.browser == :chrome
      click_list_toggle_button
      click_numbered_list_button

      in_frame rce_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('li')
      end
    end

    it "should indent and remove indentation for embedded images" do
      skip('Unskip in CORE-2637')
      title = "email.png"
      @root_folder = Folder.root_folders(@course).first
      @image = @root_folder.attachments.build(:context => @course)
      path = File.expand_path(File.dirname(__FILE__) + '/../../../public/images/email.png')
      @image.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
      @image.save!

      visit_front_page_edit(@course)
      click_images_toolbar_button
      click_course_images
      click_image_link(title)

      select_all_wiki
      force_click(indent_button)
      validate_wiki_style_attrib("padding-left", "40px", "p")

      force_click(indent_toggle_button)
      force_click(outdent_button)

      validate_wiki_style_attrib_empty("p")
    end

    it "should indent and remove indentation for text" do
      skip('Unskip in CORE-2637')
      wysiwyg_state_setup(@course, "test")

      click_indent_button
      validate_wiki_style_attrib("padding-left", "40px", "p")

      click_indent_toggle_button
      click_outdent_button

      validate_wiki_style_attrib_empty("p")
    end

    it "should make text superscript in rce" do
      skip('Unskip in CORE-2634')
      wysiwyg_state_setup(@course)

      click_superscript_button

      in_frame rce_page_body_ifr_id do
        expect(f('#tinymce sup')).to be_displayed
      end
    end

    it "should remove superscript from text in rce" do
      skip('Unskip in CORE-2634')
      skip_if_chrome('fragile in chrome')
      text = "<p><sup>This is my text</sup></p>"

      wysiwyg_state_setup(@course, text, html: true)
      shift_click_button(superscript_button)

      in_frame rce_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('sup')
      end
    end

    it "should make text subscript in rce" do
      skip('Unskip in CORE-2634')
      wysiwyg_state_setup(@course)

      click_super_toggle_button
      click_subscript_button

      in_frame rce_page_body_ifr_id do
        expect(f('#tinymce sub')).to be_displayed
      end
    end

    it "should remove subscript from text in rce" do
      skip('Unskip in CORE-2634')
      skip_if_chrome('fragile in chrome')
      text = "<p><sub>This is my text</sub></p>"
      wysiwyg_state_setup(@course, text, html: true)

      click_super_toggle_button
      shift_click_button(subscript_button)

      in_frame rce_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('sub')
      end
    end

    it "should align text to the left" do
      skip('Unskip in CORE-2635')
      wysiwyg_state_setup(@course, text = "left")

      click_align_left_button
      validate_wiki_style_attrib("text-align", text, "p")
    end

    it "should remove left align from text" do
      skip('Unskip in CORE-2635')
      text = "<p style=\"text-align: left;\">1</p>"
      wysiwyg_state_setup(@course, text, html: true)

      click_align_left_button
      validate_wiki_style_attrib_empty("p")
    end

    it "should align text to the center" do
      skip('Unskip in CORE-2635')
      wysiwyg_state_setup(@course, text = "center")

      click_align_toggle_button
      click_align_center_button
      validate_wiki_style_attrib("text-align", text, "p")
    end

    it "should remove center align from text" do
      skip('Unskip in CORE-2635')
      text = "<p style=\"text-align: center;\">1</p>"
      wysiwyg_state_setup(@course, text, html: true)

      click_align_toggle_button
      click_align_center_button
      validate_wiki_style_attrib_empty("p")
    end

    it "should align text to the right" do
      skip('Unskip in CORE-2635')
      wysiwyg_state_setup(@course, text = "right")

      click_align_toggle_button
      click_align_right_button
      validate_wiki_style_attrib("text-align", text, "p")
    end

    it "should remove right align from text" do
      skip('Unskip in CORE-2635')
      text = "<p style=\"text-align: right;\">1</p>"
      wysiwyg_state_setup(@course, text, html: true)

      click_align_toggle_button
      click_align_right_button
      validate_wiki_style_attrib_empty("p")
    end

    it "should change text to right-to-left in the rce" do
      rce_wysiwyg_state_setup(@course, text = "rtl")
      click_directionality_toggle_button
      click_right_to_left_option
      in_frame rce_page_body_ifr_id do
        expect(f('#tinymce p').attribute('dir')).to eq text
      end
    end

    it "should remove right-to-left from text in the rce" do
      skip('Unskip in CORE-3049')
      text = "<p dir=\"rtl\">This is my text</p>"
      wysiwyg_state_setup(@course, text, html: true)
      click_directionality_toggle_button
      click_right_to_left_option
      validate_wiki_style_attrib_empty("p")
    end

    it "should change text to left-to-right in the rce" do
      skip('Unskip in CORE-3049')
      wysiwyg_state_setup(@course, text = "ltr")
      click_directionality_toggle_button
      click_right_to_left_option
      in_frame rce_page_body_ifr_id do
        expect(wiki_page_body).attribute('dir').to eq text
      end
    end

    it "should remove left-to-right from text in the rce" do
      skip('Unskip in CORE-3049')
      text = "<p dir=\"ltr\">This is my text</p>"
      wysiwyg_state_setup(@course, text, html: true)
      click_directionality_button
      validate_wiki_style_attrib_empty("p")
    end

    it "should verify the rce-next toolbar is one row" do
      visit_front_page_edit(@course)

      expect(rce_next_toolbar.size.height).to be 39
    end

    it "should verify selecting Header from dropdown sets H2" do
      page_title = "header"
      create_wiki_page_with_text(page_title)
      visit_existing_wiki_edit(@course, page_title)

      select_all_wiki
      click_formatting_dropdown
      click_header_option

      in_frame tiny_rce_ifr_id do
        expect(wiki_body).to contain_css('h2')
      end
    end

    it "should verify selecting subeader from dropdown sets H3" do
      page_title = "header"
      create_wiki_page_with_text(page_title)
      visit_existing_wiki_edit(@course, page_title)

      select_all_wiki
      click_formatting_dropdown
      click_subheader_option

      in_frame tiny_rce_ifr_id do
        expect(wiki_body).to contain_css('h3')
      end
    end

    it "should verify selecting small header from dropdown sets H4" do
      page_title = "header"
      create_wiki_page_with_text(page_title)
      visit_existing_wiki_edit(@course, page_title)

      select_all_wiki
      click_formatting_dropdown
      click_small_header_option

      in_frame tiny_rce_ifr_id do
        expect(wiki_body).to contain_css('h4')
      end
    end

    it "should verify selecting preformatted from dropdown sets pre" do
      page_title = "header"
      create_wiki_page_with_text(page_title)
      visit_existing_wiki_edit(@course, page_title)

      select_all_wiki
      click_formatting_dropdown
      click_preformatted_option

      in_frame tiny_rce_ifr_id do
        expect(wiki_body).to contain_css('pre')
      end
    end

    describe 'floating toolbar' do
      before(:each) do
        create_wiki_page_with_text('hello')
        visit_existing_wiki_edit(@course, 'hello')
        driver.manage.window.resize_to(1000, 800)
      end

      it "should close on executing any command" do
        more_toolbar_button.click
        expect(overflow_toolbar).to be_displayed
        click_list_toggle_button
        click_bullet_list_button
        expect(f('body')).not_to contain_css(overflow_toolbar_selector)
      end

      it "should close on losing focus" do
        skip("Adding this test causes the previous one to fail. Go figure!?!")
        in_frame rce_page_body_ifr_id do
          f('#tinymce').send_keys('') # focus
        end
        more_toolbar_button.click
        wait_for_animations
        expect(overflow_toolbar).to be_displayed
        f('#title').click
        expect(f('body')).not_to contain_css(overflow_toolbar_selector)
      end


    end
  end
end
