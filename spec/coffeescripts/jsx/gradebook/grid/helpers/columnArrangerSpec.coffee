define [
  'jsx/gradebook/grid/helpers/columnArranger',
  'underscore'
], (ColumnArranger, _) ->

  module 'columnArranger#getComparator',
    setup: ->
    teardown: ->

  test 'returns the correct function when passed "due_date"', ->
    expectedFn = ColumnArranger.compareByDueDate
    returnedFn = ColumnArranger.getComparator('due_date')
    propEqual returnedFn, expectedFn

  test 'returns the correct function when passed "assignment_group"', ->
    expectedFn = ColumnArranger.compareByAssignmentGroup
    returnedFn = ColumnArranger.getComparator('assignment_group')
    propEqual returnedFn, expectedFn

  module 'columnArranger#compareByDueDate',
    setup: ->
    teardown: ->

  generateAssignment = (options) ->
    options = options || {}
    _.defaults(options, { name: 'assignment', due_at: new Date('Mon May 11 2015') })

  generateOverrides = ->
    [
      { title: 'section 1', due_at: new Date('Mon May 11 2015') },
      { title: 'section 2', due_at: new Date('Tue May 12 2015') }
    ]

  test 'compares assignments by due date', ->
    assignment1 = generateAssignment()
    assignment2 = generateAssignment({ due_at: new Date('Tue May 12 2015') })
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal < 0

    assignment1.due_at = new Date('Wed May 13 2015')
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

  test 'treats null values as "greater" than Date values', ->
    assignment1 = generateAssignment({ due_at: null })
    assignment2 = generateAssignment()
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

  test 'compares by name if dates are the same', ->
    assignment1 = generateAssignment({ name: 'Banana' })
    assignment2 = generateAssignment({ name: 'Apple' })
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

    assignment2.name = 'Carrot'
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal < 0

  test 'ignores case when comparing by name', ->
    assignment1 = generateAssignment({ name: 'Banana' })
    assignment2 = generateAssignment({ name: 'apple' })
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

    assignment2.name = 'Apple'
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

  test 'compares by due date overrides if dates are both null', ->
    assignment1 = generateAssignment({ due_at: null, has_overrides: true })
    assignment1.overrides = generateOverrides()
    assignment2 = generateAssignment({ due_at: null, has_overrides: false })
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal < 0

  test 'hasMultipleDueDates returns false when provided an empty object', ->
    assignment = {}
    notOk ColumnArranger.hasMultipleDueDates(assignment)

  test 'hasMultipleDueDates returns false when provided just has_overrides', ->
    assignment = { has_overrides: true }
    notOk ColumnArranger.hasMultipleDueDates(assignment)

  test 'hasMultipleDueDates returns false when provided an empty overrides', ->
    assignment = { has_overrides: true, overrides: [] }
    notOk ColumnArranger.hasMultipleDueDates(assignment)

  test 'hasMultipleDueDates returns false when provided overrides with a length of 1', ->
    assignment = { has_overrides: true, overrides: [{ title: 'section 1' }] }
    notOk ColumnArranger.hasMultipleDueDates(assignment)

  test 'hasMultipleDueDates returns true when provided overrides with a length greater than 1', ->
    overrides = [{ title: 'section 1' }, { title: 'section 2' }]
    assignment = { has_overrides: true, overrides: overrides }
    ok ColumnArranger.hasMultipleDueDates(assignment)

  test 'treats assignments with a single override with a null date as' +
  '"greater" than assignments with multiple overrides', ->
    assignment1 = generateAssignment({ due_at: null, has_overrides: true })
    assignment1.overrides = [
      { title: 'section 1', due_at: null }
    ]
    assignment2 = generateAssignment({ due_at: null, has_overrides: true })
    assignment2.overrides = [
      { title: 'section 1', due_at: null },
      { title: 'section 2', due_at: null }
    ]
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

  test 'compares by name if dates are both null and both have multiple overrides', ->
    assignment1 = { name: 'Banana', due_at: null, has_overrides: true }
    assignment1.overrides = generateOverrides()
    assignment2 = { name: 'Apple', due_at: null, has_overrides: true }
    assignment2.overrides = generateOverrides()
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

    assignment2.name = 'Carrot'
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal < 0

  test 'compares by name if dates are both null and neither have due date overrides', ->
    assignment1 = { name: 'Banana', due_at: null, has_overrides: false }
    assignment2 = { name: 'Apple', due_at: null, has_overrides: false }
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

    assignment2.name = 'Carrot'
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal < 0

  test 'treats assignments with the same dates and names as equal', ->
    assignment1 = generateAssignment()
    assignment2 = generateAssignment()
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal == 0

  test 'handles one due_at passed in as string and another passed in as date', ->
    assignment1 = generateAssignment()
    assignment2 = generateAssignment({ due_at: '2015-05-20T06:59:00Z' })
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal < 0

    assignment2.due_at = '2015-05-05T06:59:00Z'
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

  test 'handles both due_ats passed in as strings', ->
    assignment1 = generateAssignment({ due_at: '2015-05-11T06:59:00Z' })
    assignment2 = generateAssignment({ due_at: '2015-05-20T06:59:00Z' })
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal < 0

    assignment2.due_at = '2015-05-05T06:59:00Z'
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

  test 'handles an override and an assignment due_ats passed in as strings', ->
    assignment1 = generateAssignment({ due_at: null, has_overrides: true })
    assignment1.overrides = [{ title: 'section 1', due_at: '2015-05-05T06:59:00Z' }]
    assignment2 = generateAssignment({ due_at: '2015-05-11T06:59:00Z' })
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal < 0

    assignment2.due_at = '2015-04-05T06:59:00Z'
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

  test 'handles two assignments each with only a single override, and override due_ats passed in as strings', ->
    assignment1 = generateAssignment({ due_at: null, has_overrides: true })
    assignment1.overrides = [{ title: 'section 1', due_at: '2015-05-05T06:59:00Z' }]
    assignment2 = generateAssignment({ due_at: null, has_overrides: true })
    assignment2.overrides = [{ title: 'section 2', due_at: '2015-05-10T06:59:00Z' }]
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal < 0

    assignment2.overrides[0].due_at = '2015-04-05T06:59:00Z'
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal > 0

  test 'handles assignments with "has_overrides" set to true but without an overrides array', ->
    assignment1 = generateAssignment({ due_at: null, has_overrides: true })
    assignment1.overrides = null
    assignment2 = generateAssignment({ due_at: null, has_overrides: false })
    comparisonVal = ColumnArranger.compareByDueDate(assignment1, assignment2)
    ok comparisonVal == 0

  module 'columnArranger#compareByAssignmentGroup',
    setup: ->
    teardown: ->

  test 'compares assignments by their assignment group position', ->
    assignment1 = { assignment_group_position: 1, position: 1 }
    assignment2 = { assignment_group_position: 2, position: 1 }
    comparisonVal = ColumnArranger.compareByAssignmentGroup(assignment1, assignment2)
    ok comparisonVal < 0

    assignment1.assignment_group_position = 3
    comparisonVal = ColumnArranger.compareByAssignmentGroup(assignment1, assignment2)
    ok comparisonVal > 0

  test 'compares by assignment position if assignment group position is the same', ->
    assignment1 = { assignment_group_position: 1, position: 2 }
    assignment2 = { assignment_group_position: 1, position: 1 }
    comparisonVal = ColumnArranger.compareByAssignmentGroup(assignment1, assignment2)
    ok comparisonVal > 0

    assignment2.position = 3
    comparisonVal = ColumnArranger.compareByAssignmentGroup(assignment1, assignment2)
    ok comparisonVal < 0

  test 'treats assignments with the same position and group position as equal', ->
    assignment1 = { assignment_group_position: 1, position: 1 }
    assignment2 = { assignment_group_position: 1, position: 1 }
    comparisonVal = ColumnArranger.compareByAssignmentGroup(assignment1, assignment2)
    ok comparisonVal == 0
