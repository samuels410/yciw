require_relative '../../helpers/gradebook2_common'
require_relative '../../helpers/assignment_overrides'

describe "gradebook2 - arrange by assignment group" do
  include_context "in-process server selenium tests"
  include AssignmentOverridesSeleniumHelper
  include Gradebook2Common

  before(:each) do
    gradebook_data_setup
    @assignment = @course.assignments.first
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
  end

  it "should default to arrange columns by assignment group", priority: "1", test_id: 220028 do
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], @assignment_1_points)
    validate_cell_text(first_row_cells[1], @assignment_2_points)
    validate_cell_text(first_row_cells[2], "-")

    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings()
    expect(arrange_settings.first.find_element(:xpath, '..')).to be_displayed
    expect(arrange_settings.last.find_element(:xpath, '..')).not_to be_displayed
  end

  it "should validate arrange columns by assignment group option", priority: "1", test_id: 220029 do
    # since assignment group is the default, sort by due date, then assignment group again
    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings(arrange_settings.first.find_element(:xpath, '..'))
    open_gradebook_settings(arrange_settings.last.find_element(:xpath, '..'))
    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], @assignment_1_points)
    validate_cell_text(first_row_cells[1], @assignment_2_points)
    validate_cell_text(first_row_cells[2], "-")

    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings()
    expect(arrange_settings.first.find_element(:xpath, '..')).to be_displayed
    expect(arrange_settings.last.find_element(:xpath, '..')).not_to be_displayed

    # Setting should stick (not be messed up) after reload
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    first_row_cells = find_slick_cells(0, f('#gradebook_grid .container_1'))
    validate_cell_text(first_row_cells[0], @assignment_1_points)
    validate_cell_text(first_row_cells[1], @assignment_2_points)
    validate_cell_text(first_row_cells[2], "-")

    arrange_settings = ff('input[name="arrange-columns-by"]')
    open_gradebook_settings()
    expect(arrange_settings.first.find_element(:xpath, '..')).to be_displayed
    expect(arrange_settings.last.find_element(:xpath, '..')).not_to be_displayed
  end
end