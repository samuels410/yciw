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

import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import { mount } from 'enzyme'
import ConfigureExternalToolButton from  'jsx/external_apps/components/ConfigureExternalToolButton'

let tool
let event
let el

QUnit.module('ConfigureExternalToolButton screenreader functionality', {
  setup () {
    tool = {
      name: 'test tool',
      tool_configuration: {
        url: 'http://example.com/launch'
      }
    }

    event = {
      preventDefault () {}
    }
  },
  teardown () {
    $('.ReactModalPortal').remove()
  }
})

test('shows beginning info alert and adds styles to iframe', () => {
  const wrapper = mount(
    <ConfigureExternalToolButton
      tool={tool}
    />
  )
  wrapper.instance().openModal(event)
  el = $('.ReactModalPortal')
  const alert = el.find('.before_external_content_info_alert')
  alert[0].focus()
  equal(wrapper.state().beforeExternalContentAlertClass, '')
  deepEqual(wrapper.state().iframeStyle, { border: '2px solid #008EE2', width: '300px' })
})

test('shows ending info alert and adds styles to iframe', () => {
  const wrapper = mount(
    <ConfigureExternalToolButton
      tool={tool}
    />
  )
  wrapper.instance().openModal(event)
  el = $('.ReactModalPortal')
  const alert = el.find('.after_external_content_info_alert')
  alert[0].focus()
  equal(wrapper.state().afterExternalContentAlertClass, '')
  deepEqual(wrapper.state().iframeStyle, { border: '2px solid #008EE2', width: '300px' })
})

test('hides beginning info alert and adds styles to iframe', () => {
  wrapper = mount(
    <ConfigureExternalToolButton
      tool={tool}
    />
  )
  wrapper.instance().openModal(event)
  el = $('.ReactModalPortal')
  const alert = el.find('.before_external_content_info_alert')
  alert[0].focus()
  alert[0].blur()
  equal(wrapper.state().beforeExternalContentAlertClass, 'screenreader-only')
  deepEqual(wrapper.state().iframeStyle, { border: 'none', width: '100%' })
})

test('hides ending info alert and adds styles to iframe', () => {
  wrapper = mount(
    <ConfigureExternalToolButton
      tool={tool}
    />
  )
  wrapper.instance().openModal(event)
  el = $('.ReactModalPortal')
  const alert = el.find('.after_external_content_info_alert')
  alert[0].focus()
  alert[0].blur()
  equal(wrapper.state().afterExternalContentAlertClass, 'screenreader-only')
  deepEqual(wrapper.state().iframeStyle, { border: 'none', width: '100%' })
})

test("doesn't show alerts or add border to iframe by default", () => {
  wrapper = mount(
    <ConfigureExternalToolButton
      tool={tool}
    />
  )
  wrapper.instance().openModal(event)
  equal(wrapper.state().beforeExternalContentAlertClass, 'screenreader-only')
  equal(wrapper.state().afterExternalContentAlertClass, 'screenreader-only')
  deepEqual(wrapper.state().iframeStyle, {})
})
