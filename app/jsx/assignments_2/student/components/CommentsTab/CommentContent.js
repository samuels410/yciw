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

import AssignmentAlert from '../AssignmentAlert'
import {arrayOf} from 'prop-types'
import CommentRow from './CommentRow'
import I18n from 'i18n!assignments_2'
import noComments from '../../SVG/NoComments.svg'
import React, {useEffect} from 'react'
import {SubmissionComment} from '../../graphqlData/SubmissionComment'
import {Submission} from '../../graphqlData/Submission'
import SVGWithTextPlaceholder from '../../../shared/SVGWithTextPlaceholder'
import {MARK_SUBMISISON_COMMENT_READ} from '../../graphqlData/Mutations'
import {SUBMISSION_COMMENT_QUERY} from '../../graphqlData/Queries'
import {useMutation} from 'react-apollo'

function CommentContent(props) {
  const [markCommentsRead, {called: mutationCalled, error: mutationError}] = useMutation(
    MARK_SUBMISISON_COMMENT_READ,
    {
      update(cache) {
        const submissionQueryVariables = {
          id: props.submission.id,
          fragment: Submission.fragment,
          fragmentName: 'Submission',
          variables: {submissionID: props.submission.id}
        }

        const commentQueryVariables = {
          query: SUBMISSION_COMMENT_QUERY,
          variables: {
            submissionId: props.submission.id,
            submissionAttempt: props.submission.attempt
          }
        }

        const submission = JSON.parse(JSON.stringify(cache.readFragment(submissionQueryVariables)))
        submission.unreadCommentCount = 0
        cache.writeFragment({
          ...submissionQueryVariables,
          data: {...submission, __typename: 'Submission'}
        })

        const {submissionComments} = JSON.parse(
          JSON.stringify(cache.readQuery(commentQueryVariables))
        )
        submissionComments.commentsConnection.nodes.forEach(comment => (comment.read = true))
        cache.writeQuery({
          ...commentQueryVariables,
          data: {submissionComments}
        })
      }
    }
  )

  useEffect(() => {
    if (props.submission.unreadCommentCount > 0) {
      const commentIds = props.comments
        .filter(comment => comment.read === false)
        .map(comment => comment._id)
      const timer = setTimeout(() => {
        markCommentsRead({variables: {commentIds, submissionId: props.submission.id}})
      }, 1000)

      return () => clearTimeout(timer)
    }
  }, [markCommentsRead, props.comments, props.submission])

  return (
    <>
      {mutationCalled && !mutationError && (
        <AssignmentAlert
          successMessage={I18n.t('All submission comments have been marked as read.')}
        />
      )}
      {mutationError && (
        <AssignmentAlert
          errorMessage={I18n.t('There was a problem marking submission comments as read.')}
        />
      )}
      {!props.comments.length && (
        <SVGWithTextPlaceholder
          text={I18n.t('Send a comment to your instructor about this assignment.')}
          url={noComments}
        />
      )}
      {props.comments
        .sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt))
        .map(comment => (
          <CommentRow key={comment._id} comment={comment} />
        ))}
    </>
  )
}

CommentContent.propTypes = {
  comments: arrayOf(SubmissionComment.shape).isRequired,
  submission: Submission.shape.isRequired
}

export default React.memo(CommentContent)
