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

import {
  createGradebook,
  setFixtureHtml,
  stubDataLoader
} from 'jsx/gradebook/default_gradebook/__tests__/GradebookSpecHelper'

QUnit.module('Gradebook Data Loading: Content Load States', suiteHooks => {
  let $container
  let gradebook

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    setFixtureHtml($container)

    gradebook = createGradebook()
    stubDataLoader()
  })

  suiteHooks.afterEach(() => {
    gradebook.destroy()
    $container.remove()
  })

  QUnit.module('when Gradebook is initialized', hooks => {
    hooks.beforeEach(() => {
      gradebook.initialize()
    })

    test('sets assignment groups as "not loaded"', () => {
      strictEqual(gradebook.contentLoadStates.assignmentGroupsLoaded, false)
    })

    test('sets context modules as "not loaded"', () => {
      strictEqual(gradebook.contentLoadStates.contextModulesLoaded, false)
    })

    test('sets students as "not loaded"', () => {
      strictEqual(gradebook.contentLoadStates.studentsLoaded, false)
    })

    test('sets submissions as "not loaded"', () => {
      strictEqual(gradebook.contentLoadStates.submissionsLoaded, false)
    })
  })

  QUnit.module('#setAssignmentsLoaded()', () => {
    test('optionally sets assignments as "loaded"', () => {
      gradebook.setAssignmentsLoaded(true)
      strictEqual(gradebook.contentLoadStates.assignmentsLoaded, true)
    })

    test('optionally sets assignments as "not loaded"', () => {
      gradebook.setAssignmentsLoaded(true)
      gradebook.setAssignmentsLoaded(false)
      strictEqual(gradebook.contentLoadStates.assignmentsLoaded, false)
    })
  })

  QUnit.module('#setAssignmentGroupsLoaded()', () => {
    test('optionally sets assignment groups as "loaded"', () => {
      gradebook.setAssignmentGroupsLoaded(true)
      strictEqual(gradebook.contentLoadStates.assignmentGroupsLoaded, true)
    })

    test('optionally sets assignment groups as "not loaded"', () => {
      gradebook.setAssignmentGroupsLoaded(true)
      gradebook.setAssignmentGroupsLoaded(false)
      strictEqual(gradebook.contentLoadStates.assignmentGroupsLoaded, false)
    })
  })

  QUnit.module('#setStudentsLoaded()', () => {
    test('optionally sets students as "loaded"', () => {
      gradebook.setStudentsLoaded(true)
      strictEqual(gradebook.contentLoadStates.studentsLoaded, true)
    })

    test('optionally sets students as "not loaded"', () => {
      gradebook.setStudentsLoaded(true)
      gradebook.setStudentsLoaded(false)
      strictEqual(gradebook.contentLoadStates.studentsLoaded, false)
    })
  })

  QUnit.module('#setSubmissionsLoaded()', () => {
    test('optionally sets submissions as "loaded"', () => {
      gradebook.setSubmissionsLoaded(true)
      strictEqual(gradebook.contentLoadStates.submissionsLoaded, true)
    })

    test('optionally sets submissions as "not loaded"', () => {
      gradebook.setSubmissionsLoaded(true)
      gradebook.setSubmissionsLoaded(false)
      strictEqual(gradebook.contentLoadStates.submissionsLoaded, false)
    })
  })
})
