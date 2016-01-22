define([
  'react',
  'underscore',
  'i18n!gradebook',
  'jsx/gradebook/grid/constants',
  'jsx/gradebook/grid/components/dropdown_components/gradebookKyleMenu',
  'jquery',
  'jsx/gradebook/grid/components/dropdown_components/assignmentHeaderDropdownOptions',
  'jsx/gradebook/grid/components/dropdown_components/totalHeaderDropdownOptions',
  'jquery.instructure_date_and_time'
], function(React, _, I18n, GradebookConstants, GradebookKyleMenu, $, AssignmentHeaderDropdownOptions, TotalHeaderDropdownOptions) {

  var HeaderRenderer = React.createClass({
    propTypes: {
      label: React.PropTypes.string.isRequired,
      columnData: React.PropTypes.object.isRequired
    },

    prettyDate(date) {
      return $.dateString(date, { localized: true });
    },

    getHeaderDateFromOverrides(overrides) {
      var overrideWithDueAt;

      if (overrides.length > 1) { return I18n.t('Multiple due dates'); }
      overrideWithDueAt = _.find(overrides, override => override.due_at);
      if (overrideWithDueAt) {
        return I18n.t('Due %{dueAt}', { dueAt: this.prettyDate(overrideWithDueAt.due_at) });
      } else {
        return I18n.t('No due date');
      }
    },

    headerDate(columnData) {
      var assignment, dateContent;

      assignment = columnData.assignment;

      if (!assignment) {
        dateContent = undefined;
      } else if (assignment.due_at) {
        dateContent = I18n.t('Due %{dueAt}', { dueAt: this.prettyDate(assignment.due_at) });
      } else if (assignment.overrides) {
        dateContent = this.getHeaderDateFromOverrides(assignment.overrides);
      } else {
        dateContent = I18n.t('No due date');
      }

      return dateContent;
    },

    shouldDisplayAssignmentWarning() {
      var assignment = this.props.columnData.assignment;
      return assignment.shouldShowNoPointsWarning
             && GradebookConstants.group_weighting_scheme === 'percent';
    },

    getTitle() {
      if (this.shouldDisplayAssignmentWarning()) {
        return I18n.t('Assignments in this group have no points possible and cannot be included in grade calculation');
      }
    },

    getWidth() {
      var paddingAdjustment = GradebookConstants.DEFAULT_LAYOUTS.headers.paddingAdjustment;
      return this.props.width - paddingAdjustment;
    },

    label(columnData) {
      var assignment, label;

      assignment = columnData.assignment;
      label = this.props.label;

      if (assignment) {
        var className = 'assignment-name' + ((assignment.muted) ? ' muted' : '');
        return (
          <div title={label} className='gradebook-label' style={{width: this.getWidth()}}>
            <a className={className} href={assignment.html_url}>
              { this.shouldDisplayAssignmentWarning() && <i ref='icon' title={this.getTitle()} className='icon-warning'></i> }
              {label}
            </a>
          </div>
        );
      } else {
        return (
          <div title={label} className='gradebook-label' style={{width: this.getWidth()}}>
            {label}
          </div>
        );
      }

      return label;
    },

    renderDropdown(columnData) {
      let columnType  = columnData.columnType,
        assignment  = columnData.assignment,
        enrollments = columnData.enrollments,
        submissions = columnData.submissions,
        key, dropdownOptionsId;

      if (assignment) {
        key = 'assignment-' + assignment.id;
        dropdownOptionsId = key + '-options';
        return (
          <GradebookKyleMenu key={key} dropdownOptionsId={dropdownOptionsId}
            idToAppendTo='gradebook_grid' screenreaderText={I18n.t('Assignment Options')}
            defaultClassNames='gradebook-header-drop' options={{ noButton: true }}>

            <AssignmentHeaderDropdownOptions key={dropdownOptionsId}
              idAttribute={dropdownOptionsId} assignment={assignment}
              enrollments={enrollments} submissions={submissions}/>
          </GradebookKyleMenu>
        );
      } else if (columnType === 'total') {
        return (
          <GradebookKyleMenu key='total' dropdownOptionsId='total-options'
            idToAppendTo='gradebook_grid' screenreaderText={I18n.t('Total Column Options')}
            defaultClassNames='gradebook-header-drop' options={{ noButton: true }}>
            <TotalHeaderDropdownOptions key='total-options' idAttribute='total-options'/>
          </GradebookKyleMenu>
        );
      }
    },

    render() {
      let columnData = this.props.columnData,
        dueDate    = this.headerDate(columnData),
        className  = (dueDate) ? '' : ' title';

      return (
        <div style={{width: this.getWidth()}}
             title={this.props.label}
             className={'gradebook-label gradebook-header-column' + className}>
          {this.label(columnData)}
          {this.renderDropdown(columnData)}
          <div title={dueDate} className='assignment-due-date' ref='dueDate'>
            {dueDate}
          </div>
        </div>
      );
    }
  });

  return HeaderRenderer;
});
