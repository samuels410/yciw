#
# Copyright (C) 2011 - present Instructure, Inc.
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
#

define [
  'jquery'
  'underscore'
  'Backbone'
  'timezone'
  'jsx/gradezilla/DataLoader'
  'react'
  'react-dom'
  'slickgrid.long_text_editor'
  'compiled/views/KeyboardNavDialog'
  'jst/KeyboardNavDialog'
  'vendor/slickgrid'
  'compiled/api/gradingPeriodsApi'
  'compiled/api/gradingPeriodSetsApi'
  'compiled/views/InputFilterView'
  'i18nObj'
  'i18n!gradezilla'
  'compiled/gradezilla/GradebookTranslations'
  'jsx/gradebook/CourseGradeCalculator'
  'jsx/gradebook/EffectiveDueDates'
  'jsx/gradebook/shared/helpers/GradeFormatHelper'
  'compiled/userSettings'
  'spin.js'
  'compiled/AssignmentMuter'
  'compiled/shared/GradeDisplayWarningDialog'
  'compiled/gradezilla/PostGradesFrameDialog'
  'compiled/util/NumberCompare'
  'compiled/util/natcompare'
  'convert_case'
  'str/htmlEscape'
  'jsx/gradezilla/shared/SetDefaultGradeDialogManager'
  'jsx/gradezilla/default_gradebook/CurveGradesDialogManager'
  'jsx/gradezilla/default_gradebook/apis/GradebookApi'
  'jsx/gradezilla/default_gradebook/slick-grid/CellEditorFactory'
  'jsx/gradezilla/default_gradebook/slick-grid/CellFormatterFactory'
  'jsx/gradezilla/default_gradebook/slick-grid/ColumnHeaderRenderer'
  'jsx/gradezilla/default_gradebook/slick-grid/grid-support'
  'jsx/gradezilla/default_gradebook/constants/studentRowHeaderConstants'
  'jsx/gradezilla/default_gradebook/components/AssignmentRowCellPropFactory'
  'jsx/gradezilla/default_gradebook/components/GradebookMenu'
  'jsx/gradezilla/default_gradebook/components/ViewOptionsMenu'
  'jsx/gradezilla/default_gradebook/components/ActionMenu'
  'jsx/gradezilla/default_gradebook/components/AssignmentGroupFilter'
  'jsx/gradezilla/default_gradebook/components/GradingPeriodFilter'
  'jsx/gradezilla/default_gradebook/components/ModuleFilter'
  'jsx/gradezilla/default_gradebook/components/SectionFilter'
  'jsx/gradezilla/default_gradebook/components/GridColor'
  'jsx/gradezilla/default_gradebook/components/StatusesModal'
  'jsx/gradezilla/default_gradebook/components/SubmissionTray'
  'jsx/gradezilla/default_gradebook/components/GradebookSettingsModal'
  'jsx/gradezilla/default_gradebook/constants/colors'
  'jsx/gradezilla/default_gradebook/stores/StudentDatastore'
  'jsx/gradezilla/SISGradePassback/PostGradesStore'
  'jsx/gradezilla/SISGradePassback/PostGradesApp'
  'jsx/gradezilla/SubmissionStateMap'
  'jsx/gradezilla/shared/DownloadSubmissionsDialogManager'
  'jsx/gradezilla/shared/ReuploadSubmissionsDialogManager'
  'compiled/gradezilla/GradebookKeyboardNav'
  'jsx/gradezilla/shared/AssignmentMuterDialogManager'
  'jsx/gradezilla/shared/helpers/assignmentHelper'
  'jsx/gradezilla/shared/helpers/TextMeasure'
  'jsx/grading/LatePolicyApplicator'
  'instructure-ui/lib/components/Button'
  'instructure-icons/lib/Solid/IconSettingsSolid'
  'jquery.ajaxJSON'
  'jquery.instructure_date_and_time'
  'jqueryui/dialog'
  'jqueryui/tooltip'
  'compiled/behaviors/tooltip'
  'compiled/behaviors/activate'
  'jquery.instructure_misc_helpers'
  'jquery.instructure_misc_plugins'
  'vendor/jquery.ba-tinypubsub'
  'jqueryui/position'
  'jqueryui/sortable'
  'compiled/jquery.kylemenu'
  'compiled/jquery/fixDialogButtons'
  'jsx/context_cards/StudentContextCardTrigger'
], ($, _, Backbone, tz, DataLoader, React, ReactDOM, LongTextEditor, KeyboardNavDialog, KeyboardNavTemplate, Slick,
  GradingPeriodsApi, GradingPeriodSetsApi, InputFilterView, i18nObj, I18n, GRADEBOOK_TRANSLATIONS,
  CourseGradeCalculator, EffectiveDueDates, GradeFormatHelper, UserSettings, Spinner, AssignmentMuter,
  GradeDisplayWarningDialog, PostGradesFrameDialog,
  NumberCompare, natcompare, ConvertCase, htmlEscape, SetDefaultGradeDialogManager,
  CurveGradesDialogManager, GradebookApi, CellEditorFactory, CellFormatterFactory, ColumnHeaderRenderer, GridSupport,
  studentRowHeaderConstants, AssignmentRowCellPropFactory,
  GradebookMenu, ViewOptionsMenu, ActionMenu, AssignmentGroupFilter, GradingPeriodFilter, ModuleFilter, SectionFilter,
  GridColor, StatusesModal, SubmissionTray, GradebookSettingsModal, { statusColors }, StudentDatastore, PostGradesStore, PostGradesApp,
  SubmissionStateMap,
  DownloadSubmissionsDialogManager,ReuploadSubmissionsDialogManager, GradebookKeyboardNav,
  AssignmentMuterDialogManager, assignmentHelper, TextMeasure, LatePolicyApplicator, { default: Button }, { default: IconSettingsSolid }) ->

  isAdmin = =>
    _.contains(ENV.current_user_roles, 'admin')

  IS_ADMIN = isAdmin()

  htmlDecode = (input) ->
    input && new DOMParser().parseFromString(input, "text/html").documentElement.textContent

  testWidth = (text, minWidth, maxWidth) ->
    width = Math.max(TextMeasure.getWidth(text), minWidth)
    Math.min width, maxWidth

  renderComponent = (reactClass, mountPoint, props = {}, children = null) ->
    component = React.createElement(reactClass, props, children)
    ReactDOM.render(component, mountPoint)

  getAssignmentGroupPointsPossible = (assignmentGroup) ->
    assignmentGroup.assignments.reduce(
      (sum, assignment) -> sum + (assignment.points_possible || 0),
      0
    )

  ASSIGNMENT_KEY_REGEX = /^assignment_(?!group)/
  forEachSubmission = (students, fn) ->
    Object.keys(students).forEach (studentIdx) =>
      student = students[studentIdx]
      Object.keys(student).forEach (key) =>
        if key.match ASSIGNMENT_KEY_REGEX
          fn(student[key])

  ## Gradebook Display Settings
  getInitialGridDisplaySettings = (settings, colors) ->
    selectedPrimaryInfo = if studentRowHeaderConstants.primaryInfoKeys.includes(settings.student_column_display_as)
      settings.student_column_display_as
    else
      studentRowHeaderConstants.defaultPrimaryInfo

    # in case of no user preference, determine the default value after @hasSections has resolved
    selectedSecondaryInfo = settings.student_column_secondary_info

    sortRowsByColumnId = settings.sort_rows_by_column_id || 'student'
    sortRowsBySettingKey = settings.sort_rows_by_setting_key || 'sortable_name'
    sortRowsByDirection = settings.sort_rows_by_direction || 'ascending'

    filterColumnsBy =
      assignmentGroupId: null
      contextModuleId: null
      gradingPeriodId: null

    if settings.filter_columns_by?
      Object.assign(filterColumnsBy, ConvertCase.camelize(settings.filter_columns_by))

    filterRowsBy =
      sectionId: null

    if settings.filter_rows_by?
      Object.assign(filterRowsBy, ConvertCase.camelize(settings.filter_rows_by))

    {
      colors
      filterColumnsBy
      filterRowsBy
      selectedPrimaryInfo
      selectedSecondaryInfo
      sortRowsBy:
        columnId: sortRowsByColumnId # the column controlling the sort
        settingKey: sortRowsBySettingKey # the key describing the sort criteria
        direction: sortRowsByDirection # the direction of the sort
      selectedViewOptionsFilters: settings.selected_view_options_filters || []
      showEnrollments:
        concluded: false
        inactive: false
      showUnpublishedDisplayed: false
      submissionTray:
        open: false
        studentId: null
        assignmentId: null
    }

  ## Gradebook Application State
  getInitialContentLoadStates = ->
    {
      assignmentsLoaded: false
      contextModulesLoaded: false
      studentsLoaded: false
      submissionsLoaded: false
      teacherNotesColumnUpdating: false
      submissionUpdating: false
    }

  getInitialCourseContent = (options) ->
    {
      contextModules: []
      gradingPeriodAssignments: {}
      assignmentStudentVisibility: {}
      latePolicy: ConvertCase.camelize(options.late_policy) if options.late_policy
    }

  getInitialGradebookContent = (options) ->
    {
      customColumns: if options.teacher_notes then [options.teacher_notes] else []
    }

  class Gradebook
    columnWidths =
      assignment:
        min: 10
        default_max: 200
        max: 400
      assignmentGroup:
        min: 35
        default_max: 200
        max: 400
      total:
        min: 95
        max: 110

    hasSections: $.Deferred()
    gridReady: $.Deferred()

    constructor: (@options) ->
      $.subscribe 'assignment_muting_toggled',        @handleAssignmentMutingChange
      $.subscribe 'submissions_updated',              @updateSubmissionsFromExternal

      # emitted by SectionMenuView; also subscribed in OutcomeGradebookView
      $.subscribe 'currentSection/change',            @updateCurrentSection

      # emitted by GradingPeriodMenuView
      $.subscribe 'currentGradingPeriod/change',      @updateCurrentGradingPeriod

      @setInitialState()
      @loadSettings()

    # End of constructor

    setInitialState: =>
      @courseContent = getInitialCourseContent(@options)
      @gradebookContent = getInitialGradebookContent(@options)
      @gridDisplaySettings = getInitialGridDisplaySettings(@options.settings, @options.colors)
      @contentLoadStates = getInitialContentLoadStates()
      @headerComponentRefs = {}
      @filteredContentInfo =
        invalidAssignmentGroups: []
        mutedAssignments: []
        totalPointsPossible: 0

      @setAssignments({})
      @setAssignmentGroups({})
      @effectiveDueDates = {}

      @students = {}
      @studentViewStudents = {}
      @courseContent.students = new StudentDatastore(@students, @studentViewStudents)

      @gradebookGrid = {
        columns: {
          definitions: {}
          frozen: []
          scrollable: []
        }
      }
      @rows = []

      @initPostGradesStore()
      @initPostGradesLtis()
      @checkForUploadComplete()

    loadSettings: ->
      if @options.grading_period_set
        @gradingPeriodSet = GradingPeriodSetsApi.deserializeSet(@options.grading_period_set)
      else
        @gradingPeriodSet = null
      @assignmentsToHide = UserSettings.contextGet('hidden_columns') || []
      @show_attendance = !!UserSettings.contextGet 'show_attendance'
      @include_ungraded_assignments = UserSettings.contextGet 'include_ungraded_assignments'
      # preferences serialization causes these to always come
      # from the database as strings
      if @options.course_is_concluded || @options.settings.show_concluded_enrollments == 'true'
        @toggleEnrollmentFilter('concluded', true)
      if @options.settings.show_inactive_enrollments == 'true'
        @toggleEnrollmentFilter('inactive', true)
      @initShowUnpublishedAssignments(@options.settings.show_unpublished_assignments)
      @initSubmissionStateMap()
      @gradebookColumnSizeSettings = @options.gradebook_column_size_settings
      @gradebookColumnOrderSettings = @options.gradebook_column_order_settings
      @teacherNotesNotYetLoaded = !@getTeacherNotesColumn()? || @getTeacherNotesColumn().hidden

      @gotSections(@options.sections)
      @hasSections.then () =>
        if !@getSelectedSecondaryInfo()
          if @sections_enabled
            @gridDisplaySettings.selectedSecondaryInfo = 'section'
          else
            @gridDisplaySettings.selectedSecondaryInfo = 'none'

    initialize: ->
      @setStudentsLoaded(false)
      @setSubmissionsLoaded(false)

      dataLoader = DataLoader.loadGradebookData(
        courseId: @options.context_id
        perPage: @options.api_max_per_page
        assignmentGroupsURL: @options.assignment_groups_url
        assignmentGroupsParams:
          exclude_response_fields: @fieldsToExcludeFromAssignments
          include: @fieldsToIncludeWithAssignments
        contextModulesURL: @options.context_modules_url
        customColumnsURL: @options.custom_columns_url
        getGradingPeriodAssignments: @gradingPeriodSet?

        sectionsURL: @options.sections_url

        studentsURL: @options.students_stateless_url
        studentsPageCb: @gotChunkOfStudents
        studentsParams: @studentsParams()
        loadedStudentIds: []

        submissionsURL: @options.submissions_url
        submissionsChunkCb: @gotSubmissionsChunk
        submissionsChunkSize: @options.chunk_size
        customColumnDataURL: @options.custom_column_data_url
        customColumnDataPageCb: @gotCustomColumnDataChunk
        customColumnDataParams:
          include_hidden: true
      )

      dataLoader.gotStudentIds.then (response) =>
        @courseContent.students.setStudentIds(response.user_ids)
        @buildRows()

      dataLoader.gotGradingPeriodAssignments?.then (response) =>
        @courseContent.gradingPeriodAssignments = response.grading_period_assignments

      dataLoader.gotAssignmentGroups.then @gotAllAssignmentGroups
      dataLoader.gotCustomColumns.then @gotCustomColumns
      dataLoader.gotStudents.then @gotAllStudents

      @renderedGrid = $.when(
        dataLoader.gotStudentIds,
        dataLoader.gotCustomColumns,
        dataLoader.gotAssignmentGroups,
        dataLoader.gotGradingPeriodAssignments
      ).then(@doSlickgridStuff)

      dataLoader.gotStudents.then () =>
        @setStudentsLoaded(true)
        @updateColumnHeaders()
        @renderFilters()

      dataLoader.gotAssignmentGroups.then () =>
        @contentLoadStates.assignmentsLoaded = true
        @renderViewOptionsMenu()
        @updateColumnHeaders()

      dataLoader.gotContextModules.then (contextModules) =>
        @setContextModules(contextModules)
        @contentLoadStates.contextModulesLoaded = true
        @renderViewOptionsMenu()
        @renderFilters()

      dataLoader.gotSubmissions.then () =>
        @setSubmissionsLoaded(true)
        @updateColumnHeaders()
        @renderFilters()

    reloadStudentData: =>
      @setStudentsLoaded(false)
      @setSubmissionsLoaded(false)
      @renderFilters()

      dataLoader = DataLoader.loadGradebookData(
        courseId: @options.context_id
        perPage: @options.api_max_per_page
        studentsURL: @options.students_stateless_url
        studentsPageCb: @gotChunkOfStudents
        studentsParams: @studentsParams()
        loadedStudentIds: @courseContent.students.listStudentIds()
        submissionsURL: @options.submissions_url
        submissionsChunkCb: @gotSubmissionsChunk
        submissionsChunkSize: @options.chunk_size
      )

      dataLoader.gotStudentIds.then (response) =>
        @courseContent.students.setStudentIds(response.user_ids)
        @buildRows()

      dataLoader.gotStudents.then () =>
        @setStudentsLoaded(true)
        @updateColumnHeaders()
        @renderFilters()

      dataLoader.gotSubmissions.then () =>
        @setSubmissionsLoaded(true)
        @updateColumnHeaders()
        @renderFilters()

    loadOverridesForSIS: ->
      return unless @options.post_grades_feature

      assignmentGroupsURL = @options.assignment_groups_url.replace('&include%5B%5D=assignment_visibility', '')
      overrideDataLoader = DataLoader.loadGradebookData(
        assignmentGroupsURL: assignmentGroupsURL
        assignmentGroupsParams:
          exclude_response_fields: @fieldsToExcludeFromAssignments
          include: ['overrides']
        onlyLoadAssignmentGroups: true
      )
      $.when(overrideDataLoader.gotAssignmentGroups).then(@addOverridesToPostGradesStore)

    addOverridesToPostGradesStore: (assignmentGroups) =>
      for group in assignmentGroups
        for assignment in group.assignments
          @assignments[assignment.id].overrides = assignment.overrides if @assignments[assignment.id]
      @postGradesStore.setGradeBookAssignments @assignments

    # dependencies - gridReady
    setAssignmentVisibility: (studentIds) ->
      studentsWithHiddenAssignments = []

      for assignmentId, a of @assignments
        if a.only_visible_to_overrides
          hiddenStudentIds = @hiddenStudentIdsForAssignment(studentIds, a)
          for studentId in hiddenStudentIds
            studentsWithHiddenAssignments.push(studentId)
            @updateSubmission assignment_id: assignmentId, user_id: studentId, hidden: true

      for studentId in _.uniq(studentsWithHiddenAssignments)
        student = @student(studentId)
        @calculateStudentGrade(student)

    hiddenStudentIdsForAssignment: (studentIds, assignment) ->
      # TODO: _.difference is ridic expensive.  may need to do something else
      # for large courses with DA (does that happen?)
      _.difference studentIds, assignment.assignment_visibility

    updateAssignmentVisibilities: (hiddenSub) ->
      assignment = @assignments[hiddenSub.assignment_id]
      filteredVisibility = assignment.assignment_visibility.filter (id) -> id != hiddenSub.user_id
      assignment.assignment_visibility = filteredVisibility

    onShow: ->
      $(".post-grades-button-placeholder").show()
      return if @startedInitializing
      @startedInitializing = true

      @spinner = new Spinner() unless @spinner
      $(@spinner.spin().el).css(
        opacity: 0.5
        top: '55px'
        left: '50%'
      ).addClass('use-css-transitions-for-show-hide').appendTo('#main')
      $('#gradebook-grid-wrapper').hide()

    gotCustomColumns: (columns) =>
      @gradebookContent.customColumns = columns
      columns.forEach (column) =>
        customColumn = @buildCustomColumn(column)
        @gradebookGrid.columns.definitions[customColumn.id] = customColumn

    gotCustomColumnDataChunk: (column, columnData) =>
      studentIds = []

      for datum in columnData
        student = @student(datum.user_id)
        if student? #ignore filtered students
          student["custom_col_#{column.id}"] = datum.content
          studentIds.push(student.id)

      @invalidateRowsForStudentIds(_.uniq(studentIds))

    doSlickgridStuff: =>
      @initGrid()
      @initHeader()
      @gridReady.resolve()
      @loadOverridesForSIS()

    gotAllAssignmentGroups: (assignmentGroups) =>
      # purposely passing the @options and assignmentGroups by reference so it can update
      # an assigmentGroup's .group_weight and @options.group_weighting_scheme
      for group in assignmentGroups
        @assignmentGroups[group.id] = group
        for assignment in group.assignments
          assignment.assignment_group = group
          assignment.due_at = tz.parse(assignment.due_at)
          @updateAssignmentEffectiveDueDates(assignment)
          @assignments[assignment.id] = assignment

    gotSections: (sections) =>
      @setSections(sections.map(htmlEscape))
      @hasSections.resolve()

      @postGradesStore.setSections @sections

    gotChunkOfStudents: (students) =>
      @courseContent.assignmentStudentVisibility = {}
      for student in students
        student.enrollments = _.filter student.enrollments, @isStudentEnrollment
        isStudentView = student.enrollments[0].type == "StudentViewEnrollment"
        student.sections = student.enrollments.map (e) -> e.course_section_id

        if isStudentView
          @studentViewStudents[student.id] = htmlEscape(student)
        else
          @students[student.id] = htmlEscape(student)

        @updateStudentAttributes(student)
        @updateStudentRow(student)

      @gridReady.then =>
        @setupGrading(students)

      if @isFilteringRowsBySearchTerm()
        # When filtering, students cannot be matched until loaded. The grid must
        # be re-rendered more aggressively to ensure new rows are inserted.
        @buildRows()
      else
        @grid?.render()

    isStudentEnrollment: (e) =>
      e.type == "StudentEnrollment" || e.type == "StudentViewEnrollment"

    setupGrading: (students) =>
      # set up a submission for each student even if we didn't receive one
      @submissionStateMap.setup(students, @assignments)
      for student in students
        for assignment_id, assignment of @assignments
          student["assignment_#{assignment_id}"] ?=
            @submissionStateMap.getSubmission student.id, assignment_id
          submissionState = @submissionStateMap.getSubmissionState(student["assignment_#{assignment_id}"])
          student["assignment_#{assignment_id}"].gradeLocked = submissionState.locked
          student["assignment_#{assignment_id}"].gradingType = assignment.grading_type

        student.initialized = true
        @calculateStudentGrade(student)

      studentIds = _.pluck(students, 'id')
      @setAssignmentVisibility(studentIds)

      @invalidateRowsForStudentIds(studentIds)

    resetGrading: =>
      @initSubmissionStateMap()
      @setupGrading(@courseContent.students.listStudents())

    getSubmission: (studentId, assignmentId) =>
      student = @student(studentId)
      student["assignment_#{assignmentId}"]

    updateEffectiveDueDatesFromSubmissions: (submissions) =>
      EffectiveDueDates.updateWithSubmissions(@effectiveDueDates, submissions, @gradingPeriodSet?.gradingPeriods)

    updateAssignmentEffectiveDueDates: (assignment) ->
      assignment.effectiveDueDates = @effectiveDueDates[assignment.id] || {}
      assignment.inClosedGradingPeriod = _.any(assignment.effectiveDueDates, (date) => date.in_closed_grading_period)

    updateStudentAttributes: (student) =>
      student.computed_current_score ||= 0
      student.computed_final_score ||= 0

      student.isConcluded = _.all student.enrollments, (e) ->
        e.enrollment_state == 'completed'
      student.isInactive = _.all student.enrollments, (e) ->
        e.enrollment_state == 'inactive'

      student.cssClass = "student_#{student.id}"

    updateStudentRow: (student) =>
      index = @rows.findIndex (row) => row.id == student.id
      if index != -1
        @rows[index] = student
        @grid?.invalidateRow(index)

    gotAllStudents: =>
      @setStudentsLoaded(true)
      @renderedGrid.then =>
        @gridSupport.columns.updateColumnHeaders(['student'])

    studentsThatCanSeeAssignment: (assignmentId) ->
      @courseContent.assignmentStudentVisibility[assignmentId] ||= (
        assignment = @getAssignment(assignmentId)
        if assignment.only_visible_to_overrides
          _.pick @students, assignment.assignment_visibility...
        else
          @students
      )

    isInvalidSort: =>
      sortSettings = @gradebookColumnOrderSettings

      # This course was sorted by a custom column sort at some point but no longer has any stored
      # column order to sort by
      # let's mark it invalid so it reverts to default sort
      return true if sortSettings?.sortType == 'custom' && !sortSettings?.customOrder

      # This course was sorted by module_position at some point but no longer contains modules
      # let's mark it invalid so it reverts to default sort
      return true if sortSettings?.sortType == 'module_position' && @listContextModules().length == 0

      false

    columnOrderHasNotBeenSaved: =>
      !@gradebookColumnOrderSettings

    isDefaultSortOrder: (sortOrder) =>
      not (['due_date', 'name', 'points', 'module_position', 'custom'].includes(sortOrder))

    getStoredSortOrder: =>
      if @isInvalidSort() || @columnOrderHasNotBeenSaved()
        sortType: @defaultSortType
        direction: 'ascending'
      else
        @gradebookColumnOrderSettings

    setStoredSortOrder: (newSortOrder) ->
      @gradebookColumnOrderSettings = newSortOrder
      unless @isInvalidSort()
        url = @options.gradebook_column_order_settings_url
        $.ajaxJSON(url, 'POST', {column_order: newSortOrder})

    onColumnsReordered: =>
      # determine if assignment columns or custom columns were reordered
      # (this works because frozen columns and non-frozen columns are can't be
      # swapped)
      columns = @grid.getColumns()
      currentIds = (m[1] for columnId in @gradebookGrid.columns.frozen when m = columnId.match /^custom_col_(\d+)/)
      reorderedIds = (m[1] for c in columns when m = c.id.match /^custom_col_(\d+)/)

      frozenColumnCount = @grid.getOptions().numberOfColumnsToFreeze
      @gradebookGrid.columns.frozen = columns.slice(0, frozenColumnCount).map((column) -> column.id)
      @gradebookGrid.columns.scrollable = columns.slice(frozenColumnCount).map((column) -> column.id)

      if !_.isEqual(reorderedIds, currentIds)
        @reorderCustomColumns(reorderedIds)
        .then =>
          colsById = _(@gradebookContent.customColumns).indexBy (c) -> c.id
          @gradebookContent.customColumns = _(reorderedIds).map (id) -> colsById[id]
      else
        @storeCustomColumnOrder()

      @renderViewOptionsMenu()
      @updateColumnHeaders()

    reorderCustomColumns: (ids) ->
      $.ajaxJSON(@options.reorder_custom_columns_url, "POST", order: ids)

    storeCustomColumnOrder: =>
      newSortOrder =
        sortType: 'custom'
        customOrder: []
      columns = @grid.getColumns()
      numberOfColumnsToFreeze = @grid.getOptions().numberOfColumnsToFreeze
      scrollable_columns = columns.slice(numberOfColumnsToFreeze)
      newSortOrder.customOrder = _.pluck(scrollable_columns, 'id')
      @setStoredSortOrder(newSortOrder)

    arrangeColumnsBy: (newSortOrder, isFirstArrangement) =>
      @setStoredSortOrder(newSortOrder) unless isFirstArrangement

      columns = @grid.getColumns()
      frozen = columns.splice(0, @gradebookGrid.columns.frozen.length)
      @gradebookGrid.columns.frozen = frozen.map((column) -> column.id)

      columns = @gradebookGrid.columns.scrollable.map((columnId) => @gradebookGrid.columns.definitions[columnId])
      columns.sort @makeColumnSortFn(newSortOrder)
      @gradebookGrid.columns.scrollable = columns.map((column) -> column.id)

      @updateGrid()
      @renderViewOptionsMenu()
      @updateColumnHeaders()

    makeColumnSortFn: (sortOrder) =>
      switch sortOrder.sortType
        when 'due_date' then @wrapColumnSortFn(@compareAssignmentDueDates, sortOrder.direction)
        when 'module_position' then @wrapColumnSortFn(@compareAssignmentModulePositions, sortOrder.direction)
        when 'name' then @wrapColumnSortFn(@compareAssignmentNames, sortOrder.direction)
        when 'points' then @wrapColumnSortFn(@compareAssignmentPointsPossible, sortOrder.direction)
        when 'custom' then @makeCompareAssignmentCustomOrderFn(sortOrder)
        else @wrapColumnSortFn(@compareAssignmentPositions, sortOrder.direction)

    compareAssignmentPositions: (a, b) ->
      diffOfAssignmentGroupPosition = a.object.assignment_group.position - b.object.assignment_group.position
      diffOfAssignmentPosition = a.object.position - b.object.position

      # order first by assignment_group position and then by assignment position
      # will work when there are less than 1000000 assignments in an assignment_group
      return (diffOfAssignmentGroupPosition * 1000000) + diffOfAssignmentPosition

    compareAssignmentDueDates: (a, b) ->
      firstAssignment = a.object
      secondAssignment = b.object
      assignmentHelper.compareByDueDate(firstAssignment, secondAssignment)

    compareAssignmentModulePositions: (a, b) =>
      firstAssignmentModulePosition = @getContextModule(a.object.module_ids[0])?.position
      secondAssignmentModulePosition = @getContextModule(b.object.module_ids[0])?.position

      if firstAssignmentModulePosition? && secondAssignmentModulePosition?
        if firstAssignmentModulePosition == secondAssignmentModulePosition
          # let's determine their order in the module because both records are in the same module
          firstPositionInModule = a.object.module_positions[0]
          secondPositionInModule = b.object.module_positions[0]

          firstPositionInModule - secondPositionInModule
        else
          # let's determine the order of their modules because both records are in different modules
          firstAssignmentModulePosition - secondAssignmentModulePosition
      else if !firstAssignmentModulePosition? && secondAssignmentModulePosition?
        1
      else if firstAssignmentModulePosition? && !secondAssignmentModulePosition?
        -1
      else
        @compareAssignmentPositions(a, b)

    compareAssignmentNames: (a, b) =>
      @localeSort(a.object.name, b.object.name)

    compareAssignmentPointsPossible: (a, b) ->
      a.object.points_possible - b.object.points_possible

    makeCompareAssignmentCustomOrderFn: (sortOrder) =>
      sortMap = {}
      indexCounter = 0
      for assignmentId in sortOrder.customOrder
        sortMap[String(assignmentId)] = indexCounter
        indexCounter += 1
      return (a, b) =>
        # The second lookup for each index is to maintain backwards
        # compatibility with old gradebook sorting on load which only
        # considered assignment ids.
        aIndex = sortMap[a.id]
        aIndex ?= sortMap[String(a.object.id)] if a.object?
        bIndex = sortMap[b.id]
        bIndex ?= sortMap[String(b.object.id)] if b.object?
        if aIndex? and bIndex?
          return aIndex - bIndex
        # if there's a new assignment or assignment group and its
        # order has not been stored, it should come at the end
        else if aIndex? and not bIndex?
          return -1
        else if bIndex?
          return 1
        else
          return @wrapColumnSortFn(@compareAssignmentPositions)(a, b)

    wrapColumnSortFn: (wrappedFn, direction = 'ascending') ->
      (a, b) ->
        return -1 if b.type is 'total_grade'
        return  1 if a.type is 'total_grade'
        return -1 if b.type is 'assignment_group' and a.type isnt 'assignment_group'
        return  1 if a.type is 'assignment_group' and b.type isnt 'assignment_group'
        if a.type is 'assignment_group' and b.type is 'assignment_group'
          return a.object.position - b.object.position

        [a, b] = [b, a] if direction == 'descending'
        wrappedFn(a, b)

    ## Filtering

    rowFilter: (student) =>
      return true unless @isFilteringRowsBySearchTerm()

      propertiesToMatch = ['name', 'login_id', 'short_name', 'sortable_name']
      pattern = new RegExp(@userFilterTerm, 'i')
      _.any propertiesToMatch, (prop) ->
        student[prop]?.match pattern

    filterAssignments: (assignments) =>
      assignmentFilters = [
        @filterAssignmentBySubmissionTypes,
        @filterAssignmentByPublishedStatus,
        @filterAssignmentByAssignmentGroup,
        @filterAssignmentByGradingPeriod,
        @filterAssignmentByModule
      ]

      matchesAllFilters = (assignment) =>
        assignmentFilters.every ((filter) => filter(assignment))

      assignments.filter(matchesAllFilters)

    filterAssignmentBySubmissionTypes: (assignment) =>
      submissionType = '' + assignment.submission_types
      submissionType isnt 'not_graded' and
        (submissionType isnt 'attendance' or @show_attendance)

    filterAssignmentByPublishedStatus: (assignment) =>
      assignment.published or @showUnpublishedAssignments

    filterAssignmentByAssignmentGroup: (assignment) =>
      return true unless @isFilteringColumnsByAssignmentGroup()
      @getAssignmentGroupToShow() == assignment.assignment_group_id

    filterAssignmentByGradingPeriod: (assignment) =>
      return true unless @isFilteringColumnsByGradingPeriod()
      assignment.id in (@courseContent.gradingPeriodAssignments[@getGradingPeriodToShow()] or [])

    filterAssignmentByModule: (assignment) =>
      contextModuleFilterSetting = @getFilterColumnsBySetting('contextModuleId')
      return true unless contextModuleFilterSetting
      # Firefox returns a value of "null" (String) for this when nothing is set.  The comparison
      # to 'null' below is a result of that
      return true if contextModuleFilterSetting == '0' || contextModuleFilterSetting == 'null'

      @getFilterColumnsBySetting('contextModuleId') in (assignment.module_ids || [])

    ## Course Content Event Handlers

    handleAssignmentMutingChange: (assignment) =>
      @gridSupport.columns.updateColumnHeaders([@getAssignmentColumnId(assignment.id)])
      @updateFilteredContentInfo()
      @buildRows()

    handleSubmissionsDownloading: (assignmentId) =>
      @getAssignment(assignmentId).hasDownloadedSubmissions = true
      @gridSupport.columns.updateColumnHeaders([@getAssignmentColumnId(assignmentId)])

    # filter, sort, and build the dataset for slickgrid to read from, then
    # force a full redraw
    buildRows: =>
      @rows.length = 0 # empty the list of rows

      for student in @courseContent.students.listStudents()
        if @rowFilter(student)
          @rows.push(student)
          @calculateStudentGrade(student) # TODO: this may not be necessary

      return unless @grid

      for id, column of @grid.getColumns() when ''+column.object?.submission_types is "attendance"
        column.unselectable = !@show_attendance
        column.cssClass = if @show_attendance then '' else 'completely-hidden'
        @$grid.find("##{@uid}#{column.id}").showIf(@show_attendance)

      @grid.invalidateAllRows()
      @grid.updateRowCount()
      @grid.render()

    gotSubmissionsChunk: (student_submissions) =>
      changedStudentIds = []
      submissions = []

      for data in student_submissions
        changedStudentIds.push(data.user_id)
        student = @student(data.user_id)
        for submission in data.submissions
          submissions.push(submission)
          @updateSubmission(submission)

        student.loaded = true

      @updateEffectiveDueDatesFromSubmissions(submissions)
      _.each @assignments, (assignment) =>
        @updateAssignmentEffectiveDueDates(assignment)

      changedStudentIds = _.uniq(changedStudentIds)
      students = changedStudentIds.map(@student)
      @setupGrading(students)

    student: (id) =>
      @students[id] || @studentViewStudents[id]

    updateSubmission: (submission) =>
      student = @student(submission.user_id)
      submission.submitted_at = tz.parse(submission.submitted_at)
      submission.excused = !!submission.excused
      submission.rawGrade = submission.grade # save the unformatted version of the grade too
      submission.grade = GradeFormatHelper.formatGrade(submission.grade, {
        gradingType: submission.gradingType, delocalize: false
      })
      cell = student["assignment_#{submission.assignment_id}"] ||= {}
      _.extend(cell, submission)

    # this is used after the CurveGradesDialog submit xhr comes back.  it does not use the api
    # because there is no *bulk* submissions#update endpoint in the api.
    # It is different from gotSubmissionsChunk in that gotSubmissionsChunk expects an array of students
    # where each student has an array of submissions.  This one just expects an array of submissions,
    # they are not grouped by student.
    updateSubmissionsFromExternal: (submissions) =>
      columns = @grid.getColumns()
      changedColumnHeaders = {}
      changedStudentIds = []

      for submission in submissions
        student = @student(submission.user_id)
        idToMatch = @getAssignmentColumnId(submission.assignment_id)
        cell = index for column, index in columns when column.id is idToMatch

        unless changedColumnHeaders[submission.assignment_id]
          changedColumnHeaders[submission.assignment_id] = cell

        #check for DA visible
        @updateAssignmentVisibilities(submission) unless submission.assignment_visible
        @updateSubmission(submission)
        @submissionStateMap.setSubmissionCellState(student, @assignments[submission.assignment_id], submission)
        submissionState = @submissionStateMap.getSubmissionState(submission)
        student["assignment_#{submission.assignment_id}"].gradeLocked = submissionState.locked
        @calculateStudentGrade(student)
        changedStudentIds.push(student.id)

      changedColumnIds = Object.keys(changedColumnHeaders).map(@getAssignmentColumnId)
      @gridSupport.columns.updateColumnHeaders(changedColumnIds)

      @updateRowCellsForStudentIds(_.uniq(changedStudentIds))

    submissionsForStudent: (student) =>
      allSubmissions = (value for key, value of student when key.match ASSIGNMENT_KEY_REGEX)
      return allSubmissions unless @gradingPeriodSet?
      return allSubmissions unless @isFilteringColumnsByGradingPeriod()

      _.filter allSubmissions, (submission) =>
        studentPeriodInfo = @effectiveDueDates[submission.assignment_id]?[submission.user_id]
        studentPeriodInfo and studentPeriodInfo.grading_period_id == @getGradingPeriodToShow()

    calculateStudentGrade: (student) =>
      if student.loaded and student.initialized
        hasGradingPeriods = @gradingPeriodSet and @effectiveDueDates

        grades = CourseGradeCalculator.calculate(
          @submissionsForStudent(student),
          @assignmentGroups,
          @options.group_weighting_scheme,
          @gradingPeriodSet if hasGradingPeriods,
          EffectiveDueDates.scopeToUser(@effectiveDueDates, student.id) if hasGradingPeriods
        )

        if @isFilteringColumnsByGradingPeriod()
          grades = grades.gradingPeriods[@getGradingPeriodToShow()]

        finalOrCurrent = if @include_ungraded_assignments then 'final' else 'current'

        for assignmentGroupId, group of @assignmentGroups
          grade = grades.assignmentGroups[assignmentGroupId]
          grade = grade?[finalOrCurrent] || { score: 0, possible: 0, submissions: [] }

          student["assignment_group_#{assignmentGroupId}"] = grade
          for submissionData in grade.submissions
            submissionData.submission.drop = submissionData.drop
        student["total_grade"] = grades[finalOrCurrent]

    ## Grid Styling Methods

    highlightColumn: (event) =>
      $headers = @$grid.find('.slick-header-column')
      return if $headers.filter('.slick-sortable-placeholder').length
      cell = @grid.getCellFromEvent(event)
      col = @grid.getColumns()[cell.cell]
      $headers.filter("##{@uid}#{col.id}").addClass('hovered-column')

    unhighlightColumns: () =>
      @$grid.find('.hovered-column').removeClass('hovered-column')

    minimizeColumn: ($columnHeader) =>
      columnDef = $columnHeader.data('column')
      colIndex = @grid.getColumnIndex(columnDef.id)
      columnDef.cssClass = (columnDef.cssClass || '').replace(' minimized', '') + ' minimized'
      columnDef.unselectable = true
      columnDef.unminimizedName = columnDef.name
      columnDef.name = ''
      columnDef.minimized = true
      @$grid.find(".l#{colIndex}").add($columnHeader).addClass('minimized')
      @assignmentsToHide.push(columnDef.id)
      UserSettings.contextSet('hidden_columns', _.uniq(@assignmentsToHide))

    unminimizeColumn: ($columnHeader) =>
      columnDef = $columnHeader.data('column')
      colIndex = @grid.getColumnIndex(columnDef.id)
      columnDef.cssClass = (columnDef.cssClass || '').replace(' minimized', '')
      columnDef.unselectable = false
      columnDef.name = columnDef.unminimizedName
      columnDef.minimized = false
      @$grid.find(".l#{colIndex}").add($columnHeader).removeClass('minimized')
      $columnHeader.find('.slick-column-name').html($.raw(columnDef.name))
      @assignmentsToHide = $.grep @assignmentsToHide, (el) -> el != columnDef.id
      UserSettings.contextSet('hidden_columns', _.uniq(@assignmentsToHide))

    # this is because of a limitation with SlickGrid,
    # when it makes the header row it does this:
    # $("<div class='slick-header-columns' style='width:10000px; left:-1000px' />")
    # if a course has a ton of assignments then it will not be wide enough to
    # contain them all
    fixMaxHeaderWidth: ->
      @$grid.find('.slick-header-columns').width(1000000)

    # SlickGrid doesn't have a blur event for the grid, so this mimics it in
    # conjunction with a click listener on <body />. When we 'blur' the grid
    # by clicking outside of it, save the current field.
    onGridBlur: (e) =>
      @closeSubmissionTray() if @getSubmissionTrayState().open

      # Prevent exiting the cell editor when clicking in the cell being edited.
      editingNode = @gridSupport.state.getEditingNode()
      return if editingNode?.contains(e.target)

      activeNode = @gridSupport.state.getActiveNode()
      return unless activeNode

      if activeNode.contains(e.target)
        # SlickGrid does not re-engage the editor for the active cell upon single click
        @gridSupport.helper.beginEdit()
        return

      className = e.target.className

      # PopoverMenu's trigger sends an event with a target whose className is a SVGAnimatedString
      # This normalizes the className where possible
      if typeof className != 'string'
        if typeof className == 'object'
          className = className.baseVal || ''
        else
          className = ''

      # Do nothing if clicking on another cell
      return if className.match(/cell|slick/)

      @gridSupport.state.blur()

    onGridInit: () ->
      tooltipTexts = {}
      # TODO: this "if @spinner" crap is necessary because the outcome
      # gradebook kicks off the gradebook (unnecessarily).  back when the
      # gradebook was slow, this code worked, but now the spinner may never
      # initialize.  fix the way outcome gradebook loads
      $(@spinner.el).remove() if @spinner
      $('#gradebook-grid-wrapper').show()
      @uid = @grid.getUID()
      $('#content').focus ->
        $('#accessibility_warning').removeClass('screenreader-only')
      $('#accessibility_warning').focus ->
        $('#accessibility_warning').blur ->
          $('#accessibility_warning').remove()
      @$grid = grid = $('#gradebook_grid')
        .fillWindowWithMe({
          onResize: => @grid.resizeCanvas()
        })
        .delegate '.slick-cell',
          'mouseenter.gradebook' : @highlightColumn
          'mouseleave.gradebook' : @unhighlightColumns
          'mouseenter' : (event) ->
            grid.find('.hover, .focus').removeClass('hover focus')
            $(this).addClass (if event.type == 'mouseenter' then 'hover' else 'focus')
          'mouseleave' : (event) ->
            $(this).removeClass('hover focus')

      @$grid.addClass('editable') if @options.gradebook_is_editable

      @fixMaxHeaderWidth()
      @grid.onColumnsResized.subscribe (e, data) =>
        @$grid.find('.slick-header-column').each (i, elem) =>
          $columnHeader = $(elem)
          columnDef = $columnHeader.data('column')
          return unless columnDef.type is "assignment"
          if $columnHeader.outerWidth() <= columnWidths.assignment.min
            @minimizeColumn($columnHeader) unless columnDef.minimized
          else if columnDef.minimized
            @unminimizeColumn($columnHeader)

      @keyboardNav.init()
      keyBindings = @keyboardNav.keyBindings
      @kbDialog = new KeyboardNavDialog().render(KeyboardNavTemplate({keyBindings}))
      $(document).trigger('gridready')

    sectionList: () ->
      _.values(@sections).sort((a, b) => (a.id - b.id))

    updateSectionFilterVisibility: () ->
      mountPoint = document.getElementById('sections-filter-container')

      if @showSections() and 'sections' in @gridDisplaySettings.selectedViewOptionsFilters
        sectionList = @sectionList()
        props =
          items: sectionList
          onSelect: @updateCurrentSection
          selectedItemId: @getFilterRowsBySetting('sectionId') || '0'
          disabled: !@contentLoadStates.studentsLoaded

        @sectionFilterMenu = renderComponent(SectionFilter, mountPoint, props)
      else if @sectionFilterMenu
        ReactDOM.unmountComponentAtNode(mountPoint)
        @sectionFilterMenu = null

    updateCurrentSection: (sectionId) =>
      sectionId = if sectionId == '0' then null else sectionId
      currentSection = @getFilterRowsBySetting('sectionId')
      if currentSection != sectionId
        @setFilterRowsBySetting('sectionId', sectionId)
        @postGradesStore.setSelectedSection(sectionId)
        @updateSectionFilterVisibility()
        @saveSettings({}, =>
          @reloadStudentData()
        )

    showSections: ->
      @sections_enabled

    assignmentGroupList: ->
      return [] unless @assignmentGroups
      Object.values(@assignmentGroups).sort((a, b) => (a.position - b.position))

    updateAssignmentGroupFilterVisibility: ->
      mountPoint = document.getElementById('assignment-group-filter-container')
      groups = @assignmentGroupList()

      if groups.length > 1 and 'assignmentGroups' in @gridDisplaySettings.selectedViewOptionsFilters
        props =
          items: groups
          onSelect: @updateCurrentAssignmentGroup
          selectedItemId: @getAssignmentGroupToShow()

        @assignmentGroupFilterMenu = renderComponent(AssignmentGroupFilter, mountPoint, props)
      else if @assignmentGroupFilterMenu?
        ReactDOM.unmountComponentAtNode(mountPoint)
        @assignmentGroupFilterMenu = null

    updateCurrentAssignmentGroup: (group) =>
      if @getFilterColumnsBySetting('assignmentGroupId') != group
        @setFilterColumnsBySetting('assignmentGroupId', group)
        @saveSettings()
        @resetGrading()
        @updateFilteredContentInfo()
        @updateColumnsAndRenderViewOptionsMenu()
        @updateAssignmentGroupFilterVisibility()

    gradingPeriodList: ->
      @gradingPeriodSet.gradingPeriods.sort((a, b) => (a.startDate - b.startDate))

    updateGradingPeriodFilterVisibility: () ->
      mountPoint = document.getElementById('grading-periods-filter-container')

      if @gradingPeriodSet? and 'gradingPeriods' in @gridDisplaySettings.selectedViewOptionsFilters
        props =
          items: @gradingPeriodList().map((item) => { id: item.id, name: item.title })
          onSelect: @updateCurrentGradingPeriod
          selectedItemId: @getGradingPeriodToShow()

        @gradingPeriodFilterMenu = renderComponent(GradingPeriodFilter, mountPoint, props)
      else if @gradingPeriodFilterMenu?
        ReactDOM.unmountComponentAtNode(mountPoint)
        @gradingPeriodFilterMenu = null

    updateCurrentGradingPeriod: (period) =>
      if @getFilterColumnsBySetting('gradingPeriodId') != period
        @setFilterColumnsBySetting('gradingPeriodId', period)
        @saveSettings()
        @resetGrading()
        @sortGridRows()
        @updateFilteredContentInfo()
        @updateColumnsAndRenderViewOptionsMenu()
        @updateGradingPeriodFilterVisibility()

    updateCurrentModule: (moduleId) =>
      if @getFilterColumnsBySetting('contextModuleId') != moduleId
        @setFilterColumnsBySetting('contextModuleId', moduleId)
        @saveSettings()
        @updateFilteredContentInfo()
        @updateColumnsAndRenderViewOptionsMenu()
        @updateModulesFilterVisibility()

    moduleList: ->
      @listContextModules().sort((a, b) => (a.position - b.position))

    updateModulesFilterVisibility: () ->
      mountPoint = document.getElementById('modules-filter-container')

      if @listContextModules()?.length > 0 and 'modules' in @gridDisplaySettings.selectedViewOptionsFilters
        props =
          items: @moduleList()
          onSelect: @updateCurrentModule
          selectedItemId: @getFilterColumnsBySetting('contextModuleId') || '0'

        @moduleFilterMenu = renderComponent(ModuleFilter, mountPoint, props)
      else if @moduleFilterMenu?
        ReactDOM.unmountComponentAtNode(mountPoint)
        @moduleFilterMenu = null

    initSubmissionStateMap: =>
      @submissionStateMap = new SubmissionStateMap
        hasGradingPeriods: @gradingPeriodSet?
        selectedGradingPeriodID: @getGradingPeriodToShow()
        isAdmin: isAdmin()

    initPostGradesStore: ->
      @postGradesStore = PostGradesStore
        course:
          id:     @options.context_id
          sis_id: @options.context_sis_id
      @postGradesStore.addChangeListener(@updatePostGradesFeatureButton)

      sectionId = @getFilterRowsBySetting('sectionId')
      @postGradesStore.setSelectedSection(sectionId)

    delayedCall: (delay, fn) =>
      setTimeout fn, delay

    initPostGradesLtis: =>
      @postGradesLtis = @options.post_grades_ltis.map (lti) =>
        postGradesLti =
          id: lti.id
          name: lti.name
          onSelect: =>
            postGradesDialog = new PostGradesFrameDialog
              returnFocusTo: document.querySelector("[data-component='ActionMenu'] button")
              baseUrl: lti.data_url
            @delayedCall 10, => postGradesDialog.open()
            window.external_tool_redirect =
              ready: postGradesDialog.close
              cancel: postGradesDialog.close

    updatePostGradesFeatureButton: =>
      @disablePostGradesFeature = !@postGradesStore.hasAssignments() || !@postGradesStore.selectedSISId()
      @gridReady.then =>
        @renderActionMenu()

    initHeader: =>
      @renderGradebookMenus()
      @renderFilters()

      @arrangeColumnsBy(@getStoredSortOrder(), true)

      @renderGradebookSettingsModal()
      @renderSettingsButton()
      @renderStatusesModal()

      $('#keyboard-shortcuts').click ->
        questionMarkKeyDown = $.Event('keydown', keyCode: 191)
        $(document).trigger(questionMarkKeyDown)

    renderGradebookMenus: =>
      @renderGradebookMenu()
      @renderViewOptionsMenu()
      @renderActionMenu()

    renderGradebookMenu: =>
      mountPoints = document.querySelectorAll('[data-component="GradebookMenu"]')
      props =
        assignmentOrOutcome: @options.assignmentOrOutcome
        courseUrl: @options.context_url,
        learningMasteryEnabled: @options.outcome_gradebook_enabled,
        navigate: @options.navigate
      for mountPoint in mountPoints
        props.variant = mountPoint.getAttribute('data-variant')
        renderComponent(GradebookMenu, mountPoint, props)

    getTeacherNotesViewOptionsMenuProps: ->
      teacherNotes = @getTeacherNotesColumn()
      showingNotes = teacherNotes? and not teacherNotes.hidden
      if showingNotes
        onSelect = => @setTeacherNotesHidden(true)
      else if teacherNotes
        onSelect = => @setTeacherNotesHidden(false)
      else
        onSelect = @createTeacherNotes

      disabled: @contentLoadStates.teacherNotesColumnUpdating
      onSelect: onSelect
      selected: showingNotes

    getColumnSortSettingsViewOptionsMenuProps: ->
      storedSortOrder = @getStoredSortOrder()
      criterion = if @isDefaultSortOrder(storedSortOrder.sortType)
        'default'
      else
        storedSortOrder.sortType

      criterion: criterion
      direction: storedSortOrder.direction || 'ascending'
      disabled: not @contentLoadStates.assignmentsLoaded
      modulesEnabled: @listContextModules().length > 0
      onSortByDefault: =>
        @arrangeColumnsBy({ sortType: 'default', direction: 'ascending' }, false)
      onSortByNameAscending: =>
        @arrangeColumnsBy({ sortType: 'name', direction: 'ascending' }, false)
      onSortByNameDescending: =>
        @arrangeColumnsBy({ sortType: 'name', direction: 'descending' }, false)
      onSortByDueDateAscending: =>
        @arrangeColumnsBy({ sortType: 'due_date', direction: 'ascending' }, false)
      onSortByDueDateDescending: =>
        @arrangeColumnsBy({ sortType: 'due_date', direction: 'descending' }, false)
      onSortByPointsAscending: =>
        @arrangeColumnsBy({ sortType: 'points', direction: 'ascending' }, false)
      onSortByPointsDescending: =>
        @arrangeColumnsBy({ sortType: 'points', direction: 'descending' }, false)
      onSortByModuleAscending: =>
        @arrangeColumnsBy({ sortType: 'module_position', direction: 'ascending' }, false)
      onSortByModuleDescending: =>
        @arrangeColumnsBy({ sortType: 'module_position', direction: 'descending' }, false)

    getFilterSettingsViewOptionsMenuProps: =>
      available: @listAvailableViewOptionsFilters()
      onSelect: (filters) =>
        @setSelectedViewOptionsFilters(filters)
        @renderViewOptionsMenu()
        @renderFilters()
        @saveSettings()
      selected: @listSelectedViewOptionsFilters()

    getViewOptionsMenuProps: ->
      teacherNotes: @getTeacherNotesViewOptionsMenuProps()
      columnSortSettings: @getColumnSortSettingsViewOptionsMenuProps()
      filterSettings: @getFilterSettingsViewOptionsMenuProps()
      showUnpublishedAssignments: @showUnpublishedAssignments
      onSelectShowUnpublishedAssignments: @toggleUnpublishedAssignments
      onSelectShowStatusesModal: =>
        @statusesModal.open()

    renderViewOptionsMenu: =>
      mountPoint = document.querySelector("[data-component='ViewOptionsMenu']")
      @viewOptionsMenu = renderComponent(ViewOptionsMenu, mountPoint, @getViewOptionsMenuProps())

    getActionMenuProps: =>
      focusReturnPoint = document.querySelector("[data-component='ActionMenu'] button")
      actionMenuProps =
        gradebookIsEditable: @options.gradebook_is_editable
        contextAllowsGradebookUploads: @options.context_allows_gradebook_uploads
        gradebookImportUrl: @options.gradebook_import_url
        currentUserId: ENV.current_user_id
        gradebookExportUrl: @options.export_gradebook_csv_url
        postGradesLtis: @postGradesLtis
        postGradesFeature:
          enabled: @options.post_grades_feature? && !@disablePostGradesFeature
          returnFocusTo: focusReturnPoint
          label: @options.sis_name
          store: @postGradesStore
        publishGradesToSis:
          isEnabled: @options.publish_to_sis_enabled?
          publishToSisUrl: @options.publish_to_sis_url

      progressData = @options.gradebook_csv_progress

      if @options.gradebook_csv_progress
        actionMenuProps.lastExport =
          progressId: "#{progressData.progress.id}"
          workflowState: progressData.progress.workflow_state

        attachmentData = @options.attachment
        if attachmentData
          actionMenuProps.attachment =
            id: "#{attachmentData.attachment.id}"
            downloadUrl: @options.attachment_url
            updatedAt: attachmentData.attachment.updated_at
      actionMenuProps

    renderActionMenu: =>
      mountPoint = document.querySelector("[data-component='ActionMenu']")
      props = @getActionMenuProps()
      renderComponent(ActionMenu, mountPoint, props)

    renderFilters: =>
      @updateSectionFilterVisibility()
      @updateAssignmentGroupFilterVisibility()
      @updateGradingPeriodFilterVisibility()
      @updateModulesFilterVisibility()
      @renderSearchFilter()

    renderGridColor: =>
      gridColorMountPoint = document.querySelector('[data-component="GridColor"]')
      gridColorProps =
        colors: @getGridColors()
      renderComponent(GridColor, gridColorMountPoint, gridColorProps)

    renderGradebookSettingsModal: =>
      gradebookSettingsModalMountPoint = document.querySelector("[data-component='GradebookSettingsModal']")
      gradebookSettingsModalProps =
        courseId: @options.context_id
        locale: @options.locale
        onClose: => @gradebookSettingsModalButton.focus()
        onLatePolicyUpdate: @onLatePolicyUpdate
        newGradebookDevelopmentEnabled: @options.new_gradebook_development_enabled
        gradedLateOrMissingSubmissionsExist: @options.graded_late_or_missing_submissions_exist
      @gradebookSettingsModal = renderComponent(
        GradebookSettingsModal,
        gradebookSettingsModalMountPoint,
        gradebookSettingsModalProps
      )

    renderSettingsButton: =>
      buttonMountPoint = document.getElementById('gradebook-settings-modal-button-container')
      buttonProps =
        id: 'gradebook-settings-button',
        variant: 'icon',
        onClick: @gradebookSettingsModal.open
      iconSettingsSolid = React.createElement(IconSettingsSolid, { title: I18n.t('Gradebook Settings') })
      @gradebookSettingsModalButton = renderComponent(Button, buttonMountPoint, buttonProps, iconSettingsSolid)

    renderStatusesModal: =>
      statusesModalMountPoint = document.querySelector("[data-component='StatusesModal']")
      statusesModalProps =
        onClose: => @viewOptionsMenu.focus()
        colors: @getGridColors()
        afterUpdateStatusColors: @updateGridColors
      @statusesModal = renderComponent(StatusesModal, statusesModalMountPoint, statusesModalProps)

    checkForUploadComplete: () ->
      if UserSettings.contextGet('gradebookUploadComplete')
        $.flashMessage I18n.t('Upload successful')
        UserSettings.contextRemove('gradebookUploadComplete')

    weightedGroups: =>
      @options.group_weighting_scheme == "percent"

    weightedGrades: =>
      @options.group_weighting_scheme == "percent" || @gradingPeriodSet?.weighted || false

    displayPointTotals: =>
      @options.show_total_grade_as_points and not @weightedGrades()

    switchTotalDisplay: ({ dontWarnAgain = false } = {}) =>
      if dontWarnAgain
        UserSettings.contextSet('warned_about_totals_display', true)

      @options.show_total_grade_as_points = not @options.show_total_grade_as_points
      $.ajaxJSON @options.setting_update_url, "PUT", show_total_grade_as_points: @displayPointTotals()
      @grid.invalidate()
      @gridSupport.columns.updateColumnHeaders(['total_grade'])

    togglePointsOrPercentTotals: (cb) =>
      if UserSettings.contextGet('warned_about_totals_display')
        @switchTotalDisplay()
        cb() if typeof cb == 'function'
      else
        dialog_options =
          showing_points: @options.show_total_grade_as_points
          save: @switchTotalDisplay
          onClose: cb
        new GradeDisplayWarningDialog(dialog_options)

    onUserFilterInput: (term) =>
      @userFilterTerm = term
      @buildRows()

    renderSearchFilter: =>
      unless @userFilter
        @userFilter = new InputFilterView(el: '#search-filter-container input')
        @userFilter.on('input', @onUserFilterInput)

      disabled = !@contentLoadStates.studentsLoaded or !@contentLoadStates.submissionsLoaded
      @userFilter.el.disabled = disabled
      @userFilter.el.setAttribute('aria-disabled', disabled)

    setVisibleGridColumns: ->
      assignments = @filterAssignments(Object.values(@assignments))
      scrollableColumns = assignments.map (assignment) =>
        @gradebookGrid.columns.definitions[@getAssignmentColumnId(assignment.id)]

      unless @hideAggregateColumns()
        for assignmentGroupId of @assignmentGroups
          scrollableColumns.push(@gradebookGrid.columns.definitions[@getAssignmentGroupColumnId(assignmentGroupId)])
        scrollableColumns.push(@gradebookGrid.columns.definitions['total_grade'])

      if @gradebookColumnOrderSettings?.sortType
        scrollableColumns.sort @makeColumnSortFn(@getStoredSortOrder())

      parentColumnIds = @gradebookGrid.columns.frozen.filter((columnId) -> !/^custom_col_/.test(columnId))
      customColumnIds = @listVisibleCustomColumns().map((column) => @getCustomColumnId(column.id))

      @gradebookGrid.columns.frozen = [parentColumnIds..., customColumnIds...]
      @gradebookGrid.columns.scrollable = scrollableColumns.map((column) -> column.id)

    getVisibleGradeGridColumns: ->
      [@gradebookGrid.columns.frozen..., @gradebookGrid.columns.scrollable...].map (columnId) =>
        @gradebookGrid.columns.definitions[columnId]

    updateGrid: ->
      @grid.setNumberOfColumnsToFreeze(@gradebookGrid.columns.frozen.length)
      @grid.setColumns(@getVisibleGradeGridColumns())
      @grid.invalidate()

    ## Grid Column Definitions

    # Student Column

    buildStudentColumn: ->
      studentColumnWidth = 150
      if @gradebookColumnSizeSettings
        if @gradebookColumnSizeSettings['student']
          studentColumnWidth = parseInt(@gradebookColumnSizeSettings['student'])

      {
        id: 'student'
        type: 'student'
        width: studentColumnWidth
        cssClass: 'meta-cell primary-column student'
        headerCssClass: 'primary-column student'
        resizable: true
      }

    # Custom Column

    buildCustomColumn: (customColumn) =>
      columnId = @getCustomColumnId(customColumn.id)

      id: columnId
      type: 'custom_column'
      name: htmlEscape customColumn.title
      field: "custom_col_#{customColumn.id}"
      width: 100
      cssClass: "meta-cell custom_column #{columnId}"
      headerCssClass: "custom_column #{columnId}"
      resizable: true
      editor: LongTextEditor
      customColumnId: customColumn.id
      autoEdit: false
      maxLength: 255

    # Assignment Column

    buildAssignmentColumn: (assignment) ->
      shrinkForOutOfText = assignment && assignment.grading_type == 'points' && assignment.points_possible?
      minWidth = if shrinkForOutOfText then 140 else 90

      columnId = @getAssignmentColumnId(assignment.id)
      fieldName = "assignment_#{assignment.id}"

      if @gradebookColumnSizeSettings && @gradebookColumnSizeSettings[fieldName]
        assignmentWidth = parseInt(@gradebookColumnSizeSettings[fieldName])
      else
        assignmentWidth = testWidth(assignment.name, minWidth, columnWidths.assignment.default_max)

      columnDef =
        id: columnId
        field: fieldName
        name: assignment.name
        object: assignment
        getGridSupport: => @gridSupport
        propFactory: new AssignmentRowCellPropFactory(assignment, @)
        minWidth: columnWidths.assignment.min
        maxWidth: columnWidths.assignment.max
        width: assignmentWidth
        cssClass: "assignment #{columnId}"
        headerCssClass: "assignment #{columnId}"
        toolTip: assignment.name
        type: 'assignment'
        assignmentId: assignment.id

      if fieldName in @assignmentsToHide
        columnDef.width = 10
        do (fieldName) =>
          $(document)
            .bind('gridready', =>
              @minimizeColumn(@$grid.find("##{@uid}#{fieldName}"))
            )
            .unbind('gridready.render')
            .bind('gridready.render', => @grid.invalidate() )

      columnDef

    buildAssignmentGroupColumn: (assignmentGroup) ->
      columnId = @getAssignmentGroupColumnId(assignmentGroup.id)
      fieldName = "assignment_group_#{assignmentGroup.id}"

      if @gradebookColumnSizeSettings && @gradebookColumnSizeSettings[fieldName]
        width = parseInt(@gradebookColumnSizeSettings[fieldName])
      else
        width = testWidth(
          assignmentGroup.name, columnWidths.assignmentGroup.min, columnWidths.assignmentGroup.default_max
        )

      {
        id: columnId
        field: fieldName
        name: assignmentGroup.name
        toolTip: assignmentGroup.name
        object: assignmentGroup
        minWidth: columnWidths.assignmentGroup.min
        maxWidth: columnWidths.assignmentGroup.max
        width: width
        cssClass: "meta-cell assignment-group-cell #{columnId}"
        headerCssClass: "assignment_group #{columnId}"
        type: 'assignment_group'
        assignmentGroupId: assignmentGroup.id
      }

    buildTotalGradeColumn: ->
      label = I18n.t "Total"

      if @gradebookColumnSizeSettings && @gradebookColumnSizeSettings['total_grade']
        totalWidth = parseInt(@gradebookColumnSizeSettings['total_grade'])
      else
        totalWidth = testWidth(label, columnWidths.total.min, columnWidths.total.max)

      {
        id: "total_grade"
        field: "total_grade"
        toolTip: label
        minWidth: columnWidths.total.min
        maxWidth: columnWidths.total.max
        width: totalWidth
        cssClass: 'total-cell total_grade'
        headerCssClass: 'total_grade'
        type: 'total_grade'
      }

    initGrid: =>
      @updateFilteredContentInfo()

      studentColumn = @buildStudentColumn()
      @gradebookGrid.columns.definitions[studentColumn.id] = studentColumn
      @gradebookGrid.columns.frozen.push(studentColumn.id)

      for id, assignment of @assignments
        assignmentColumn = @buildAssignmentColumn(assignment)
        @gradebookGrid.columns.definitions[assignmentColumn.id] = assignmentColumn

      for id, assignmentGroup of @assignmentGroups
        assignmentGroupColumn = @buildAssignmentGroupColumn(assignmentGroup)
        @gradebookGrid.columns.definitions[assignmentGroupColumn.id] = assignmentGroupColumn

      totalGradeColumn = @buildTotalGradeColumn()
      @gradebookGrid.columns.definitions[totalGradeColumn.id] = totalGradeColumn

      @renderGridColor()
      @createGrid()

    createGrid: () =>
      options = $.extend({
        enableCellNavigation: true
        enableColumnReorder: true
        autoEdit: true # whether to go into edit-mode as soon as you tab to a cell
        editable: @options.gradebook_is_editable
        editorFactory: new CellEditorFactory()
        formatterFactory: new CellFormatterFactory(@)
        syncColumnCellResize: true
        rowHeight: 35
        headerHeight: 38
        numberOfColumnsToFreeze: @gradebookGrid.columns.frozen.length
      }, @options)

      @setVisibleGridColumns()
      @grid = new Slick.Grid('#gradebook_grid', @rows, @getVisibleGradeGridColumns(), options)
      @grid.setSortColumn('student')

      # This is a faux blur event for SlickGrid.
      # Use capture to preempt SlickGrid's internal handlers.
      document.getElementById('application')
        .addEventListener('click', @onGridBlur, true)

      # Grid Events
      @grid.onKeyDown.subscribe @onGridKeyDown

      # Grid Header Events
      @grid.onColumnsReordered.subscribe @onColumnsReordered
      @grid.onColumnsResized.subscribe @onColumnsResized

      # Grid Body Cell Events
      @grid.onBeforeEditCell.subscribe @onBeforeEditCell
      @grid.onCellChange.subscribe @onCellChange

      gridSupportOptions = {
        activeBorderColor: '#1790DF' # $active-border-color
        columnHeaderRenderer: new ColumnHeaderRenderer(@)
        rows: @rows
      }

      if ENV.use_high_contrast
        gridSupportOptions.activeHeaderBackground = '#E6F1F7' # $ic-bg-light-primary
      else
        gridSupportOptions.activeHeaderBackground = '#E5F2F8' # $ic-bg-light-primary

      # Improved SlickGrid Management
      @gridSupport = new GridSupport(@grid, gridSupportOptions)

      @keyboardNav = new GradebookKeyboardNav({
        gridSupport: @gridSupport,
        getColumnTypeForColumnId: @getColumnTypeForColumnId,
        toggleDefaultSort: @toggleDefaultSort,
        openSubmissionTray: @openSubmissionTray
      })

      @gridSupport.initialize()

      @gridSupport.events.onActiveLocationChanged.subscribe (event, location) =>
        if location.columnId == 'student' && location.region == 'body'
          @gridSupport.state.getActiveNode().querySelector('.student-grades-link')?.focus()

      @gridSupport.events.onKeyDown.subscribe (event, location) =>
        if (location.region == 'header')
          @getHeaderComponentRef(location.columnId)?.handleKeyDown(event)

      @gridSupport.events.onNavigatePrev.subscribe (event, location) =>
        if (location.region == 'header')
          @getHeaderComponentRef(location.columnId)?.focusAtEnd()

      @gridSupport.events.onNavigateNext.subscribe (event, location) =>
        if (location.region == 'header')
          @getHeaderComponentRef(location.columnId)?.focusAtStart()

      @gridSupport.events.onNavigateLeft.subscribe (event, location) =>
        if (location.region == 'header')
          @getHeaderComponentRef(location.columnId)?.focusAtStart()

      @gridSupport.events.onNavigateRight.subscribe (event, location) =>
        if (location.region == 'header')
          @getHeaderComponentRef(location.columnId)?.focusAtStart()

      @gridSupport.events.onNavigateUp.subscribe (event, location) =>
        if (location.region == 'header')
          @getHeaderComponentRef(location.columnId)?.focusAtStart()

      @onGridInit()

    # Grid Event Handlers

    onGridKeyDown: (event, obj) =>
      return unless obj.row? and obj.cell?

      columns = obj.grid.getColumns()
      column = columns[obj.cell]

      return unless column

      if column.type == 'student' and event.which == 13 # activate link
        event.originalEvent.skipSlickGridDefaults = true

    ## Grid Body Event Handlers

    # The target cell will enter editing mode
    onBeforeEditCell: (event, obj) =>
      { row, cell } = obj
      $cell = @grid.getCellNode(row, cell)
      return false if $($cell).hasClass("cannot_edit") || $($cell).find(".gradebook-cell").hasClass("cannot_edit")

    # The current cell editor has been changed and is valid
    onCellChange: (event, obj) =>
      { item, column } = obj
      if col_id = column.field.match /^custom_col_(\d+)/
        url = @options.custom_column_datum_url
          .replace(/:id/, col_id[1])
          .replace(/:user_id/, item.id)

        $.ajaxJSON url, "PUT", "column_data[content]": item[column.field]
      else
        # this is the magic that actually updates group and final grades when you edit a cell
        @calculateStudentGrade(item)
        @grid.invalidate()

    onColumnsResized: (event, obj) =>
      grid = obj.grid
      columns = grid.getColumns()

      _.each columns, (column) =>
        if column.previousWidth && column.width != column.previousWidth
          @saveColumnWidthPreference(column.id, column.width)

    # Persisted Gradebook Settings

    saveColumnWidthPreference: (id, newWidth) ->
      url = @options.gradebook_column_size_settings_url
      $.ajaxJSON(url, 'POST', {column_id: id, column_size: newWidth})

    saveSettings: ({
      selectedViewOptionsFilters = @listSelectedViewOptionsFilters(),
      showConcludedEnrollments = @getEnrollmentFilters().concluded,
      showInactiveEnrollments = @getEnrollmentFilters().inactive,
      showUnpublishedAssignments = @showUnpublishedAssignments,
      studentColumnDisplayAs = @getSelectedPrimaryInfo(),
      studentColumnSecondaryInfo = @getSelectedSecondaryInfo(),
      sortRowsBy = @getSortRowsBySetting(),
      colors = @getGridColors()
    } = {}, successFn, errorFn) =>
      selectedViewOptionsFilters.push('') unless selectedViewOptionsFilters.length > 0
      data =
        gradebook_settings:
          filter_columns_by: ConvertCase.underscore(@gridDisplaySettings.filterColumnsBy)
          selected_view_options_filters: selectedViewOptionsFilters
          show_concluded_enrollments: showConcludedEnrollments
          show_inactive_enrollments: showInactiveEnrollments
          show_unpublished_assignments: showUnpublishedAssignments
          student_column_display_as: studentColumnDisplayAs
          student_column_secondary_info: studentColumnSecondaryInfo
          filter_rows_by: ConvertCase.underscore(@gridDisplaySettings.filterRowsBy)
          sort_rows_by_column_id: sortRowsBy.columnId
          sort_rows_by_setting_key: sortRowsBy.settingKey
          sort_rows_by_direction: sortRowsBy.direction
          colors: colors

      # TODO: include the "sort rows by" setting for Assignment Groups and Total
      # Grade when fully supported by the Gradebook `user_ids` endpoint.
      sortingByIncompleteSortFeature = data.gradebook_settings.sort_rows_by_column_id.match(/^assignment_group_/)
      sortingByIncompleteSortFeature ||= data.gradebook_settings.sort_rows_by_column_id == 'total_grade'
      if sortingByIncompleteSortFeature
        delete data.gradebook_settings.sort_rows_by_column_id
        delete data.gradebook_settings.sort_rows_by_setting_key
        delete data.gradebook_settings.sort_rows_by_direction

      $.ajaxJSON(@options.settings_update_url, 'PUT', data, successFn, errorFn)

    ## Grid Sorting Methods

    sortRowsBy: (sortFn) ->
      respectorOfPersonsSort = =>
        if _(@studentViewStudents).size()
          (a, b) =>
            if @studentViewStudents[a.id]
              return 1
            else if @studentViewStudents[b.id]
              return -1
            else
              sortFn(a, b)
        else
          sortFn

      @rows.sort respectorOfPersonsSort()
      @courseContent.students.setStudentIds(_.map(@rows, 'id'))
      @grid?.invalidate()

    getStudentGradeForColumn: (student, field) =>
      student[field] || { score: null, possible: 0 }

    getGradeAsPercent: (grade) =>
      if grade.possible > 0
        (grade.score || 0) / grade.possible
      else
        null

    getColumnTypeForColumnId: (columnId) =>
      if columnId.match /^custom_col/
        return 'custom_column'
      else if columnId.match ASSIGNMENT_KEY_REGEX
        return 'assignment'
      else if columnId.match /^assignment_group/
        return 'assignment_group'
      else
        return columnId

    localeSort: (a, b, { asc = true } = {}) ->
      [b, a] = [a, b] unless asc
      natcompare.strings(a || '', b || '')

    idSort: (a, b, { asc = true }) ->
      NumberCompare(Number(a.id), Number(b.id), descending: !asc)

    secondaryAndTertiarySort: (a, b, { asc = true }) =>
      result = @localeSort(a.sortable_name, b.sortable_name, { asc })
      result = @idSort(a, b, { asc }) if result == 0
      result

    gradeSort: (a, b, field, asc) =>
      scoreForSorting = (student) =>
        grade = @getStudentGradeForColumn(student, field)
        if field == "total_grade"
          if @options.show_total_grade_as_points
            grade.score
          else
            @getGradeAsPercent(grade)
        else if field.match /^assignment_group/
          @getGradeAsPercent(grade)
        else
          # TODO: support assignment grading types
          grade.score
      result = NumberCompare(scoreForSorting(a), scoreForSorting(b), descending: !asc)
      result = @secondaryAndTertiarySort(a, b, { asc }) if result == 0
      result

    # when fn is true, those rows get a -1 so they go to the top of the sort
    sortRowsWithFunction: (fn, { asc = true } = {}) ->
      @sortRowsBy((a, b) =>
        rowA = fn(a)
        rowB = fn(b)
        [rowA, rowB] = [rowB, rowA] unless asc
        return -1 if rowA > rowB
        return 1 if rowA < rowB
        @secondaryAndTertiarySort(a, b, { asc })
      )

    missingSort: (columnId) =>
      @sortRowsWithFunction((row) => !!row[columnId]?.missing)

    lateSort: (columnId) =>
      @sortRowsWithFunction((row) => row[columnId].late)

    sortByStudentColumn: (settingKey, direction) =>
      @sortRowsBy((a, b) =>
        asc = direction == 'ascending'
        result = @localeSort(a[settingKey], b[settingKey], { asc })
        result = @idSort(a, b, { asc }) if result == 0
        result
      )

    sortByCustomColumn: (columnId, direction) =>
      @sortRowsBy((a, b) =>
        asc = direction == 'ascending'
        result = @localeSort(a[columnId], b[columnId], { asc } )
        result = @secondaryAndTertiarySort(a, b, { asc }) if result == 0
        result
      )

    sortByAssignmentColumn: (columnId, settingKey, direction) =>
      switch settingKey
        when 'grade'
          @sortRowsBy((a, b) => @gradeSort(a, b, columnId, direction == 'ascending'))
        when 'late'
          @lateSort(columnId)
        when 'missing'
          @missingSort(columnId)
        # when 'unposted' # TODO: in a future milestone, unposted will be added

    sortByAssignmentGroupColumn: (columnId, settingKey, direction) =>
      if settingKey == 'grade'
        @sortRowsBy((a, b) => @gradeSort(a, b, columnId, direction == 'ascending'))

    sortByTotalGradeColumn: (direction) =>
      @sortRowsBy((a, b) => @gradeSort(a, b, 'total_grade', direction == 'ascending'))

    sortGridRows: =>
      { columnId, settingKey, direction } = @getSortRowsBySetting()
      columnType = @getColumnTypeForColumnId(columnId)

      switch columnType
        when 'custom_column' then @sortByCustomColumn(columnId, direction)
        when 'assignment' then @sortByAssignmentColumn(columnId, settingKey, direction)
        when 'assignment_group' then @sortByAssignmentGroupColumn(columnId, settingKey, direction)
        when 'total_grade' then @sortByTotalGradeColumn(direction)
        else @sortByStudentColumn(settingKey, direction)

      @updateColumnHeaders()

    # Filtered Content Information Methods

    updateFilteredContentInfo: =>
      unorderedAssignments = (assignment for assignmentId, assignment of @assignments)
      filteredAssignments = @filterAssignments(unorderedAssignments)

      @filteredContentInfo.mutedAssignments = filteredAssignments.filter((assignment) => assignment.muted)
      @filteredContentInfo.totalPointsPossible = _.reduce @assignmentGroups,
        (sum, assignmentGroup) -> sum + getAssignmentGroupPointsPossible(assignmentGroup),
        0

      if @weightedGroups()
        invalidAssignmentGroups = _.filter @assignmentGroups, (ag) ->
          getAssignmentGroupPointsPossible(ag) == 0
        @filteredContentInfo.invalidAssignmentGroups = invalidAssignmentGroups
      else
        @filteredContentInfo.invalidAssignmentGroups = []

    listInvalidAssignmentGroups: =>
      @filteredContentInfo.invalidAssignmentGroups

    listMutedAssignments: =>
      @filteredContentInfo.mutedAssignments

    getTotalPointsPossible: =>
      @filteredContentInfo.totalPointsPossible

    handleColumnHeaderMenuClose: =>
      @keyboardNav.handleMenuOrDialogClose()

    toggleNotesColumn: =>
      parentColumnIds = @gradebookGrid.columns.frozen.filter((columnId) -> !/^custom_col_/.test(columnId))
      customColumnIds = @listVisibleCustomColumns().map((column) => @getCustomColumnId(column.id))

      @gradebookGrid.columns.frozen = [parentColumnIds..., customColumnIds...]

      @updateGrid()

    showNotesColumn: =>
      if @teacherNotesNotYetLoaded
        @teacherNotesNotYetLoaded = false
        DataLoader.getDataForColumn(@getTeacherNotesColumn(), @options.custom_column_data_url, {}, @gotCustomColumnDataChunk)

      @getTeacherNotesColumn()?.hidden = false
      @toggleNotesColumn()

    hideNotesColumn: =>
      @getTeacherNotesColumn()?.hidden = true
      @toggleNotesColumn()

    hideAggregateColumns: ->
      return false unless @gradingPeriodSet?
      return false if @gradingPeriodSet.displayTotalsForAllGradingPeriods
      not @isFilteringColumnsByGradingPeriod()

    fieldsToExcludeFromAssignments: ['description', 'needs_grading_count', 'in_closed_grading_period']
    fieldsToIncludeWithAssignments: ['module_ids', 'assignment_group_id']

    studentsParams: ->
      enrollmentStates = ['invited', 'active']

      if @getEnrollmentFilters().concluded
        enrollmentStates.push('completed')
      if @getEnrollmentFilters().inactive
        enrollmentStates.push('inactive')

      { enrollment_state: enrollmentStates }

    ## Grid DOM Access/Reference Methods

    getCustomColumnId: (customColumnId) =>
      "custom_col_#{customColumnId}"

    getAssignmentColumnId: (assignmentId) =>
      "assignment_#{assignmentId}"

    getAssignmentGroupColumnId: (assignmentGroupId) =>
      "assignment_group_#{assignmentGroupId}"

    ## SlickGrid Data Access Methods

    listRows: =>
      @rows # currently the source of truth for filtered and sorted rows

    listRowIndicesForStudentIds: (studentIds) =>
      rowIndicesByStudentId = @listRows().reduce((map, row, index) =>
        map[row.id] = index
        map
      , {})
      studentIds.map (studentId) => rowIndicesByStudentId[studentId]

    ## SlickGrid Update Methods

    updateRowCellsForStudentIds: (studentIds) =>
      return unless @grid

      # Update each row without entirely replacing the DOM elements.
      # This is needed to preserve the editor for the active cell, when present.
      rowIndices = @listRowIndicesForStudentIds(studentIds)
      columns = @grid.getColumns()
      for rowIndex in rowIndices
        for column, columnIndex in columns
          @grid.updateCell(rowIndex, columnIndex)

      null # skip building an unused array return value

    invalidateRowsForStudentIds: (studentIds) =>
      return unless @grid

      rowIndices = @listRowIndicesForStudentIds(studentIds)
      for rowIndex in rowIndices
        @grid.invalidateRow(rowIndex)

      @grid.render()

      null # skip building an unused array return value

    ## Gradebook Bulk UI Update Methods

    updateColumnsAndRenderViewOptionsMenu: =>
      @setVisibleGridColumns()
      @grid.setColumns(@getVisibleGradeGridColumns())
      @updateColumnHeaders()
      @renderViewOptionsMenu()

    ## React Header Component Ref Methods

    setHeaderComponentRef: (columnId, ref) =>
      @headerComponentRefs[columnId] = ref

    getHeaderComponentRef: (columnId) =>
      @headerComponentRefs[columnId]

    removeHeaderComponentRef: (columnId) =>
      delete @headerComponentRefs[columnId]

    ## React Grid Component Rendering Methods

    updateColumnHeaders: ->
      @gridSupport?.columns.updateColumnHeaders()

    # Column Header Helpers
    handleHeaderKeyDown: (e, columnId) =>
      @gridSupport.navigation.handleHeaderKeyDown e,
        region: 'header'
        cell: @grid.getColumnIndex(columnId)
        columnId: columnId

    # Total Grade Column Header

    freezeTotalGradeColumn: =>
      @totalColumnPositionChanged = true

      studentColumnPosition = @gradebookGrid.columns.frozen.indexOf('student')
      @gradebookGrid.columns.frozen.splice(studentColumnPosition + 1, 0, 'total_grade')
      @gradebookGrid.columns.scrollable = @gradebookGrid.columns.scrollable.filter((columnId) -> columnId != 'total_grade')

      @updateGrid()
      @updateColumnHeaders()

    moveTotalGradeColumnToEnd: =>
      @totalColumnPositionChanged = true

      @gradebookGrid.columns.frozen = @gradebookGrid.columns.frozen.filter((columnId) -> columnId != 'total_grade')
      @gradebookGrid.columns.scrollable = @gradebookGrid.columns.scrollable.filter((columnId) -> columnId != 'total_grade')
      @gradebookGrid.columns.scrollable.push('total_grade')

      @updateGrid()
      @updateColumnHeaders()

    totalColumnShouldFocus: ->
      if @totalColumnPositionChanged
        @totalColumnPositionChanged = false
        true
      else
        false

    # Submission Tray

    assignmentColumns: =>
      @gridSupport.grid.getColumns().filter (column) =>
        column.type == 'assignment'

    navigateAssignment: (direction) =>
      location = @gridSupport.state.getActiveLocation()
      columns = @grid.getColumns()
      range = if direction == 'next'
        [location.cell + 1 .. columns.length]
      else
        [location.cell - 1 ... 0]
      assignment

      for i in range
        curAssignment = columns[i]

        if curAssignment.id.match(/^assignment_(?!group)/)
          this.gridSupport.state.setActiveLocation('body', { row: location.row, cell: i })
          assignment = curAssignment
          break

      assignment

    loadTrayAssignment: (direction) =>
      studentId = @getSubmissionTrayState().studentId
      assignment = @navigateAssignment(direction)

      return unless assignment

      @setSubmissionTrayState(true, studentId, assignment.assignmentId)
      @updateRowAndRenderSubmissionTray(studentId)

    renderSubmissionTray: (student) =>
      mountPoint = document.getElementById('StudentTray__Container')
      { open, studentId, assignmentId } = @getSubmissionTrayState()
      # get the student's submission, or use a fake submission object in case the
      # submission has not yet loaded
      fakeSubmission = { assignment_id: assignmentId, late: false, missing: false, excused: false, seconds_late: 0 }
      submission = @getSubmission(studentId, assignmentId) || fakeSubmission
      assignment = @getAssignment(assignmentId)
      activeLocation = @gridSupport.state.getActiveLocation()
      cell = activeLocation.cell

      columns = @gridSupport.grid.getColumns()
      currentColumn = columns[cell]

      assignmentColumns = @assignmentColumns()
      currentIndex = assignmentColumns.indexOf(currentColumn)

      isFirstAssignment = currentIndex == 0
      isLastAssignment = currentIndex == assignmentColumns.length - 1

      props =
        key: "grade_details_tray"
        colors: @getGridColors()
        isOpen: open
        latePolicy: @courseContent.latePolicy
        locale: @options.locale
        onRequestClose: @closeSubmissionTray
        onClose: => @gridSupport.helper.focus()
        showContentComingSoon: !@options.new_gradebook_development_enabled
        student:
          id: student.id,
          name: student.name,
          avatarUrl: htmlDecode(student.avatar_url)
        assignment: ConvertCase.camelize(assignment)
        submission: ConvertCase.camelize(submission)
        isFirstAssignment: isFirstAssignment
        isLastAssignment: isLastAssignment
        selectNextAssignment: => @loadTrayAssignment('next')
        selectPreviousAssignment: => @loadTrayAssignment('previous')
        courseId: @options.context_id
        speedGraderEnabled: @options.speed_grader_enabled
        submissionUpdating: @contentLoadStates.submissionUpdating
        updateSubmission: @updateSubmissionAndRenderSubmissionTray
      renderComponent(SubmissionTray, mountPoint, props)

    updateRowAndRenderSubmissionTray: (studentId) =>
      @updateRowCellsForStudentIds([studentId])
      @renderSubmissionTray(@student(studentId))

    toggleSubmissionTrayOpen: (studentId, assignmentId) =>
      @setSubmissionTrayState(!@getSubmissionTrayState().open, studentId, assignmentId)
      @updateRowAndRenderSubmissionTray(studentId)

    openSubmissionTray: (studentId, assignmentId) =>
      @setSubmissionTrayState(true, studentId, assignmentId)
      @updateRowAndRenderSubmissionTray(studentId)

    closeSubmissionTray: =>
      @setSubmissionTrayState(false)
      rowIndex = @grid.getActiveCell().row
      studentId = @rows[rowIndex].id
      @updateRowAndRenderSubmissionTray(studentId)

    getSubmissionTrayState: =>
      @gridDisplaySettings.submissionTray

    setSubmissionTrayState: (open, studentId, assignmentId) =>
      @gridDisplaySettings.submissionTray.open = open
      @gridDisplaySettings.submissionTray.studentId = studentId if studentId
      @gridDisplaySettings.submissionTray.assignmentId = assignmentId if assignmentId
      @gridSupport.helper.commitCurrentEdit() if open

    ## Gradebook Application State

    defaultSortType: 'assignment_group'

    ## Gradebook Application State Methods

    initShowUnpublishedAssignments: (show_unpublished_assignments = 'true') =>
      @showUnpublishedAssignments = show_unpublished_assignments == 'true'

    toggleUnpublishedAssignments: =>
      @showUnpublishedAssignments = !@showUnpublishedAssignments
      @updateColumnsAndRenderViewOptionsMenu()

      @saveSettings(
        { @showUnpublishedAssignments },
        () =>, # on success, do nothing since the render happened earlier
        () => # on failure, undo
          @showUnpublishedAssignments = !@showUnpublishedAssignments
          @updateColumnsAndRenderViewOptionsMenu()
      )

    setAssignmentsLoaded: (loaded) =>
      @contentLoadStates.assignmentsLoaded = loaded

    setStudentsLoaded: (loaded) =>
      @contentLoadStates.studentsLoaded = loaded

    setSubmissionsLoaded: (loaded) =>
      @contentLoadStates.submissionsLoaded = loaded

    setSubmissionUpdating: (loaded) =>
      @contentLoadStates.submissionUpdating = loaded

    setTeacherNotesColumnUpdating: (updating) =>
      @contentLoadStates.teacherNotesColumnUpdating = updating

    ## Grid Display Settings Access Methods

    getFilterColumnsBySetting: (filterKey) =>
      @gridDisplaySettings.filterColumnsBy[filterKey]

    setFilterColumnsBySetting: (filterKey, value) =>
      @gridDisplaySettings.filterColumnsBy[filterKey] = value

    getFilterRowsBySetting: (filterKey) =>
      @gridDisplaySettings.filterRowsBy[filterKey]

    setFilterRowsBySetting: (filterKey, value) =>
      @gridDisplaySettings.filterRowsBy[filterKey] = value

    isFilteringColumnsByAssignmentGroup: =>
      @getAssignmentGroupToShow() != '0'

    getAssignmentGroupToShow: () =>
      groupId = @getFilterColumnsBySetting('assignmentGroupId') || '0'
      if groupId in _.pluck(@assignmentGroups, 'id') then groupId else '0'

    isFilteringColumnsByGradingPeriod: =>
      @getGradingPeriodToShow() != '0'

    isFilteringRowsBySearchTerm: =>
      @userFilterTerm? and @userFilterTerm != ''

    getGradingPeriodToShow: () =>
      return '0' unless @gradingPeriodSet?
      periodId = @getFilterColumnsBySetting('gradingPeriodId') || @options.current_grading_period_id
      if periodId in _.pluck(@gradingPeriodSet.gradingPeriods, 'id') then periodId else '0'

    getGradingPeriod: (gradingPeriodId) =>
      (@gradingPeriodSet?.gradingPeriods || []).find((gradingPeriod) => gradingPeriod.id == gradingPeriodId)

    setSelectedPrimaryInfo: (primaryInfo, skipRedraw) =>
      @gridDisplaySettings.selectedPrimaryInfo = primaryInfo
      @saveSettings()
      unless skipRedraw
        @buildRows()
        @gridSupport.columns.updateColumnHeaders(['student'])

    toggleDefaultSort: (columnId) =>
      sortSettings = @getSortRowsBySetting()
      columnType = @getColumnTypeForColumnId(columnId)
      settingKey = @getDefaultSettingKeyForColumnType(columnType)
      direction = 'ascending'

      if sortSettings.columnId == columnId && sortSettings.settingKey == settingKey && sortSettings.direction == 'ascending'
        direction = 'descending'

      @setSortRowsBySetting(columnId, settingKey, direction)

    getDefaultSettingKeyForColumnType: (columnType) =>
      if columnType == 'assignment' || columnType == 'assignment_group' || columnType == 'total_grade'
        return 'grade'
      else if columnType == 'student'
        return 'sortable_name'

    getSelectedPrimaryInfo: () =>
      @gridDisplaySettings.selectedPrimaryInfo

    setSelectedSecondaryInfo: (secondaryInfo, skipRedraw) =>
      @gridDisplaySettings.selectedSecondaryInfo = secondaryInfo
      @saveSettings()
      unless skipRedraw
        @buildRows()
        @gridSupport.columns.updateColumnHeaders(['student'])

    getSelectedSecondaryInfo: () =>
      @gridDisplaySettings.selectedSecondaryInfo

    setSortRowsBySetting: (columnId, settingKey, direction) =>
      @gridDisplaySettings.sortRowsBy.columnId = columnId
      @gridDisplaySettings.sortRowsBy.settingKey = settingKey
      @gridDisplaySettings.sortRowsBy.direction = direction
      @saveSettings()
      @sortGridRows()

    getSortRowsBySetting: =>
      @gridDisplaySettings.sortRowsBy

    updateGridColors: (colors, successFn, errorFn) =>
      setAndRenderColors = =>
        @setGridColors(colors)
        @renderGridColor()
        successFn()

      @saveSettings({ colors }, setAndRenderColors, errorFn)

    setGridColors: (colors) =>
      @gridDisplaySettings.colors = colors

    getGridColors: =>
      statusColors @gridDisplaySettings.colors

    listAvailableViewOptionsFilters: =>
      filters = []
      filters.push('assignmentGroups') if Object.keys(@assignmentGroups || {}).length > 1
      filters.push('gradingPeriods') if @gradingPeriodSet?
      filters.push('modules') if @listContextModules().length > 0
      filters.push('sections') if @sections_enabled
      filters

    setSelectedViewOptionsFilters: (filters) =>
      @gridDisplaySettings.selectedViewOptionsFilters = filters

    listSelectedViewOptionsFilters: =>
      @gridDisplaySettings.selectedViewOptionsFilters

    toggleEnrollmentFilter: (enrollmentFilter, skipApply) =>
      @getEnrollmentFilters()[enrollmentFilter] = !@getEnrollmentFilters()[enrollmentFilter]
      @applyEnrollmentFilter() unless skipApply

    applyEnrollmentFilter: () =>
      showInactive = @getEnrollmentFilters().inactive
      showConcluded = @getEnrollmentFilters().concluded
      @saveSettings({ showInactive, showConcluded }, =>
        @gridSupport.columns.updateColumnHeaders(['student'])
        @reloadStudentData()
      )

    getEnrollmentFilters: () =>
      @gridDisplaySettings.showEnrollments

    getSelectedEnrollmentFilters: () =>
      filters = @getEnrollmentFilters()
      selectedFilters = []
      for filter of filters
        selectedFilters.push filter if filters[filter]
      selectedFilters

    ## Gradebook Content Access Methods

    setSections: (sections) =>
      @sections = _.indexBy(sections, 'id')
      @sections_enabled = sections.length > 1

    setAssignments: (assignmentMap) =>
      @assignments = assignmentMap

    setAssignmentGroups: (assignmentGroupMap) =>
      @assignmentGroups = assignmentGroupMap

    getAssignment: (assignmentId) =>
      @assignments[assignmentId]

    getAssignmentGroup: (assignmentGroupId) =>
      @assignmentGroups[assignmentGroupId]

    getCustomColumn: (customColumnId) =>
      @gradebookContent.customColumns.find((column) -> column.id == customColumnId)

    getTeacherNotesColumn: =>
      @gradebookContent.customColumns.find((column) -> column.teacher_notes)

    listVisibleCustomColumns: ->
      @gradebookContent.customColumns.filter((column) -> !column.hidden)

    setContextModules: (contextModules) =>
      @courseContent.contextModules = contextModules
      @courseContent.modulesById = {}

      if contextModules?.length
        for contextModule in contextModules
          @courseContent.modulesById[contextModule.id] = contextModule

      contextModules

    onLatePolicyUpdate: (latePolicy) =>
      @setLatePolicy(latePolicy)
      @applyLatePolicy()

    setLatePolicy: (latePolicy) =>
      @courseContent.latePolicy = latePolicy

    applyLatePolicy: =>
      latePolicy = @courseContent?.latePolicy
      gradingStandard = @options.grading_standard || @options.default_grading_standard
      studentsToInvalidate = {}

      forEachSubmission(@students, (submission) =>
        assignment = @assignments[submission.assignment_id]
        return if @getGradingPeriod(submission.grading_period_id)?.isClosed
        if LatePolicyApplicator.processSubmission(submission, assignment, gradingStandard, latePolicy)
          studentsToInvalidate[submission.user_id] = true
      )
      studentIds = _.uniq(Object.keys(studentsToInvalidate))
      studentIds.forEach (studentId) =>
        @calculateStudentGrade(@students[studentId])
      @invalidateRowsForStudentIds(studentIds)

    getContextModule: (contextModuleId) =>
      @courseContent.modulesById?[contextModuleId] if contextModuleId?

    listContextModules: =>
      @courseContent.contextModules

    ## Assignment UI Action Methods

    getDownloadSubmissionsAction: (assignmentId) =>
      assignment = @getAssignment(assignmentId)
      manager = new DownloadSubmissionsDialogManager(
        assignment,
        @options.download_assignment_submissions_url,
        @handleSubmissionsDownloading
      )

      {
        hidden: !manager.isDialogEnabled()
        onSelect: manager.showDialog
      }

    getReuploadSubmissionsAction: (assignmentId) =>
      assignment = @getAssignment(assignmentId)
      manager = new ReuploadSubmissionsDialogManager(
        assignment,
        @options.re_upload_submissions_url
      )

      {
        hidden: !manager.isDialogEnabled()
        onSelect: manager.showDialog
      }

    getSetDefaultGradeAction: (assignmentId) =>
      assignment = @getAssignment(assignmentId)
      manager = new SetDefaultGradeDialogManager(
        assignment,
        @studentsThatCanSeeAssignment(assignmentId),
        @options.context_id,
        @getFilterRowsBySetting('sectionId'),
        isAdmin(),
        @contentLoadStates.submissionsLoaded
      )

      {
        disabled: !manager.isDialogEnabled()
        onSelect: manager.showDialog
      }

    getCurveGradesAction: (assignmentId) =>
      assignment = @getAssignment(assignmentId)
      CurveGradesDialogManager.createCurveGradesAction(
        assignment,
        @studentsThatCanSeeAssignment(assignmentId),
        {
          isAdmin: isAdmin()
          contextUrl: @options.context_url
          submissionsLoaded: @contentLoadStates.submissionsLoaded
        }
      )

    getMuteAssignmentAction: (assignmentId) =>
      assignment = @getAssignment(assignmentId)
      manager = new AssignmentMuterDialogManager(
        assignment,
        "#{@options.context_url}/assignments/#{assignmentId}/mute",
        @contentLoadStates.submissionsLoaded
      )

      {
        disabled: !manager.isDialogEnabled()
        onSelect: manager.showDialog
      }

    ## Gradebook Content Api Methods

    createTeacherNotes: =>
      @setTeacherNotesColumnUpdating(true)
      @renderViewOptionsMenu()
      GradebookApi.createTeacherNotesColumn(@options.context_id)
        .then (response) =>
          @gradebookContent.customColumns.push(response.data)
          teacherNotesColumn = @buildCustomColumn(response.data)
          @gradebookGrid.columns.definitions[teacherNotesColumn.id] = teacherNotesColumn
          @showNotesColumn()
          @setTeacherNotesColumnUpdating(false)
          @renderViewOptionsMenu()
        .catch (error) =>
          $.flashError I18n.t('There was a problem creating the teacher notes column.')
          @setTeacherNotesColumnUpdating(false)
          @renderViewOptionsMenu()

    setTeacherNotesHidden: (hidden) =>
      @setTeacherNotesColumnUpdating(true)
      @renderViewOptionsMenu()
      teacherNotes = @getTeacherNotesColumn()
      GradebookApi.updateTeacherNotesColumn(@options.context_id, teacherNotes.id, { hidden })
        .then =>
          if hidden
            @hideNotesColumn()
          else
            @showNotesColumn()
            @reorderCustomColumns(@gradebookContent.customColumns.map (c) -> c.id)
          @setTeacherNotesColumnUpdating(false)
          @renderViewOptionsMenu()
        .catch (error) =>
          if hidden
            $.flashError I18n.t('There was a problem hiding the teacher notes column.')
          else
            $.flashError I18n.t('There was a problem showing the teacher notes column.')
          @setTeacherNotesColumnUpdating(false)
          @renderViewOptionsMenu()

    updateSubmissionAndRenderSubmissionTray: (data) =>
      { studentId, assignmentId } = @getSubmissionTrayState()
      student = @student(studentId)
      @setSubmissionUpdating(true)
      @renderSubmissionTray(student)
      GradebookApi.updateSubmission(@options.context_id, assignmentId, studentId, data)
        .then((response) =>
          @setSubmissionUpdating(false)
          @updateSubmissionsFromExternal(response.data.all_submissions)
          @renderSubmissionTray(student)
        ).catch(=>
          @setSubmissionUpdating(false)
          $.flashError I18n.t('There was a problem updating the submission.')
          @renderSubmissionTray(student)
        )
