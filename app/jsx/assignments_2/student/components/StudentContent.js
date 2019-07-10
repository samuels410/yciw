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

import {AssignmentShape, SubmissionShape} from '../assignmentData'
import AssignmentToggleDetails from '../../shared/AssignmentToggleDetails'
import ContentTabs from './ContentTabs'
import Header from './Header'
import I18n from 'i18n!assignments_2_student_content'
import LockedAssignment from './LockedAssignment'
import MissingPrereqs from './MissingPrereqs'
import React, {Suspense, lazy} from 'react'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'

const LoggedOutTabs = lazy(() => import('./LoggedOutTabs'))

function renderContentBaseOnAvailability(assignment, submission) {
  if (assignment.env.modulePrereq) {
    const prereq = assignment.env.modulePrereq
    return <MissingPrereqs preReqTitle={prereq.title} preReqLink={prereq.link} />
  } else if (assignment && assignment.lockInfo.isLocked) {
    return <LockedAssignment assignment={assignment} />
  } else if (submission === null) {
    // NOTE: handles case where user is not logged in
    return (
      <React.Fragment>
        <AssignmentToggleDetails description={assignment.description} />
        <Suspense
          fallback={<Spinner title={I18n.t('Loading')} size="large" margin="0 0 0 medium" />}
        >
          <LoggedOutTabs assignment={assignment} />
        </Suspense>
      </React.Fragment>
    )
  } else {
    return (
      <React.Fragment>
        <AssignmentToggleDetails description={assignment.description} />
        <ContentTabs assignment={assignment} submission={submission} />
      </React.Fragment>
    )
  }
}

function StudentContent(props) {
  const {assignment, submission} = props
  return (
    <div data-testid="assignments-2-student-view">
      <Header scrollThreshold={150} assignment={assignment} submission={submission} />
      {renderContentBaseOnAvailability(assignment, submission)}
    </div>
  )
}

StudentContent.propTypes = {
  assignment: AssignmentShape,
  submission: SubmissionShape
}

export default React.memo(StudentContent)
