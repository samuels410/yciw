/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import ready from '@instructure/ready'

const Tour = React.lazy(() => import('../nav_tourpoints/tour'))

ready(() => {
  const current_roles = window.ENV.current_user_roles || []
  let role = null

  // Decide which tour to show based on the role
  if (current_roles.includes('teacher')) {
    role = 'teacher'
  }

  const globalNavTourContainer = document.getElementById('global_nav_tour')

  // If the user doesn't have a role with a tour
  // don't even mount it. This saves us from having
  // to download the code-split bundle.
  if (globalNavTourContainer && role) {
    ReactDOM.render(
      <React.Suspense fallback={null}>
        <Tour role={role} />
      </React.Suspense>,
      globalNavTourContainer
    )
  }
})
