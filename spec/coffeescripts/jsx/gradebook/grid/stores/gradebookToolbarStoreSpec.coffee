define [
  'jsx/gradebook/grid/stores/gradebookToolbarStore'
  'underscore'
  'helpers/fakeENV'
  'compiled/userSettings'
], (GradebookToolbarStore, _, fakeENV, userSettings) ->

  module 'ReactGradebook.gradebookToolbarStore',
    setup: ->
      env = {
        GRADEBOOK_OPTIONS: {}
      }
      fakeENV.setup(env)
      @defaultOptions =
        hideStudentNames: false
        hideNotesColumn: true
        treatUngradedAsZero: false
        arrangeColumnsBy: 'assignment_group'
        totalColumnInFront: false
        warnedAboutTotalsDisplay: false
        showTotalGradeAsPoints: false
    teardown: ->
      fakeENV.teardown()
      GradebookToolbarStore.toolbarOptions = undefined

  test '#getInitialState returns default options if the user does not have saved preferences', ->
    initialState = GradebookToolbarStore.getInitialState()
    propEqual(initialState, @defaultOptions)

  test '#getInitialState returns the saved preferences of the user, otherwise it returns defaults', ->
    userSettings.contextSet('hideStudentNames', true)
    userSettings.contextSet('treatUngradedAsZero', true)
    expectedState = _.defaults(
      { hideStudentNames: true, treatUngradedAsZero: true }
      @defaultOptions)
    initialState = GradebookToolbarStore.getInitialState()

    propEqual(initialState, expectedState)
    userSettings.contextRemove('hideStudentNames')
    userSettings.contextRemove('treatUngradedAsZero')

  test '#onToggleStudentNames should set toolbarOptions.hideStudentNames and trigger a setState', ->
    triggerMock = @mock(GradebookToolbarStore)
    triggerExpectation = triggerMock.expects('trigger').once()
    GradebookToolbarStore.getInitialState()
    GradebookToolbarStore.onToggleStudentNames(true)

    deepEqual GradebookToolbarStore.toolbarOptions.hideStudentNames, true
    ok(triggerExpectation.once())

  test '#onToggleNotesColumn should set toolbarOptions.hideNotesColumn and trigger a setState', ->
    triggerMock = @mock(GradebookToolbarStore)
    triggerExpectation = triggerMock.expects('trigger').once()
    GradebookToolbarStore.getInitialState()
    GradebookToolbarStore.onToggleNotesColumn(false)

    deepEqual GradebookToolbarStore.toolbarOptions.hideNotesColumn, false
    ok(triggerExpectation.once())

  test '#onArrangeColumnsBy should set toolbarOptions.arrangeColumnsBy and trigger a setState', ->
    triggerMock = @mock(GradebookToolbarStore)
    triggerExpectation = triggerMock.expects('trigger').once()
    GradebookToolbarStore.getInitialState()
    GradebookToolbarStore.onArrangeColumnsBy('due_date')

    deepEqual GradebookToolbarStore.toolbarOptions.arrangeColumnsBy, 'due_date'
    ok(triggerExpectation.once())

  test '#onToggleTreatUngradedAsZero should set toolbarOptions.treatUngradedAsZero and trigger a setState', ->
    triggerMock = @mock(GradebookToolbarStore)
    triggerExpectation = triggerMock.expects('trigger').once()
    GradebookToolbarStore.getInitialState()
    GradebookToolbarStore.onToggleTreatUngradedAsZero(true)

    deepEqual GradebookToolbarStore.toolbarOptions.treatUngradedAsZero, true
    ok(triggerExpectation.once())

  test '#onShowTotalGradeAsPoints should set toolbarOptions.showTotalGradeAsPoints and trigger a setState', ->
    triggerMock = @mock(GradebookToolbarStore)
    triggerExpectation = triggerMock.expects('trigger').once()
    GradebookToolbarStore.getInitialState()
    GradebookToolbarStore.onShowTotalGradeAsPoints(true)

    deepEqual GradebookToolbarStore.toolbarOptions.showTotalGradeAsPoints, true
    ok(triggerExpectation.once())

  test '#onHideTotalDisplayWarning should set toolbarOptions.warnedAboutTotalsDisplay and trigger a setState', ->
    triggerMock = @mock(GradebookToolbarStore)
    triggerExpectation = triggerMock.expects('trigger').once()
    GradebookToolbarStore.getInitialState()
    GradebookToolbarStore.onHideTotalDisplayWarning(true)

    deepEqual GradebookToolbarStore.toolbarOptions.warnedAboutTotalsDisplay, true
    ok(triggerExpectation.once())
