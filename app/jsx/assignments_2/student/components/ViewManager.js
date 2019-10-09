/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {arrayOf, func, shape} from 'prop-types'
import {Assignment, AssignmentSubmissionsConnection} from '../graphqlData/Assignment'
import React from 'react'
import StudentContent from './StudentContent'
import StudentViewContext from './Context'
import {Submission} from '../graphqlData/Submission'

// Helper functions used by this component

function makeDummyNextSubmission(submission) {
  return {
    ...submission,
    attachments: [],
    attempt: submission.attempt + 1,
    deductedPoints: null,
    enteredGrade: null,
    grade: null,
    gradingStatus: null,
    latePolicyStatus: null,
    state: 'unsubmitted',
    submissionDraft: submission.submissionDraft,
    submissionStatus: 'unsubmitted',
    submittedAt: null,
    unreadCommentCount: 0
  }
}

function getAssignmentEnvVariables() {
  const baseUrl = `${window.location.origin}/${ENV.context_asset_string.split('_')[0]}s/${
    ENV.context_asset_string.split('_')[1]
  }`

  const env = {
    assignmentUrl: `${baseUrl}/assignments`,
    courseId: ENV.context_asset_string.split('_')[1],
    currentUser: ENV.current_user,
    modulePrereq: null,
    moduleUrl: `${baseUrl}/modules`
  }

  if (ENV.PREREQS.items && ENV.PREREQS.items.length !== 0 && ENV.PREREQS.items[0].prev) {
    const prereq = ENV.PREREQS.items[0].prev
    env.modulePrereq = {
      title: prereq.title,
      link: prereq.html_url,
      __typename: 'modulePrereq'
    }
  }

  return env
}

function getInitialSubmission(initialQueryData) {
  const submissionsConnection = initialQueryData.assignment.submissionsConnection
  if (!submissionsConnection || submissionsConnection.nodes.length === 0) {
    return null
  }
  return submissionsConnection.nodes[0]
}

function getSubmissionHistories(submissionHistoriesQueryData) {
  if (!submissionHistoriesQueryData) {
    return []
  }

  const historiesConnection = submissionHistoriesQueryData.node.submissionHistoriesConnection
  if (historiesConnection && historiesConnection.nodes) {
    return historiesConnection.nodes
  } else {
    return []
  }
}

function getAllSubmissions({initialQueryData, submissionHistoriesQueryData}) {
  const initialSubmission = getInitialSubmission(initialQueryData)
  if (!initialSubmission) {
    return []
  }

  // submisison histories don't have an id. We are going to add the initial
  // submissions id to all of the histories that we can query submission
  // comments without having to pipe both the initial submission and
  // currently displayed submission to all components.
  const submissionHistories = getSubmissionHistories(submissionHistoriesQueryData).map(history => {
    return {...history, id: initialSubmission.id}
  })
  submissionHistories.push(initialSubmission)
  return submissionHistories
}

class ViewManager extends React.Component {
  static propTypes = {
    initialQueryData: shape({
      ...Assignment.shape.propTypes,
      ...AssignmentSubmissionsConnection.shape.propTypes
    }),
    loadMoreSubmissionHistories: func,
    // eslint-disable-next-line react/no-unused-prop-types
    submissionHistoriesQueryData: shape({
      submissionHistoriesConnection: shape({
        nodes: arrayOf(Submission.shape)
      })
    })
  }

  state = {
    displayedAttempt: null,
    dummyNextSubmission: null,
    loadingMore: false,
    submissions: []
  }

  static getDerivedStateFromProps(props, state) {
    const prevState = state
    const nextState = {
      ...prevState,
      submissions: getAllSubmissions(props)
    }

    // Case where there are no submissions (user not logged in on public course)
    if (prevState.submissions.length === 0 && nextState.submissions.length === 0) {
      return nextState
    }

    // A submission draft for attempt n+1 is tied to the lastest submitted submission
    // with attempt n (thanks versionable). All of our children already know how to
    // display a submission draft for an unsubmitted assignment, because that's how the
    // attempt 0 works. Rather then making the components aware of how to toggle back
    // and forth and display a submission draft for an already submitted submission,
    // we are moving the submission draft for attempt n+1 into an unsubmitted
    // "dummy submission" that all our components already know how to handle.
    let currentSubmission = nextState.submissions[nextState.submissions.length - 1]
    if (currentSubmission.submissionDraft) {
      nextState.submissions.push(makeDummyNextSubmission(currentSubmission))
      nextState.dummyNextSubmission = null
    } else if (state.dummyNextSubmission) {
      nextState.submissions.push(state.dummyNextSubmission)
    }
    currentSubmission = nextState.submissions[nextState.submissions.length - 1]

    const prevStateCurrentSubmission = prevState.submissions[prevState.submissions.length - 1] || {}

    if (prevStateCurrentSubmission.attempt !== currentSubmission.attempt) {
      // Case where the "current" submission is new. This could be because an the
      // page was initially loaded, an assignment was submitted, a submission draft
      // was created, or the new attempt button was clicked which triggered a dummy
      // submission to be created.
      nextState.displayedAttempt = currentSubmission.attempt
    } else if (nextState.submissions.length > prevState.submissions.length) {
      // Case where we have new submission histories available to display. This will
      // happen as a result of `this.props.onLoadMore()` call finishing after the
      // previous submission button was clicked.
      const nextIndex = nextState.submissions.length - prevState.submissions.length - 1
      nextState.displayedAttempt = nextState.submissions[nextIndex].attempt
      nextState.loadingMore = false
    }

    return nextState
  }

  getAssignmentWithEnv = () => {
    const assignment = this.props.initialQueryData.assignment
    const assignmentCopy = JSON.parse(JSON.stringify(assignment))
    delete assignmentCopy.submissionsConnection
    assignmentCopy.env = getAssignmentEnvVariables()
    return assignmentCopy
  }

  getPageInfo = (opts = {}) => {
    const props = opts.props || this.props
    if (!props.submissionHistoriesQueryData) {
      return null
    }

    const historiesConnection =
      props.submissionHistoriesQueryData.node.submissionHistoriesConnection
    return historiesConnection && historiesConnection.pageInfo
  }

  getDisplayedSubmissionIndex = (opts = {}) => {
    const state = opts.state || this.state
    const index = state.submissions.findIndex(s => s.attempt === state.displayedAttempt)
    if (index === -1) {
      throw new Error('Could not find displayed submission')
    }
    return index
  }

  getDisplayedSubmission = (opts = {}) => {
    const state = opts.state || this.state
    return state.submissions[this.getDisplayedSubmissionIndex(opts)]
  }

  getLatestSubmission = (opts = {}) => {
    const state = opts.state || this.state
    return state.submissions[state.submissions.length - 1]
  }

  hasNextSubmission = (opts = {}) => {
    const state = opts.state || this.state
    const currentIndex = this.getDisplayedSubmissionIndex(opts)
    return currentIndex !== state.submissions.length - 1
  }

  hasPrevSubmission = (opts = {}) => {
    const state = opts.state || this.state

    // If we haven't loaded any histories yet (and aren't on attempt 1), or if
    // we still have more histories to load
    const pageInfo = this.getPageInfo(opts)
    if (!pageInfo && state.displayedAttempt > 1) {
      return true
    } else if (pageInfo && pageInfo.hasPreviousPage) {
      return true
    }

    const currentIndex = this.getDisplayedSubmissionIndex(opts)
    const submission = this.getDisplayedSubmission(opts)
    return currentIndex !== 0 && submission.attempt > 1
  }

  onNextSubmission = () => {
    this.setState((state, props) => {
      const opts = {state, props}
      if (!this.hasNextSubmission(opts)) {
        return null
      }

      const currentIndex = this.getDisplayedSubmissionIndex(opts)
      const nextAttempt = state.submissions[currentIndex + 1].attempt
      return {displayedAttempt: nextAttempt}
    })
  }

  onPrevSubmission = () => {
    this.setState((state, props) => {
      const opts = {state, props}

      // If we are already loading more submissions histories, we cannot go back
      // any further until the graphql query is complete
      if (state.loadingMore || !this.hasPrevSubmission(opts)) {
        return null
      }

      const currentIndex = this.getDisplayedSubmissionIndex(opts)
      if (currentIndex === 0) {
        props.loadMoreSubmissionHistories()
        return {loadingMore: true}
      } else {
        return {displayedAttempt: state.submissions[currentIndex - 1].attempt}
      }
    })
  }

  onStartNewAttempt = () => {
    this.setState((state, props) => {
      const opts = {state, props}
      const submission = this.getDisplayedSubmission(opts)

      // Can only create a new dummy submission if we are on the newest submission
      // and a dummy doesn't already exist, either because this was already called
      // or because it was created for a submission draft.
      if (
        state.dummyNextSubmission ||
        submission !== this.getLatestSubmission(opts) ||
        submission.submissionDraft
      ) {
        return null
      }

      // This dummy submission isn't backed by a submission draft in the database
      // at this point. Until the user does something like uploading a file which
      // creates a real submission draft, this will exist only on the frontend,
      // which is why we need to save it to the state so isn't forgotten about.
      // Once the user does make a frd submission draft, the dummy submission in
      // the state will be set back to null, and a new dummy submission will be
      // created from that submission draft instead. See getDerviedStateFromProps.
      const dummyNextSubmission = makeDummyNextSubmission(submission)
      return {
        dummyNextSubmission,
        displayedAttempt: dummyNextSubmission.attempt
      }
    })
  }

  render() {
    const assignment = this.getAssignmentWithEnv()
    const submission = this.getDisplayedSubmission()

    return (
      <StudentViewContext.Provider
        value={{
          latestSubmission: getInitialSubmission(this.props.initialQueryData),
          nextButtonAction: this.onNextSubmission,
          nextButtonEnabled: this.hasNextSubmission(),
          prevButtonAction: this.onPrevSubmission,
          prevButtonEnabled: this.hasPrevSubmission(),
          startNewAttemptAction: this.onStartNewAttempt
        }}
      >
        <StudentContent assignment={assignment} submission={submission} />
      </StudentViewContext.Provider>
    )
  }
}

export default ViewManager
