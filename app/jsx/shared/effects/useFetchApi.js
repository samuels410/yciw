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

import _ from 'lodash'
import {useEffect, useRef} from 'react'
import doFetchApi from './doFetchApi'

// this is a nicety so we only run the search effect if the parameters have
// deeply changed. If we didn't do this and the consumer of this effect wasn't
// careful about the identity of the params object they were passing in, we
// could wind up redoing the search on every render. This also lets us safely
// use `{}` as a default parameter
function useOldestUnchanged(nextParams) {
  const oldParamsRef = useRef(nextParams)
  const shouldUpdate = !_.isEqual(oldParamsRef.current, nextParams)
  const result = shouldUpdate ? nextParams : oldParamsRef.current
  useEffect(() => {
    oldParamsRef.current = result
  })
  return result
}

// utility for making it easy to abort the fetch
function abortable({success, error}) {
  const aborter = new AbortController()
  let active = true
  return {
    activeSuccess: (...p) => {
      if (active && success) success(...p)
    },
    activeError: (...p) => {
      if (active && error) error(...p)
    },
    abort: () => {
      active = false
      aborter.abort()
    },
    signal: aborter.signal
  }
}

export default function useFetchApi({
  success,
  error,
  path,
  convert,
  forceResult,
  params = {},
  headers = {},
  fetchOpts = {}
}) {
  const oldestUnchangedParams = useOldestUnchanged(params)
  const oldestUnchangedHeaders = useOldestUnchanged(headers)
  const oldestUnchangedFetchOpts = useOldestUnchanged(fetchOpts)
  const oldestForceResult = useOldestUnchanged(forceResult)
  useEffect(() => {
    if (oldestForceResult !== undefined) {
      success(oldestForceResult)
      return
    }

    // prevent sending results and errors from stale queries
    const {activeSuccess, activeError, abort, signal} = abortable({success, error})
    doFetchApi({
      path,
      headers: oldestUnchangedHeaders,
      params: oldestUnchangedParams,
      fetchOpts: {signal, ...oldestUnchangedFetchOpts}
    })
      .then(result => {
        if (convert && result) result = convert(result)
        activeSuccess(result)
      })
      .catch(err => activeError(err))
    return abort
  }, [
    success,
    error,
    path,
    convert,
    oldestUnchangedHeaders,
    oldestUnchangedParams,
    oldestUnchangedFetchOpts,
    oldestForceResult
  ])
}
