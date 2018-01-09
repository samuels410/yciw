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

import actions from 'jsx/announcements/actions'
import reducer from 'jsx/announcements/reducer'
import sampleData from './sampleData'

QUnit.module('Announcements reducer')

const reduce = (action, state = {}) => reducer(state, action)

// test('does something on SOME_ACTION', () => {
//   const newState = reduce(actions.someAction())
//   deepEqual(newState.foo, 'bar')
// })
