/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import {arrayOf, bool, func, instanceOf, number, shape, string} from 'prop-types'
import {IconMoreSolid, IconOffLine, IconOffSolid} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {Grid, GridCol, GridRow} from '@instructure/ui-layout'
import {Menu, MenuItem, MenuItemGroup, MenuItemSeparator} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-elements'
import 'message_students'
import I18n from 'i18n!gradezilla'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {isHidden} from '../../../../grading/helpers/SubmissionHelper'
import MessageStudentsWhoHelper from '../../../shared/helpers/messageStudentsWhoHelper'
import ColumnHeader from './ColumnHeader'

function SecondaryDetailLine(props) {
  const anonymous = props.assignment.anonymizeStudents
  const unpublished = !props.assignment.published

  if (anonymous || unpublished) {
    return (
      <span className="Gradebook__ColumnHeaderDetailLine Gradebook__ColumnHeaderDetail--secondary">
        <Text color="error" size="x-small" transform="uppercase" weight="bold">
          {unpublished ? I18n.t('Unpublished') : I18n.t('Anonymous')}
        </Text>
      </span>
    )
  }

  const pointsPossible = I18n.n(props.assignment.pointsPossible || 0)

  return (
    <span className="Gradebook__ColumnHeaderDetailLine Gradebook__ColumnHeaderDetail--secondary">
      <span className="assignment-points-possible">
        <Text weight="normal" fontStyle="normal" size="x-small">
          {I18n.t('Out of %{pointsPossible}', {pointsPossible})}
        </Text>
      </span>

      {!props.postPoliciesEnabled && props.assignment.muted && (
        <span>
          &nbsp;
          <Text size="x-small" transform="uppercase" weight="bold">
            {I18n.t('Muted')}
          </Text>
        </span>
      )}
    </span>
  )
}

SecondaryDetailLine.propTypes = {
  assignment: shape({
    anonymizeStudents: bool.isRequired,
    muted: bool.isRequired,
    pointsPossible: number,
    published: bool.isRequired
  }).isRequired,
  postPoliciesEnabled: bool.isRequired
}

function labelForPostGradesAction(postGradesAction) {
  if (!postGradesAction.hasGrades) {
    return I18n.t('No grades to post')
  } else if (postGradesAction.hasGradesToPost) {
    return I18n.t('Post grades')
  }

  return I18n.t('All grades posted')
}

function labelForHideGradesAction(hideGradesAction) {
  if (!hideGradesAction.hasGrades) {
    return I18n.t('No grades to hide')
  } else if (hideGradesAction.hasGradesToHide) {
    return I18n.t('Hide grades')
  }

  return I18n.t('All grades hidden')
}

export default class AssignmentColumnHeader extends ColumnHeader {
  static propTypes = {
    ...ColumnHeader.propTypes,

    assignment: shape({
      anonymizeStudents: bool.isRequired,
      courseId: string.isRequired,
      htmlUrl: string.isRequired,
      id: string.isRequired,
      muted: bool.isRequired,
      name: string.isRequired,
      pointsPossible: number,
      postManually: bool.isRequired,
      published: bool.isRequired,
      submissionTypes: arrayOf(string).isRequired
    }).isRequired,

    curveGradesAction: shape({
      isDisabled: bool.isRequired,
      onSelect: func.isRequired
    }).isRequired,

    hideGradesAction: shape({
      hasGradesToHide: bool.isRequired,
      onSelect: func.isRequired
    }).isRequired,

    postGradesAction: shape({
      featureEnabled: bool.isRequired,
      hasGradesToPost: bool.isRequired,
      onSelect: func.isRequired
    }).isRequired,

    showGradePostingPolicyAction: shape({
      onSelect: func.isRequired
    }).isRequired,

    sortBySetting: shape({
      direction: string.isRequired,
      disabled: bool.isRequired,
      isSortColumn: bool.isRequired,
      onSortByGradeAscending: func.isRequired,
      onSortByGradeDescending: func.isRequired,
      onSortByLate: func.isRequired,
      onSortByMissing: func.isRequired,
      onSortByUnposted: func.isRequired,
      settingKey: string.isRequired
    }).isRequired,

    students: arrayOf(
      shape({
        isInactive: bool.isRequired,
        id: string.isRequired,
        name: string.isRequired,
        sortableName: string.isRequired,
        submission: shape({
          excused: bool.isRequired,
          latePolicyStatus: string,
          postedAt: instanceOf(Date),
          score: number,
          submittedAt: instanceOf(Date),
          workflowState: string.isRequired
        }).isRequired
      })
    ).isRequired,

    submissionsLoaded: bool.isRequired,

    setDefaultGradeAction: shape({
      disabled: bool.isRequired,
      onSelect: func.isRequired
    }).isRequired,

    downloadSubmissionsAction: shape({
      hidden: bool.isRequired,
      onSelect: func.isRequired
    }).isRequired,

    reuploadSubmissionsAction: shape({
      hidden: bool.isRequired,
      onSelect: func.isRequired
    }).isRequired,

    muteAssignmentAction: shape({
      disabled: bool.isRequired,
      onSelect: func.isRequired
    }).isRequired,

    onMenuDismiss: func.isRequired,
    showUnpostedMenuItem: bool.isRequired
  }

  static defaultProps = {
    ...ColumnHeader.defaultProps
  }

  bindAssignmentLink = ref => {
    this.assignmentLink = ref
  }

  bindEnterGradesAsMenuContent = ref => {
    this.enterGradesAsMenuContent = ref
  }

  curveGrades = () => {
    this.invokeAndSkipFocus(this.props.curveGradesAction)
  }

  hideGrades = () => {
    this.invokeAndSkipFocus(this.props.hideGradesAction)
  }

  postGrades = () => {
    this.invokeAndSkipFocus(this.props.postGradesAction)
  }

  setDefaultGrades = () => {
    this.invokeAndSkipFocus(this.props.setDefaultGradeAction)
  }

  muteAssignment = () => {
    this.invokeAndSkipFocus(this.props.muteAssignmentAction)
  }

  downloadSubmissions = () => {
    this.invokeAndSkipFocus(this.props.downloadSubmissionsAction)
  }

  reuploadSubmissions = () => {
    this.invokeAndSkipFocus(this.props.reuploadSubmissionsAction)
  }

  showGradePostingPolicy = () => {
    this.invokeAndSkipFocus(this.props.showGradePostingPolicyAction)
  }

  invokeAndSkipFocus(action) {
    // this is because the onToggle handler in ColumnHeader.js is going to get
    // called synchronously, before the SetState takes effect, and it needs to
    // know to skipFocusOnClose
    this.state.skipFocusOnClose = true

    this.setState({skipFocusOnClose: true}, () => action.onSelect(this.focusAtEnd))
  }

  focusAtStart = () => {
    this.assignmentLink.focus()
  }

  handleKeyDown = event => {
    if (event.which === 9) {
      if (this.assignmentLink.focused && !event.shiftKey) {
        event.preventDefault()
        this.optionsMenuTrigger.focus()
        return false // prevent Grid behavior
      }

      if (document.activeElement === this.optionsMenuTrigger && event.shiftKey) {
        event.preventDefault()
        this.assignmentLink.focus()
        return false // prevent Grid behavior
      }
    }

    return ColumnHeader.prototype.handleKeyDown.call(this, event)
  }

  onEnterGradesAsSettingSelect = (_event, values) => {
    this.props.enterGradesAsSetting.onSelect(values[0])
  }

  showMessageStudentsWhoDialog = () => {
    this.state.skipFocusOnClose = true
    this.setState({skipFocusOnClose: true})
    const settings = MessageStudentsWhoHelper.settings(
      this.props.assignment,
      this.activeStudentDetails()
    )
    settings.onClose = this.focusAtEnd
    window.messageStudents(settings)
  }

  activeStudentDetails() {
    const activeStudents = this.props.students.filter(student => !student.isInactive)
    return activeStudents.map(student => {
      const {excused, latePolicyStatus, score, submittedAt} = student.submission
      return {
        excused,
        id: student.id,
        latePolicyStatus,
        name: student.name,
        score,
        sortableName: student.sortableName,
        submittedAt
      }
    })
  }

  renderAssignmentLink() {
    const assignment = this.props.assignment

    return (
      <Button
        size="small"
        variant="link"
        theme={{smallPadding: '0', smallFontSize: '0.75rem', smallHeight: '1rem'}}
        ref={this.bindAssignmentLink}
        href={assignment.htmlUrl}
      >
        <span className="assignment-name">{assignment.name}</span>
      </Button>
    )
  }

  renderTrigger() {
    const optionsTitle = I18n.t('%{name} Options', {name: this.props.assignment.name})

    return (
      <Button
        buttonRef={ref => (this.optionsMenuTrigger = ref)}
        size="small"
        variant="icon"
        icon={IconMoreSolid}
      >
        <ScreenReaderContent>{optionsTitle}</ScreenReaderContent>
      </Button>
    )
  }

  renderMenu() {
    if (!this.props.assignment.published) {
      return null
    }

    const {sortBySetting} = this.props
    const selectedSortSetting = sortBySetting.isSortColumn && sortBySetting.settingKey

    return (
      <Menu
        contentRef={this.bindOptionsMenuContent}
        shouldFocusTriggerOnClose={false}
        trigger={this.renderTrigger()}
        onToggle={this.onToggle}
        onDismiss={this.props.onMenuDismiss}
      >
        <Menu contentRef={this.bindSortByMenuContent} label={I18n.t('Sort by')}>
          <MenuItemGroup label={<ScreenReaderContent>{I18n.t('Sort by')}</ScreenReaderContent>}>
            <MenuItem
              selected={selectedSortSetting === 'grade' && sortBySetting.direction === 'ascending'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByGradeAscending}
            >
              {I18n.t('Grade - Low to High')}
            </MenuItem>

            <MenuItem
              selected={selectedSortSetting === 'grade' && sortBySetting.direction === 'descending'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByGradeDescending}
            >
              {I18n.t('Grade - High to Low')}
            </MenuItem>

            <MenuItem
              selected={selectedSortSetting === 'missing'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByMissing}
            >
              {I18n.t('Missing')}
            </MenuItem>

            <MenuItem
              selected={selectedSortSetting === 'late'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByLate}
            >
              {I18n.t('Late')}
            </MenuItem>

            {this.props.showUnpostedMenuItem && (
              <MenuItem
                selected={selectedSortSetting === 'unposted'}
                disabled={sortBySetting.disabled}
                onSelect={sortBySetting.onSortByUnposted}
              >
                {I18n.t('Unposted')}
              </MenuItem>
            )}
          </MenuItemGroup>
        </Menu>

        <MenuItem
          disabled={!this.props.submissionsLoaded}
          onSelect={this.showMessageStudentsWhoDialog}
        >
          <span data-menu-item-id="message-students-who">{I18n.t('Message Students Who')}</span>
        </MenuItem>

        <MenuItem disabled={this.props.curveGradesAction.isDisabled} onSelect={this.curveGrades}>
          <span data-menu-item-id="curve-grades">{I18n.t('Curve Grades')}</span>
        </MenuItem>

        <MenuItem
          disabled={this.props.setDefaultGradeAction.disabled}
          onSelect={this.setDefaultGrades}
        >
          <span data-menu-item-id="set-default-grade">{I18n.t('Set Default Grade')}</span>
        </MenuItem>

        {this.props.postGradesAction.featureEnabled ? (
          <MenuItem
            disabled={
              !this.props.postGradesAction.hasGradesToPost || !this.props.postGradesAction.hasGrades
            }
            onSelect={this.postGrades}
          >
            {labelForPostGradesAction(this.props.postGradesAction)}
          </MenuItem>
        ) : (
          <MenuItem
            disabled={this.props.muteAssignmentAction.disabled}
            onSelect={this.muteAssignment}
          >
            <span data-menu-item-id="assignment-muter">
              {this.props.assignment.muted
                ? I18n.t('Unmute Assignment')
                : I18n.t('Mute Assignment')}
            </span>
          </MenuItem>
        )}

        {this.props.postGradesAction.featureEnabled && (
          <MenuItem
            disabled={
              !this.props.hideGradesAction.hasGradesToHide || !this.props.hideGradesAction.hasGrades
            }
            onSelect={this.hideGrades}
          >
            {labelForHideGradesAction(this.props.hideGradesAction)}
          </MenuItem>
        )}

        {!this.props.enterGradesAsSetting.hidden && <MenuItemSeparator />}

        {!this.props.enterGradesAsSetting.hidden && (
          <Menu contentRef={this.bindEnterGradesAsMenuContent} label={I18n.t('Enter Grades as')}>
            <MenuItemGroup
              label={<ScreenReaderContent>{I18n.t('Enter Grades as')}</ScreenReaderContent>}
              onSelect={this.onEnterGradesAsSettingSelect}
              selected={[this.props.enterGradesAsSetting.selected]}
            >
              <MenuItem value="points">{I18n.t('Points')}</MenuItem>

              <MenuItem value="percent">{I18n.t('Percentage')}</MenuItem>

              {this.props.enterGradesAsSetting.showGradingSchemeOption && (
                <MenuItem value="gradingScheme">{I18n.t('Grading Scheme')}</MenuItem>
              )}
            </MenuItemGroup>
          </Menu>
        )}

        {!(
          this.props.downloadSubmissionsAction.hidden && this.props.reuploadSubmissionsAction.hidden
        ) && <MenuItemSeparator />}

        {!this.props.downloadSubmissionsAction.hidden && (
          <MenuItem onSelect={this.downloadSubmissions}>
            <span data-menu-item-id="download-submissions">{I18n.t('Download Submissions')}</span>
          </MenuItem>
        )}

        {!this.props.reuploadSubmissionsAction.hidden && (
          <MenuItem onSelect={this.reuploadSubmissions}>
            <span data-menu-item-id="reupload-submissions">{I18n.t('Re-Upload Submissions')}</span>
          </MenuItem>
        )}

        {this.props.postGradesAction.featureEnabled && <MenuItemSeparator />}

        {this.props.postGradesAction.featureEnabled && (
          <MenuItem onSelect={this.showGradePostingPolicy}>
            {I18n.t('Grade Posting Policy')}
          </MenuItem>
        )}
      </Menu>
    )
  }

  renderUnpostedSubmissionsIcon() {
    if (!this.props.submissionsLoaded) {
      return null
    }

    const submissions = this.props.students.map(student => student.submission)
    const postableSubmissionsPresent = submissions.some(isHidden)

    // Assignment is manually-posted and has no graded-but-unposted submissions
    // (i.e., no unposted submissions that are in a suitable state to post)
    if (this.props.assignment.postManually && !postableSubmissionsPresent) {
      return <IconOffLine size="x-small" />
    }

    // Assignment has at least one hidden submission that can be posted
    // (regardless of whether it's manually or automatically posted)
    if (postableSubmissionsPresent) {
      return <IconOffSolid color="warning" size="x-small" />
    }

    return null
  }

  render() {
    const classes = `Gradebook__ColumnHeaderAction ${this.state.menuShown ? 'menuShown' : ''}`
    const postPoliciesEnabled = this.props.postGradesAction.featureEnabled

    return (
      <div
        className={`Gradebook__ColumnHeaderContent ${this.state.hasFocus ? 'focused' : ''}`}
        onBlur={this.handleBlur}
        onFocus={this.handleFocus}
      >
        <div style={{flex: 1, minWidth: '1px'}}>
          <Grid colSpacing="none" hAlign="space-between" vAlign="middle">
            <GridRow>
              <GridCol textAlign="center" width="auto" vAlign="top">
                <div className="Gradebook__ColumnHeaderIndicators">
                  {postPoliciesEnabled && this.renderUnpostedSubmissionsIcon()}
                </div>
              </GridCol>

              <GridCol textAlign="center">
                <span className="Gradebook__ColumnHeaderDetail">
                  <span className="Gradebook__ColumnHeaderDetailLine Gradebook__ColumnHeaderDetail--primary">
                    {this.renderAssignmentLink()}
                  </span>

                  <SecondaryDetailLine
                    assignment={this.props.assignment}
                    postPoliciesEnabled={postPoliciesEnabled}
                  />
                </span>
              </GridCol>

              <GridCol textAlign="center" width="auto">
                <div className={classes}>{this.renderMenu()}</div>
              </GridCol>
            </GridRow>
          </Grid>
        </div>
      </div>
    )
  }
}
