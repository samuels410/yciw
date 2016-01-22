define([
  'underscore',
  'react',
  './actions/ModerationActions',
  './constants',
  'i18n!moderated_grading'
], function (_, React, ModerationActions, Constants, I18n) {

  // CONSTANTS
  var PG_ONE_INDEX = 0;
  var PG_TWO_INDEX = 1;
  var PG_THREE_INDEX = 2;

  return React.createClass({
    displayName: 'ModeratedStudentList',

    propTypes: {
      studentList: React.PropTypes.object.isRequired,
      assignment: React.PropTypes.object.isRequired,
      handleCheckbox: React.PropTypes.func.isRequired,
      includeModerationSetColumns: React.PropTypes.bool,
      urls: React.PropTypes.object.isRequired,
      onSelectProvisionalGrade: React.PropTypes.func.isRequired
    },

    generateSpeedgraderUrl (baseSpeedgraderUrl, student) {
      var encoded = window.encodeURI(`{"student_id":${student.id},"add_review":true}`);
      return (`${baseSpeedgraderUrl}#${encoded}`);
    },

    isProvisionalGradeChecked (provisionalGradeId, student) {
      return student.selected_provisional_grade_id === provisionalGradeId
    },

    renderStudentMark (student, markIndex) {
      // Set up previousIndex reference
      var previousMarkIndex = 0;

      if (markIndex > 0) {
        previousMarkIndex = markIndex - 1;
      }

      if (student.provisional_grades && student.provisional_grades[markIndex]) {
        if (this.props.includeModerationSetColumns) {
          var provisionalGradeId = student.provisional_grades[markIndex].provisional_grade_id;
          return (
            <div className='col-xs-2' role="gridcell">
              <div className='ModeratedAssignmentList__Mark'>
                <input
                  type='radio'
                  name={`mark_${student.id}`}
                  disabled={this.props.assignment.published}
                  onChange={this.props.onSelectProvisionalGrade.bind(this, provisionalGradeId)}
                  checked={this.isProvisionalGradeChecked(provisionalGradeId, student)}
                />
                  <a target='_blank' href={student.provisional_grades[markIndex].speedgrader_url}>
                    <span className='screenreader-only'>{I18n.t('Score of %{score}. View in SpeedGrader', {score: student.provisional_grades[markIndex].score})}</span>
                    <span aria-hidden='true'>{student.provisional_grades[markIndex].score}</span>
                  </a>
              </div>
            </div>
          );
        } else {
          return (
            <div className='col-xs-2' role="gridcell">
              <div className='AssignmentList__Mark'>
                <a target='_blank' href={student.provisional_grades[markIndex].speedgrader_url}>
                  <span className='screenreader-only'>{I18n.t('Score of %{score}. View in SpeedGrader', {score: student.provisional_grades[markIndex].score})}</span>
                  <span aria-hidden='true'>{student.provisional_grades[markIndex].score}</span>
                </a>
              </div>
            </div>
          );
        }
      } else {
          if (student.in_moderation_set && (student.provisional_grades[previousMarkIndex] || markIndex == 0)) {
            return (
              <div className='col-xs-2' role="gridcell">
                <div className='ModeratedAssignmentList__Mark'>
                  <a target='_blank' href={this.generateSpeedgraderUrl(this.props.urls.assignment_speedgrader_url, student)}>
                    <span className='screenreader-only'>{I18n.t('View in SpeedGrader')}</span>
                    <span aria-hidden='true'>{I18n.t('SpeedGrader™')}</span>
                  </a>
                </div>
              </div>
            );
          } else {
            return (
              <div className='col-xs-2' role="gridcell">
                <div className='AssignmentList__Mark'>
                  <span className='screenreader-only'>{I18n.t('No grade assigned.')}</span>
                  <span aria-hidden='true'>-</span>
                </div>
              </div>
            );
          }
      }
    },

    renderFinalGrade (student) {
      if (student.selected_provisional_grade_id) {
        var grade = _.find(student.provisional_grades, (pg) => {
          return pg.provisional_grade_id === student.selected_provisional_grade_id;
        });
        return (
          <div className='col-xs-2' role="gridcell">
            <div className='AssignmentList_Grade'>
              <span className='screenreader-only'>{I18n.t('Final grade: %{score}', {score: (grade.score || I18n.t('Not available'))})}</span>
              <span aria-hidden='true'>{grade.score}</span>
            </div>
          </div>
        );
      } else {
        return (
          <div className='col-xs-2' role="gridcell">
            <div className='AssignmentList_Grade'>
              <span className='screenreader-only'>{I18n.t('No final grade selected')}</span>
              <span aria-hidden='true'>-</span>
            </div>
          </div>
        );
      }
    },
    render () {
      return (
        <ul className='ModeratedAssignmentList' role="presentation">
          {
            this.props.studentList.students.map((student) => {
              if (this.props.includeModerationSetColumns) {
                return (
                  <li key={student.id} className='ModeratedAssignmentList__Item' role="presentation">
                    <div className='grid-row' role="row">
                      <div className='col-xs-4' role="rowheader">
                        <div className='ModeratedAssignmentList__StudentInfo'>
                          <label>
                            <input
                              checked={student.on_moderation_stage || student.in_moderation_set || student.isChecked}
                              disabled={student.in_moderation_set || this.props.assignment.published}
                              type='checkbox'
                              onChange={this.props.handleCheckbox.bind(null, student)}
                            />
                            <img className='img-circle AssignmentList_StudentPhoto' alt='' src={student.avatar_image_url} />
                            <span>{student.display_name}</span>
                          </label>
                        </div>
                      </div>
                      {this.renderStudentMark(student, PG_ONE_INDEX)}
                      {this.renderStudentMark(student, PG_TWO_INDEX)}
                      {this.renderStudentMark(student, PG_THREE_INDEX)}
                      {this.renderFinalGrade(student)}
                    </div>
                  </li>
                 );
              } else {
                return (
                  <li key={student.id} className='AssignmentList__Item' role="presentation">
                    <div className='grid-row' role="row">
                      <div className='col-xs-4' role="rowheader">
                        <div className='AssignmentList__StudentInfo'>
                          <label>
                            <input
                              checked={student.on_moderation_stage || student.in_moderation_set || student.isChecked}
                              disabled={student.in_moderation_set || this.props.assignment.published}
                              type='checkbox'
                              onChange={this.props.handleCheckbox.bind(null, student)}
                            />
                            <img className='img-circle AssignmentList_StudentPhoto' alt='' src={student.avatar_image_url} />
                            <span>{student.display_name}</span>
                          </label>
                        </div>
                      </div>
                      {this.renderStudentMark(student, PG_ONE_INDEX)}
                    </div>
                  </li>
                );
              }
            })
          }
        </ul>
      );
    }
  });

});
