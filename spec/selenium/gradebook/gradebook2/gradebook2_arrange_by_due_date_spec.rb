require_relative '../../helpers/gradebook2_common'
require_relative '../../helpers/assignment_overrides'

describe "gradebook2 - arrange by due date" do
  include_context "in-process server selenium tests"
  include AssignmentOverridesSeleniumHelper
  include Gradebook2Common

  before(:each) do
    gradebook_data_setup
    @assignment = @course.assignments.first
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
  end

  it "should validate arrange columns by due date option", priority: "1", test_id: 220027 do
    expected_text = "-"
    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings(arrange_settings.first.find_element(:xpath, '..'))
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], expected_text)
    open_gradebook_settings()
    expect(arrange_settings.first.find_element(:xpath, '..')).not_to be_displayed
    expect(arrange_settings.last.find_element(:xpath, '..')).to be_displayed

    # Setting should stick after reload
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], expected_text)

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], expected_text)
    validate_cell_text(first_row_cells[1], @assignment_1_points)
    validate_cell_text(first_row_cells[2], @assignment_2_points)

    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings()
    expect(arrange_settings.first.find_element(:xpath, '..')).not_to be_displayed
    expect(arrange_settings.last.find_element(:xpath, '..')).to be_displayed
  end

  it "should put assignments with no due date last when sorting by due date and VDD", priority: "2", test_id: 251038 do
    assignment2 = @course.assignments.where(title: 'second assignment').first
    assignment3 = @course.assignments.where(title: 'assignment three').first
    # create 1 section
    @section_a = @course.course_sections.create!(name: 'Section A')
    # give second assignment a default due date and an override
    assignment2.update_attribute(:due_at, 3.days.from_now)
    create_assignment_override(assignment2, @section_a, 2)

    fj('#gradebook_settings').click
    fj("a[data-arrange-columns-by='due_date']").click
    # since due date changes in assignments don't reflect in column sorting without a refresh
    get "/courses/#{@course.id}/gradebook2"
    expect(fj('#gradebook_grid .container_1 .slick-header-sortable:nth-child(1)')).to include_text(assignment3.title)
    expect(fj('#gradebook_grid .container_1 .slick-header-sortable:nth-child(2)')).to include_text(assignment2.title)
    expect(fj('#gradebook_grid .container_1 .slick-header-sortable:nth-child(3)')).to include_text(@assignment.title)
  end

  it "should arrange columns by due date when multiple due dates are present", priority: "2", test_id: 378823 do
    assignment3 = @course.assignments.where(title: 'assignment three').first
    # create 2 sections
    @section_a = @course.course_sections.create!(name: 'Section A')
    @section_b = @course.course_sections.create!(name: 'Section B')
    # give each assignment a default due date
    @assignment.update_attribute(:due_at, 3.days.from_now)
    assignment3.update_attribute(:due_at, 2.days.from_now)
    # creating overrides in each section
    create_assignment_override(@assignment, @section_a, 5)
    create_assignment_override(assignment3, @section_b, 4)

    fj('#gradebook_settings').click
    fj("a[data-arrange-columns-by='due_date']").click
    expect(fj('#gradebook_grid .container_1 .slick-header-sortable:nth-child(1)')).to include_text(assignment3.title)
    expect(fj('#gradebook_grid .container_1 .slick-header-sortable:nth-child(2)')).to include_text(@assignment.title)
  end
end