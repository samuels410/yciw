define [
  'underscore',
  'react',
  'jsx/epub_exports/CourseList'
], (_, React, CourseList, I18n) ->
  TestUtils = React.addons.TestUtils

  module 'CourseListSpec',
    setup: ->
      @props = {
        1: {
          name: 'Maths 101',
          id: 1
        },
        2: {
          name: 'Physics 101',
          id: 2
        }
      }

  test 'render', ->
    CourseListElement = React.createElement(CourseList, courses: {})
    component = TestUtils.renderIntoDocument(CourseListElement)
    node = component.getDOMNode()
    equal node.querySelectorAll('li').length, 0, 'should not render list items'
    React.unmountComponentAtNode(node.parentNode)

    CourseListElement = React.createElement(CourseList, courses: @props)
    component = TestUtils.renderIntoDocument(CourseListElement)
    node = component.getDOMNode()
    equal node.querySelectorAll('li').length, Object.keys(@props).length,
      'should have an li element per course in @props'

    React.unmountComponentAtNode(node.parentNode)
