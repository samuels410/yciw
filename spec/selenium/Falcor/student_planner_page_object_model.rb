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

module PlannerPageObject

  def click_dashboard_settings
    expect(f('#DashboardOptionsMenu_Container')).to be_displayed # Ensure the page is loaded and the element is visible
    f('#DashboardOptionsMenu_Container').click
  end

  def select_list_view
    driver.find_element(:xpath, "//span[text()[contains(.,'List View')]]").click
  end

  def navigate_to_course_object(object)
    expect_new_page_load do
      fln(object.title.to_s).click
    end
  end

  def validate_url(object_type, object)
    url = driver.current_url
    domain = url.split('courses')[0]
    expected_url = domain + "courses/#{@course.id}/#{object_type}/#{object.id}"
    expected_url = domain + "courses/#{@course.id}/#{object_type}/#{object.title.downcase}" if object_type == 'pages'
    expect(url).to eq(expected_url)
  end

  def validate_object_displayed(object_type)  # Pass what type of object it is. Ensure object's name starts with a capital letter
    expect(f('.PlannerApp').find_element(:xpath, "//span[text()[contains(.,'Unnamed Course #{object_type}')]]")).
      to be_displayed
  end

  def validate_no_due_dates_assigned
    expect(f('#dashboard-planner').find_element(:xpath, "//h2[text()[contains(.,'No Due Dates Assigned')]]")).
      to be_displayed
    expect(f('#dashboard-planner').find_element(:xpath, "//div[text()[contains(.,\"Looks like there isn't anything here\")]]")).
      to be_displayed
  end

  def go_to_dashcard_view
    fj("button:contains('Go to Dashboard Card View')").click
  end

  def expand_completed_item
    f('.PlannerApp').find_element(:xpath, "//span[text()[contains(.,'Show 1 completed item')]]").click
  end

  def validate_pill(pill_type)
    expect(f('.PlannerApp').find_element(:xpath, "//span[text()[contains(.,'#{pill_type}')]]")).to be_displayed
  end

  def go_to_list_view
    get '/'
    click_dashboard_settings
    select_list_view
    wait_for_planner_load
  end

  def validate_link_to_url(object, url_type) # should pass the type of object as a string
    navigate_to_course_object(object)
    validate_url(url_type, object)
  end

  def open_opportunities_dropdown
    fj("button:contains('opportunit')").click
  end

  def close_opportunities_dropdown
    fj("button[title='Close opportunities popover']").click
  end

  def todo_modal_button
    fj("button:contains('Add To Do')")
  end

  def wait_for_planner_load
    wait_for_dom_ready
    wait_for_ajaximations
    todo_modal_button
  end

  def todo_save_button
    fj("button:contains('Save')")
  end

  def todo_details
    f('textarea')
  end

  def todo_sidebar_modal
    f("div[aria-label = 'Add To Do']")
  end

  def wait_for_spinner
    fj("title:contains('Loading')", f('.PlannerApp')) # the loading spinner appears
    expect(f('.PlannerApp')).not_to contain_css('title') # and disappears
  end

  def items_displayed
    ff('li', f('.PlannerApp'))
  end

  def todo_info_holder
    f('ol')
  end

  def create_new_todo
    modal = todo_sidebar_modal
    element = f('input', modal)
    element.send_keys("Title Text")
    todo_save_button.click
  end
end
