/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import _ from 'underscore'

  const MD5_REGEX = /[0-9a-fA-F]{32}$/
  const types = {}

  types.md5 = (props, propName, componentName) => {
    var val = props[propName];
    if (val !== null && !MD5_REGEX.test(val)) {
      return new Error(`Invalid md5: ${val} propName: ${propName} componentName: ${componentName}`)
    }
  }

  const baseVarDef = {
    default: React.PropTypes.string.isRequired,
    human_name: React.PropTypes.string.isRequired,
    variable_name: React.PropTypes.string.isRequired,
  }

  types.variables = React.PropTypes.objectOf(React.PropTypes.string).isRequired

  types.color = React.PropTypes.shape(_.extend({
    type: React.PropTypes.oneOf(['color']).isRequired
  }, baseVarDef))

  types.image = React.PropTypes.shape(_.extend({
    type: React.PropTypes.oneOf(['image']).isRequired,
    accept: React.PropTypes.string.isRequired,
    helper_text: React.PropTypes.string
  }, baseVarDef))

  types.percentage = React.PropTypes.shape(_.extend({
    type: React.PropTypes.oneOf(['percentage']).isRequired,
    helper_text: React.PropTypes.string
  },baseVarDef))

  types.varDef = React.PropTypes.oneOfType([types.image, types.color, types.percentage])

  types.brandConfig = React.PropTypes.shape({
    md5: types.md5,
    variables: types.variables
  })

  types.sharedBrandConfig = React.PropTypes.shape({
    account_id: React.PropTypes.string,
    brand_config: types.brandConfig.isRequired,
    name: React.PropTypes.string.isRequired
  })

  types.variableGroup = React.PropTypes.shape({
    group_name: React.PropTypes.string.isRequired,
    variables: React.PropTypes.arrayOf(types.varDef).isRequired
  })

  types.userVariableInput = React.PropTypes.shape({
    val: React.PropTypes.string,
    invalid: React.PropTypes.bool
  })

  types.variableSchema = React.PropTypes.arrayOf(types.variableGroup).isRequired

  types.variableDescription = React.PropTypes.shape({
    default: React.PropTypes.string.isRequired,
    type: React.PropTypes.oneOf(['color', 'image', 'percentage']).isRequired,
    variable_name: React.PropTypes.string.isRequired
  })

  types.brandableVariableDefaults = React.PropTypes.objectOf(types.variableDescription)

export default types
