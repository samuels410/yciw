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
import {arrayOf, shape, string} from 'prop-types'
import gql from 'graphql-tag'
import {MediaSource} from './MediaSource'

export const MediaObject = {
  fragment: gql`
    fragment MediaObject on MediaObject {
      id
      mediaSources {
        ...MediaSource
      }
      mediaType
      title
    }
    ${MediaSource.fragment}
  `,

  shape: shape({
    id: string.isRequired,
    mediaSources: arrayOf(MediaSource.shape),
    mediaType: string,
    title: string
  })
}

export const MediaObjectDefaultMocks = {
  MediaObject: () => ({
    mediaSources: [{}],
    mediaType: 'video',
    title: 'Mocked Video'
  })
}
