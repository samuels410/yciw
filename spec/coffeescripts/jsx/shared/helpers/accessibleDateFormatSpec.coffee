define [
  'jsx/shared/helpers/accessibleDateFormat'
], (accessibleDateFormat) ->

  module 'accessibleDateFormat',
    setup: ->

  test 'it pulls out the links from an Axios response header', ->
    ok accessibleDateFormat().match(/YYYY/)
    ok accessibleDateFormat().match(/hh:mm/)
