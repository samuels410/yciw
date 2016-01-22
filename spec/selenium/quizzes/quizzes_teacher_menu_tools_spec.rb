require_relative '../common'
require_relative '../helpers/quizzes_common'
require_relative '../helpers/assignment_overrides'

describe 'quizzes' do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include AssignmentOverridesSeleniumHelper

  before(:each) do
    course_with_teacher_logged_in
    @course.update_attributes(name: 'teacher course')
    @course.save!
    @course.reload
    course_with_teacher_logged_in
    Account.default.enable_feature!(:lor_for_account)

    @tool = Account.default.context_external_tools.new(
      name: 'a',
      domain: 'google.com',
      consumer_key: '12345',
      shared_secret: 'secret'
    )
    @tool.quiz_menu = {url: 'http://www.example.com', text: 'Export Quiz'}
    @tool.save!

    @quiz = @course.quizzes.create!(title: 'score 10')
  end

  it 'shows tool launch links in the gear for items on the index', priority: "1", test_id: 209942 do
    get "/courses/#{@course.id}/quizzes"
    wait_for_ajaximations

    # click gear icon
    f("#summary_quiz_#{@quiz.id} .al-trigger").click

    link = f("#summary_quiz_#{@quiz.id} li a.menu_tool_link")
    expect(link).to be_displayed
    expect(link.text).to match_ignoring_whitespace(@tool.label_for(:quiz_menu))
    assert_url_parse_match(link['href'], "#{course_external_tool_url(@course, @tool)}?launch_type=quiz_menu&quizzes[]=#{@quiz.id}")
  end

  it 'shows tool launch links in the gear for items on the show page', priority: "1", test_id: 209943 do
    get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
    wait_for_ajaximations

    # click gear icon
    f('#quiz_show .al-trigger').click

    link = f('#quiz_show li a.menu_tool_link')
    expect(link).to be_displayed
    expect(link.text).to match_ignoring_whitespace(@tool.label_for(:quiz_menu))
    assert_url_parse_match(link['href'], "#{course_external_tool_url(@course, @tool)}?launch_type=quiz_menu&quizzes[]=#{@quiz.id}")
  end
end
