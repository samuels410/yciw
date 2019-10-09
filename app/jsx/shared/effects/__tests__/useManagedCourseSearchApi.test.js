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

import fetchMock from 'fetch-mock'
import {renderHook} from '@testing-library/react-hooks'
import useManagedCourseSearchApi from '../useManagedCourseSearchApi'

function setupManagedCoursesResponse() {
  const response = [
    {
      id: '1',
      label: 'Board Game Basics'
    },
    {
      id: '2',
      label: 'Settlers of Catan 101'
    }
  ]
  fetchMock.mock('path:/users/self/manageable_courses', response)
  return response
}

describe('useManagedCourseSearchApi', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  it('fetches and reports converted results', async () => {
    setupManagedCoursesResponse()
    const success = jest.fn()
    const error = jest.fn()
    renderHook(() => useManagedCourseSearchApi({success}))
    await fetchMock.flush(true)
    expect(error).not.toHaveBeenCalled()
    expect(success).toHaveBeenCalledWith([
      expect.objectContaining({id: '1', name: 'Board Game Basics'}),
      expect.objectContaining({id: '2', name: 'Settlers of Catan 101'})
    ])
  })
})
