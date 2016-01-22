define([
  'react',
  'underscore',
  '../components/gridCell',
  '../components/column_types/studentNameColumn',
  '../components/column_types/notesColumn',
  '../components/column_types/assignmentPercentage',
  '../components/column_types/assignmentPassFail',
  '../components/column_types/assignmentLetterGrade',
  '../components/column_types/assignmentPoints',
  '../components/column_types/totalColumn',
  '../components/column_types/assignmentGroupColumn',
  '../components/column_types/customColumn',
  'i18n!gradebook',
  '../constants'
], function(
  React,
  _,
  GridCell,
  StudentNameColumn,
  NotesColumn,
  AssignmentPercentColumn,
  AssignmentPassFailColumn,
  AssignmentLetterGradeColumn,
  AssignmentPointsColumn,
  TotalColumn,
  AssignmentGroupColumn,
  CustomColumn,
  I18n,
  GradebookConstants
) {

  var cellIndex = 0;

  var renderers = {};
  renderers[GradebookConstants.STUDENT_COLUMN_ID]          = StudentNameColumn;
  renderers[GradebookConstants.NOTES_COLUMN_ID]            = NotesColumn;
  renderers[GradebookConstants.PERCENT_COLUMN_ID]          = AssignmentPercentColumn;
  renderers[GradebookConstants.PASS_FAIL_COLUMN_ID]        = AssignmentPassFailColumn;
  renderers[GradebookConstants.GPA_SCALE_COLUMN_ID]        = AssignmentLetterGradeColumn;
  renderers[GradebookConstants.LETTER_GRADE_COLUMN_ID]     = AssignmentLetterGradeColumn;
  renderers[GradebookConstants.POINTS_COLUMN_ID]           = AssignmentPointsColumn;
  renderers[GradebookConstants.TOTAL_COLUMN_ID]            = TotalColumn;
  renderers[GradebookConstants.ASSIGNMENT_GROUP_COLUMN_ID] = AssignmentGroupColumn;
  renderers[GradebookConstants.CUSTOM_COLUMN_ID]           = CustomColumn;

  function getRenderer (cellData, cellDataKey, rowData, rowIndex, columnData) {
    var Renderer = renderers[columnData.columnType];

    if (Renderer) {
      var key = columnData.columnType + cellDataKey;
      return (<GridCell
                cellIndex={cellIndex++}
                activeCell={columnData.activeCell}
                setActiveCell={columnData.setActiveCell}
                columnData={columnData}
                renderer={Renderer}
                cellData={cellData}
                rowData={rowData}
                key={key}/>);
    } else {
      var message = 'Cell Renderer Not Registered. ' +
        'Register "' + columnData.columnType +
        '" in the renderers Object (columnRenderer.jsx)';

      throw new Error(message);
    }
  }

  return {getRenderer: getRenderer};
});
