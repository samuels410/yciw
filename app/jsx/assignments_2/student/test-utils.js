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
import {
  CREATE_SUBMISSION,
  CREATE_SUBMISSION_COMMENT,
  CREATE_SUBMISSION_DRAFT,
  STUDENT_VIEW_QUERY,
  SUBMISSION_COMMENT_QUERY,
  SUBMISSION_ID_QUERY
} from './assignmentData'

export function mockAssignment(overrides = {}) {
  return {
    _id: '22',
    description: '<p>description</p>',
    dueAt: '2018-07-11T18:59:59-06:00',
    lockAt: null,
    name: 'Assignment',
    pointsPossible: 10,
    muted: false,
    unlockAt: null,
    gradingType: 'points',
    allowedAttempts: null,
    allowedExtensions: [],
    assignmentGroup: {
      name: 'Assignments',
      __typename: 'AssignmentGroup'
    },
    env: {
      assignmentUrl: '/test/assignment',
      moduleUrl: '/test/module',
      currentUser: {
        display_name: 'optimistic user',
        avatar_image_url: 'http://awesome.url.thing'
      },
      modulePrereq: null,
      courseId: '3',
      __typename: 'env'
    },
    lockInfo: {
      isLocked: true,
      __typename: 'LockInfo'
    },
    modules: [],
    __typename: 'Assignment',
    ...overrides
  }
}

export function mockComments(overrides = {}) {
  return {
    __typename: 'Submission',
    commentsConnection: {
      __typename: 'CommentsConnection',
      nodes: [
        {
          __typename: 'SubmissionComment',
          _id: '1',
          attachments: [],
          comment: 'comment comment',
          mediaObject: null,
          updatedAt: '2019-03-05T23:09:36-07:00',
          author: {
            __typename: 'User',
            avatarUrl: 'example.com',
            shortName: 'bob builder'
          }
        }
      ]
    },
    ...overrides
  }
}

export function mockMultipleAttachments() {
  return [
    {
      _id: '1',
      id: '1',
      displayName: 'awesome-test-image1.png',
      mimeClass: 'data',
      submissionPreviewUrl: 'https://some/awesome/preview1',
      thumbnailUrl: 'https://some/awesome/thumbnail1.jpg',
      url: 'fake_url',
      __typename: 'Attachment'
    },
    {
      _id: '2',
      id: '2',
      displayName: 'awesome-test-image2.png',
      mimeClass: 'data',
      submissionPreviewUrl: 'https://some/awesome/preview2',
      thumbnailUrl: 'https://some/awesome/thumbnail2.jpg',
      url: 'fake_url',
      __typename: 'Attachment'
    },
    {
      _id: '3',
      id: '3',
      displayName: 'awesome-test-image3.png',
      mimeClass: 'data',
      submissionPreviewUrl: 'https://some/awesome/preview3',
      thumbnailUrl: 'https://some/awesome/thumbnail3.jpg',
      url: 'fake_url',
      __typename: 'Attachment'
    }
  ]
}

export function singleMediaObject(overrides = {}) {
  return {
    __typename: 'MediaObject',
    id: '9',
    title: 'video media comment',
    mediaType: 'video/mp4',
    mediaSources: {
      __typename: 'MediaSource',
      src: 'www.blah.com',
      type: 'video/mp4'
    },
    ...overrides
  }
}

export function singleComment(overrides = {}) {
  return {
    _id: '1',
    attachments: [],
    comment: 'comment comment',
    updatedAt: '2019-03-05T23:09:36-07:00',
    author: {
      __typename: 'Author',
      avatarUrl: 'example.com',
      shortName: 'bob builder'
    },
    ...overrides
  }
}

export function singleAttachment(overrides = {}) {
  return {
    __typename: 'Attachment',
    _id: '20',
    displayName: 'lookatme.pdf',
    id: '20',
    mimeClass: 'pdf',
    thumbnailUrl: 'https://some/awesome/thumbnail.jpg',
    url: 'https://some-awesome/url/goes/here',
    ...overrides
  }
}

export function commentGraphqlMock(comments) {
  return [
    {
      request: {
        query: SUBMISSION_COMMENT_QUERY,
        variables: {
          submissionAttempt: legacyMockSubmission().attempt,
          submissionId: legacyMockSubmission().id
        }
      },
      result: {
        data: {
          submissionComments: comments
        }
      }
    },
    {
      request: {
        query: CREATE_SUBMISSION_COMMENT,
        variables: {
          submissionAttempt: legacyMockSubmission().attempt,
          id: legacyMockSubmission().id,
          comment: 'lion',
          fileIds: []
        }
      },
      result: {
        data: {
          createSubmissionComment: {
            submissionComment: {
              _id: '3',
              comment: 'lion',
              updatedAt: new Date().toISOString(),
              attachments: [],
              author: {
                avatarUrl: 'whatever',
                shortName: 'sent user',
                __typename: 'User'
              },
              mediaObject: null,
              __typename: 'SubmissionComment'
            },
            __typename: 'CreateSubmissionCommentPayload'
          }
        }
      }
    },
    {
      request: {
        query: CREATE_SUBMISSION_COMMENT,
        variables: {
          submissionAttempt: legacyMockSubmission().attempt,
          id: legacyMockSubmission().id,
          comment: 'lion',
          fileIds: ['1', '2', '3']
        }
      },
      result: {
        data: {
          createSubmissionComment: {
            submissionComment: {
              _id: '3',
              comment: 'lion',
              updatedAt: new Date().toISOString(),
              attachments: mockMultipleAttachments(),
              author: {
                avatarUrl: 'whatever',
                shortName: 'sent user',
                __typename: 'User'
              },
              mediaObject: null,
              __typename: 'SubmissionComment'
            },
            __typename: 'CreateSubmissionCommentPayload'
          }
        }
      }
    }
  ]
}

export function mockSubmissionHistoriesConnection() {
  const submissionHistory = mockSubmission()

  return {
    __typename: 'SubmissionHistoryConnection',
    pageInfo: {
      __typename: 'PageInfo',
      hasPreviousPage: false,
      startCursor: btoa('1')
    },
    edges: [
      {
        __typename: 'SubmissionHistoryEdge',
        cursor: btoa('1'),
        node: submissionHistory
      }
    ]
  }
}

export function mockGraphqlQueryResults(overrides = {}) {
  const assignment = mockAssignment(overrides)
  assignment.submissionsConnection = {
    nodes: [mockSubmission()],
    __typename: 'SubmissionConnection'
  }
  return assignment
}

export function submissionGraphqlMock() {
  return [
    {
      request: {
        query: CREATE_SUBMISSION_DRAFT,
        variables: {
          id: mockSubmission().id,
          attempt: 1,
          fileIds: ['1']
        }
      },
      result: {
        data: {
          createSubmissionDraft: {
            submissionDraft: {
              __typename: 'SubmissionDraft',
              _id: '22',
              attachments: [singleAttachment({_id: '1'})]
            },
            errors: {
              attribute: null,
              message: null,
              __typename: 'Errors'
            },
            __typename: 'CreateSubmissionDraftPayload'
          }
        }
      }
    },
    {
      request: {
        query: CREATE_SUBMISSION,
        variables: {
          assignmentLid: '22',
          submissionID: mockSubmission().id,
          type: 'online_upload',
          fileIds: ['1']
        }
      },
      result: {
        data: {
          createSubmission: {
            submission: mockSubmission(),
            errors: {
              attribute: null,
              message: null,
              __typename: 'Errors'
            },
            __typename: 'CreateSubmissionPayload'
          }
        }
      }
    },
    {
      request: {
        query: STUDENT_VIEW_QUERY,
        variables: {
          assignmentLid: '22',
          submissionID: mockSubmission().id
        }
      },
      result: {
        data: {
          assignment: mockGraphqlQueryResults({
            lockInfo: {isLocked: false, __typename: 'LockInfo'}
          })
        }
      }
    },
    {
      request: {
        query: SUBMISSION_ID_QUERY,
        variables: {
          assignmentLid: '22'
        }
      },
      result: {
        data: {
          assignment: {
            submissionsConnection: {
              nodes: [
                {
                  id: mockSubmission().id,
                  __typename: 'Submission'
                }
              ],
              __typename: 'SubmissionConnection'
            },
            __typename: 'Assignment'
          }
        }
      }
    }
  ]
}

export function mockSubmission(overrides = {}) {
  return {
    attachments: mockMultipleAttachments(),
    attempt: 1,
    commentsConnection: {
      __typename: 'CommentsConnection',
      nodes: [
        {
          __typename: 'Comment',
          _id: '1',
          attachments: [],
          comment: 'comment comment',
          updatedAt: '2019-03-05T23:09:36-07:00',
          author: {
            __typename: 'Author',
            avatarUrl: 'example.com',
            shortName: 'bob builder'
          }
        }
      ]
    },
    deductedPoints: null,
    enteredGrade: null,
    grade: null,
    gradingStatus: 'needs_grading',
    id: btoa('Submission-22'),
    latePolicyStatus: null,
    state: 'submitted',
    submissionDraft: null,
    submissionStatus: 'submitted',
    submittedAt: '2019-05-08T10:02:42-06:00',
    __typename: 'Submission',
    ...overrides
  }
}

export function mockSubmissionHistory() {
  const submissionHistory = mockSubmission()
  delete submissionHistory.id
  return submissionHistory
}

export function mockSubmissionDraft(overrides = {}) {
  return {
    _id: '50',
    attachments: [singleAttachment()],
    ...overrides
  }
}

// TODO We had a split between mockSubmission and mockAssignment where they
//     returned different submisison results. Now that submission is a separate
//     prop, we need to rectify these changes and unify everything under one
//     function. Ideally, each test will set the submission state explictly that
//     is required for the test work work, and not rely on the default values
//     provided (or we have separate helper functions like mockSubmittedAssignment).
//     But that will come after instcon, for now we are providing a separate
//     function that has the same results as submission in the old mockAssignment.
export function legacyMockSubmission() {
  const overrides = {
    deductedPoints: 3,
    enteredGrade: '9',
    grade: '6',
    id: btoa('Submission-3'),
    latePolicyStatus: 'late',
    submissionStatus: 'late',
    submittedAt: '2019-02-20T15:12:33-07:00',
    gradingStatus: 'graded'
  }
  return mockSubmission(overrides)
}
