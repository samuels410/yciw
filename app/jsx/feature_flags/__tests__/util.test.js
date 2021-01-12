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

import sampleData from './sampleData.json'
import * as util from '../util'

describe('feature_flags:util', () => {
  describe('buildTransitions', () => {
    it('generates the right things for allowed, allowsDefaults', () => {
      expect(util.buildTransitions(sampleData.allowedFeature.feature_flag, true)).toEqual(
        expect.objectContaining({
          enabled: 'allowed_on',
          disabled: 'allowed',
          lock: 'off'
        })
      )
    })

    it('generates the right things for allowedOn, allowsDefaults', () => {
      expect(util.buildTransitions(sampleData.allowedOnFeature.feature_flag, true)).toEqual(
        expect.objectContaining({
          enabled: 'allowed_on',
          disabled: 'allowed',
          lock: 'on'
        })
      )
    })

    it('generates the right things for allowedOn, no allowsDefaults', () => {
      expect(util.buildTransitions(sampleData.allowedOnFeature.feature_flag, false)).toEqual(
        expect.objectContaining({
          enabled: 'on',
          disabled: 'off'
        })
      )
    })
  })

  describe('buildDescription', () => {
    it('generates the right things with allowsDefaults', () => {
      expect(util.buildDescription(sampleData.offFeature.feature_flag, true)).toEqual(
        'Disabled (locked)'
      )
      expect(util.buildDescription(sampleData.allowedFeature.feature_flag, true)).toEqual(
        'Disabled (unlocked)'
      )
      expect(util.buildDescription(sampleData.allowedOnFeature.feature_flag, true)).toEqual(
        'Enabled (unlocked)'
      )
      expect(util.buildDescription(sampleData.onFeature.feature_flag, true)).toEqual(
        'Enabled (locked)'
      )
    })

    it('generates the right things with no allowsDefaults', () => {
      expect(util.buildDescription(sampleData.offFeature.feature_flag, false)).toEqual('Disabled')
      expect(util.buildDescription(sampleData.allowedFeature.feature_flag, false)).toEqual(
        'Disabled'
      )
      expect(util.buildDescription(sampleData.allowedOnFeature.feature_flag, false)).toEqual(
        'Enabled'
      )
      expect(util.buildDescription(sampleData.onFeature.feature_flag, false)).toEqual('Enabled')
    })
  })
})
