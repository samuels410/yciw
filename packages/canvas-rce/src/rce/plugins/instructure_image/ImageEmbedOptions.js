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

import formatMessage from '../../../format-message'
import {scaleForHeight, scaleForWidth} from '../shared/DimensionUtils'

export const MIN_HEIGHT = 10
export const MIN_WIDTH = 10

export const SMALL = 'small'
export const MEDIUM = 'medium'
export const LARGE = 'large'
export const EXTRA_LARGE = 'extra-large'
export const CUSTOM = 'custom'

export const imageSizes = [SMALL, MEDIUM, LARGE, EXTRA_LARGE, CUSTOM]
export const defaultImageSize = 320

const sizeByMaximumDimension = {
  200: SMALL,
  320: MEDIUM,
  400: LARGE,
  640: EXTRA_LARGE
}

function parsedOrNull($element, attribute) {
  // when the image is first inserted into the rce, it's size
  // is constrained by a style attribute with max-width, max-height.
  // While it doesn't have a 'width' or 'height' attribute, we can
  // still get its width and height directly from the img element
  const value = $element.hasAttribute(attribute) ?
    $element.getAttribute(attribute) :
    $element[attribute]
  return value ? Math.round(Number.parseInt(value, 10)) : null
}

function imageSizeFromKnownOptions(imageOptions) {
  const intendedWidth = imageOptions.appliedWidth || imageOptions.naturalWidth
  const intendedHeight = imageOptions.appliedHeight || imageOptions.naturalHeight
  const largestDimension = Math.max(intendedWidth, intendedHeight)
  return sizeByMaximumDimension[largestDimension] || CUSTOM
}

export function fromImageEmbed($element) {
  const altText = $element.alt || ''

  const imageOptions = {
    altText,
    appliedHeight: parsedOrNull($element, 'height'),
    appliedWidth: parsedOrNull($element, 'width'),
    isDecorativeImage: altText === '' && $element.getAttribute('data-is-decorative') === 'true',
    naturalHeight: $element.naturalHeight,
    naturalWidth: $element.naturalWidth,
    url: $element.src
  }

  imageOptions.imageSize = imageSizeFromKnownOptions(imageOptions)

  return imageOptions
}

export function scaleImageForHeight(naturalWidth, naturalHeight, targetHeight) {
  const constraints = {minHeight: MIN_HEIGHT, minWidth: MIN_WIDTH}
  return scaleForHeight(naturalWidth, naturalHeight, targetHeight, constraints)
}

export function scaleImageForWidth(naturalWidth, naturalHeight, targetWidth) {
  const constraints = {minHeight: MIN_HEIGHT, minWidth: MIN_WIDTH}
  return scaleForWidth(naturalWidth, naturalHeight, targetWidth, constraints)
}

export function scaleToSize(imageSize, naturalWidth, naturalHeight) {
  if (imageSize === CUSTOM) {
    return {width: naturalWidth, height: naturalHeight}
  }

  const [dimension] = Object.entries(sizeByMaximumDimension).find(
    ([, size]) => size === imageSize
  )
  const scaleFactor = dimension / Math.max(naturalWidth, naturalHeight)
  return {
    height: Math.round(naturalHeight * scaleFactor),
    width: Math.round(naturalWidth * scaleFactor)
  }
}

export function labelForImageSize(imageSize) {
  switch (imageSize) {
    case SMALL: {
      return formatMessage('Small')
    }
    case MEDIUM: {
      return formatMessage('Medium')
    }
    case LARGE: {
      return formatMessage('Large')
    }
    case EXTRA_LARGE: {
      return formatMessage('Extra Large')
    }
    default: {
      return formatMessage('Custom')
    }
  }
}
