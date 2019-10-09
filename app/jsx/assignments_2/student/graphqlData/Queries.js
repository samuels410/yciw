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
import gql from 'graphql-tag'

import {Assignment, AssignmentSubmissionsConnection} from './Assignment'
import {ExternalTool} from './ExternalTool'
import {Rubric} from './Rubric'
import {SubmissionComment} from './SubmissionComment'
import {SubmissionHistory} from './SubmissionHistory'
import {UserGroups} from './UserGroups'

export const EXTERNAL_TOOLS_QUERY = gql`
  query ExternalTools($courseID: ID!) {
    course(id: $courseID) {
      externalToolsConnection(filter: {placement: homework_submission, state: public}) {
        nodes {
          ...ExternalTool
        }
      }
    }
  }
  ${ExternalTool.fragment}
`

export const RUBRIC_QUERY = gql`
  query GetRubric($assignmentID: ID!) {
    assignment(id: $assignmentID) {
      rubric {
        ...Rubric
      }
    }
  }
  ${Rubric.fragment}
`

export const STUDENT_VIEW_QUERY = gql`
  query GetAssignment($assignmentLid: ID!, $submissionID: ID!) {
    assignment(id: $assignmentLid) {
      ...Assignment
      ...AssignmentSubmissionsConnection
    }
  }
  ${Assignment.fragment}
  ${AssignmentSubmissionsConnection.fragment}
`

export const SUBMISSION_COMMENT_QUERY = gql`
  query GetSubmissionComments($submissionId: ID!, $submissionAttempt: Int!) {
    submissionComments: node(id: $submissionId) {
      ... on Submission {
        commentsConnection(filter: {forAttempt: $submissionAttempt}) {
          nodes {
            ...SubmissionComment
          }
        }
      }
    }
  }
  ${SubmissionComment.fragment}
`

export const SUBMISSION_HISTORIES_QUERY = gql`
  query NextSubmission($submissionID: ID!, $cursor: String) {
    node(id: $submissionID) {
      ... on Submission {
        submissionHistoriesConnection(
          before: $cursor
          last: 5
          filter: {includeCurrentSubmission: false}
        ) {
          pageInfo {
            hasPreviousPage
            startCursor
          }
          nodes {
            ...SubmissionHistory
          }
        }
      }
    }
  }
  ${SubmissionHistory.fragment}
`

export const SUBMISSION_ID_QUERY = gql`
  query GetAssignmentSubmissionID($assignmentLid: ID!) {
    assignment(id: $assignmentLid) {
      submissionsConnection(
        last: 1
        filter: {states: [unsubmitted, graded, pending_review, submitted]}
      ) {
        nodes {
          id
        }
      }
    }
  }
`

export const USER_GROUPS_QUERY = gql`
  query GetUserGroups($userID: ID!) {
    legacyNode(_id: $userID, type: User) {
      ...UserGroups
    }
  }
  ${UserGroups.fragment}
`
