define [
  'i18n!gradebook2'
  'jquery'
  'message_students'
  'compiled/AssignmentDetailsDialog'
  'compiled/AssignmentMuter'
  'compiled/gradebook2/SetDefaultGradeDialog'
  'compiled/gradebook2/CurveGradesDialog'
  'jst/gradebook2/GradebookHeaderMenu'
  'jst/re_upload_submissions_form'
  'underscore'
  'compiled/behaviors/authenticity_token'
  'jsx/gradebook/grid/helpers/messageStudentsWhoHelper'
  'jquery.instructure_forms'
  'jqueryui/dialog'
  'jquery.instructure_misc_helpers'
  'jquery.instructure_misc_plugins'
  'compiled/jquery.kylemenu'
], (I18n, $, messageStudents, AssignmentDetailsDialog, AssignmentMuter, SetDefaultGradeDialog, CurveGradesDialog, gradebookHeaderMenuTemplate, re_upload_submissions_form, _, authenticity_token, MessageStudentsWhoHelper) ->

  class GradebookHeaderMenu
    constructor: (@assignment, @$trigger, @gradebook) ->
      templateLocals =
        assignmentUrl: "#{@gradebook.options.context_url}/assignments/#{@assignment.id}"
        speedGraderUrl: "#{@gradebook.options.context_url}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      templateLocals.speedGraderUrl = null unless @gradebook.options.speed_grader_enabled

      @gradebook.allSubmissionsLoaded.done =>
        @allSubmissionsLoaded = true

      @$menu = $(gradebookHeaderMenuTemplate(templateLocals)).insertAfter(@$trigger)
      @$trigger.kyleMenu(noButton:true)
      @$menu
        # need it to be a child of #gradebook_grid (not the header cell) to get over overflow:hidden obstacles.
        .appendTo('#gradebook_grid')
        .delegate('a', 'click', (event) =>
          action = @[$(event.target).data('action')]
          if action
            action()
            false
        )
        .bind('popupopen popupclose', (event) =>
          @$trigger.toggleClass 'ui-menu-trigger-menu-is-open', event.type == 'popupopen'

          if event.type == 'popupclose' and event.originalEvent? and event.originalEvent.type != 'focusout'
            #defer because there seems to make sure this occurs after all of the jquery ui events
            setTimeout((=>
              @gradebook.grid.editActiveCell()
            ), 0)
        )
        .bind('popupopen',  =>
          @$menu.find("[data-action=#{action}]").showIf(condition) for action, condition of {
            showAssignmentDetails: @allSubmissionsLoaded
            messageStudentsWho:    @allSubmissionsLoaded
            setDefaultGrade:       @allSubmissionsLoaded
            curveGrades:           @allSubmissionsLoaded && @assignment.grading_type != 'pass_fail' && @assignment.points_possible
            downloadSubmissions:   "#{@assignment.submission_types}".match(/(online_upload|online_text_entry|online_url)/) && @assignment.has_submitted_submissions
            reuploadSubmissions:   @gradebook.options.gradebook_is_editable && @assignment.submissions_downloads > 0
          }
        )
        .popup('open')

      new AssignmentMuter(@$menu.find("[data-action=toggleMuting]"),
        @assignment,
        "#{@gradebook.options.context_url}/assignments/#{@assignment.id}/mute",
        (a, _z, status) =>
          a.muted = status
          @gradebook.setAssignmentWarnings()
      )

    showAssignmentDetails: (opts={
      assignment:@assignment,
      students:@gradebook.studentsThatCanSeeAssignment(@gradebook.students, @assignment)
    })=>
      new AssignmentDetailsDialog(opts)

    messageStudentsWho: (opts={
      assignment:@assignment,
      students:@gradebook.studentsThatCanSeeAssignment(@gradebook.students, @assignment)
    }) =>
      {students, assignment} = opts
      students = _.map students, (student)=>
        sub = student["assignment_#{assignment.id}"]
        id: student.id
        name: student.name
        score: sub?.score
        submitted_at: sub?.submitted_at

      settings = MessageStudentsWhoHelper.settings(assignment, students)
      messageStudents(settings)

    setDefaultGrade: (opts={
      assignment:@assignment,
      students:@gradebook.studentsThatCanSeeAssignment(@gradebook.students, @assignment),
      context_id:@gradebook.options.context_id
      selected_section: @gradebook.sectionToShow
    }) =>
      new SetDefaultGradeDialog(opts)

    curveGrades: (opts={
      assignment:@assignment,
      students:@gradebook.studentsThatCanSeeAssignment(@gradebook.students, @assignment),
      context_url:@gradebook.options.context_url
    }) =>
      new CurveGradesDialog(opts)

    downloadSubmissions: =>
      url = $.replaceTags @gradebook.options.download_assignment_submissions_url, "assignment_id", @assignment.id
      INST.downloadSubmissions url
      @assignment.submissions_downloads = (@assignment.submissions_downloads ?= 0) + 1

    reuploadSubmissions: =>
      unless @$re_upload_submissions_form
        locals =
          authenticityToken: authenticity_token()

        GradebookHeaderMenu::$re_upload_submissions_form = $(re_upload_submissions_form(locals))
          .dialog
            width: 400
            modal: true
            resizable: false
            autoOpen: false
          .submit ->
            data = $(this).getFormData()
            if !data.submissions_zip
              false
            else if !data.submissions_zip.match(/\.zip$/)
              $(this).formErrors submissions_zip: I18n.t('errors.upload_as_zip', "Please upload files as a .zip")
              false
      url = $.replaceTags @gradebook.options.re_upload_submissions_url, "assignment_id", @assignment.id
      @$re_upload_submissions_form.attr('action', url).dialog('open')
