/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {bool, number, shape, string, arrayOf} from 'prop-types'

export function GetAssignmentEnvVariables() {
  const defaults = {
    assignmentUrl: '',
    courseId: null,
    currentUser: null,
    modulePrereq: null,
    moduleUrl: ''
  }
  if (!window.ENV || !Object.keys(window.ENV).length) {
    return defaults
  }

  const baseUrl = `${window.location.origin}/${ENV.context_asset_string.split('_')[0]}s/${
    ENV.context_asset_string.split('_')[1]
  }`
  defaults.assignmentUrl = `${baseUrl}/assignments`
  defaults.moduleUrl = `${baseUrl}/modules`
  defaults.currentUser = ENV.current_user
  defaults.courseId = ENV.context_asset_string.split('_')[1]

  if (ENV.PREREQS.items && ENV.PREREQS.items.length !== 0 && ENV.PREREQS.items[0].prev) {
    const prereq = ENV.PREREQS.items[0].prev
    defaults.modulePrereq = {
      title: prereq.title,
      link: prereq.html_url,
      __typename: 'modulePrereq'
    }
  } else {
    defaults.modulePrereq = null
  }

  return {...defaults}
}

function attachmentFields() {
  return `
    _id
    displayName
    mimeClass
    thumbnailUrl
    url
  `
}

function submissionFields() {
  return `
    _id
    id
    deductedPoints
    enteredGrade
    grade
    gradingStatus
    latePolicyStatus
    state
    submissionDraft {
      _id
      attachments {
        ${attachmentFields()}
      }
    }
    submissionStatus
    submittedAt
  `
}

function submissionCommentQueryParams() {
  return `
    _id
    comment
    updatedAt
    mediaObject {
      id
      title
      mediaType
      mediaSources {
        src: url
        type: contentType
        height
        width
      }
    }
    author {
      avatarUrl
      shortName
    }
    attachments {
      ${attachmentFields()}
    }`
}

export const STUDENT_VIEW_QUERY = gql`
  query GetAssignment($assignmentLid: ID!) {
    assignment: legacyNode(type: Assignment, _id: $assignmentLid) {
      ... on Assignment {
        _id
        description
        dueAt
        lockAt
        name
        muted
        pointsPossible
        unlockAt
        gradingType
        allowedAttempts
        allowedExtensions
        assignmentGroup {
          name
        }
        lockInfo {
          isLocked
        }
        modules {
          id
          name
        }
        submissionsConnection(
          last: 1
          filter: {states: [unsubmitted, graded, pending_review, submitted]}
        ) {
          nodes {
            ${submissionFields()}
          }
        }
      }
    }
  }
`

export const SUBMISSION_COMMENT_QUERY = gql`
  query GetSubmissionComments($submissionId: ID!) {
    submissionComments: node(id: $submissionId) {
      ... on Submission {
        commentsConnection(filter: {allComments: true}) {
          nodes {
            ${submissionCommentQueryParams()}
          }
        }
      }
    }
  }
`

export const CREATE_SUBMISSION_COMMENT = gql`
  mutation CreateSubmissionComment($id: ID!, $comment: String!, $fileIds: [ID!]) {
    createSubmissionComment(input: {submissionId: $id, comment: $comment, fileIds: $fileIds}) {
      submissionComment {
        ${submissionCommentQueryParams()}
      }
    }
  }
`

export const CREATE_SUBMISSION = gql`
  mutation CreateSubmission($id: ID!, $type: OnlineSubmissionType!, $fileIds: [ID!]) {
    createSubmission(input: {assignmentId: $id, submissionType: $type, fileIds: $fileIds}) {
      submission {
        ${submissionFields()}
      }
      errors {
        attribute
        message
      }
    }
  }
`

export const AttachmentShape = shape({
  _id: string,
  displayName: string,
  mimeClass: string,
  thumbnailUrl: string,
  url: string
})

export const SubmissionDraftShape = shape({
  _id: string,
  attachments: arrayOf(AttachmentShape)
})

export const MediaObjectShape = shape({
  id: string,
  title: string,
  mediaType: string,
  mediaSources: shape({
    src: string,
    type: string
  })
})

export const CommentShape = shape({
  _id: string,
  attachments: arrayOf(AttachmentShape),
  comment: string,
  mediaObject: MediaObjectShape,
  author: shape({
    avatarUrl: string,
    shortName: string
  }),
  updatedAt: string
})

export const AssignmentShape = shape({
  _id: string,
  description: string,
  dueAt: string,
  lockAt: string,
  muted: bool.isRequired,
  name: string.isRequired,
  pointsPossible: number.isRequired,
  unlockAt: string,
  gradingType: string,
  allowedAttempts: number,
  allowedExtensions: arrayOf(string),
  assignmentGroup: shape({
    name: string.isRequired
  }).isRequired,
  env: shape({
    assignmentUrl: string.isRequired,
    moduleUrl: string.isRequired,
    currentUser: shape({
      display_name: string,
      avatar_image_url: string,
      id: string
    }),
    modulePrereq: shape({
      title: string.isRequired,
      link: string.isRequired
    })
  }).isRequired,
  lockInfo: shape({
    isLocked: bool.isRequired
  }).isRequired,
  modules: arrayOf(
    shape({
      id: string.isRequired,
      name: string.isRequired
    }).isRequired
  ).isRequired
})

export const SubmissionShape = shape({
  commentsConnection: shape({
    nodes: arrayOf(CommentShape)
  }),
  id: string,
  deductedPoints: number,
  enteredGrade: string,
  grade: string,
  gradingStatus: string,
  latePolicyStatus: string,
  state: string,
  submissionDraft: SubmissionDraftShape,
  submissionStatus: string,
  submittedAt: string
})
