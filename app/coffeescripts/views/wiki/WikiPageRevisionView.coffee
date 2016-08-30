define [
  'jquery'
  'underscore'
  'Backbone'
  'jst/wiki/WikiPageRevision'
], ($, _, Backbone, template) ->

  class WikiPageRevisionView extends Backbone.View
    tagName: 'li'
    className: 'revision clearfix'
    template: template

    events:
      'click .restore-link': 'restore'
      'keydown .restore-link': 'restore'

    els:
      '.revision-details': '$revisionButton'

    initialize: ->
      super
      @model.on 'change', => @render()

    render: ->
      hadFocus = @$revisionButton?.is(':focus')
      super
      if (hadFocus)
        @$revisionButton.focus()

    afterRender: ->
      super
      @$el.toggleClass('selected', !!@model.get('selected'))
      @$el.toggleClass('latest', !!@model.get('latest'))

    toJSON: ->
      latest = @model.collection?.latest
      json = _.extend {}, super,
        IS:
          LATEST: !!@model.get('latest')
          SELECTED: !!@model.get('selected')
          LOADED: !!@model.get('title') && !!@model.get('body')
      json.IS.SAME_AS_LATEST = json.IS.LOADED && (@model.get('title') == latest?.get('title')) && (@model.get('body') == latest?.get('body'))
      json.updated_at = $.datetimeString(json.updated_at)
      json.edited_by = json.edited_by?.display_name
      json

    windowLocation: ->
      return window.location;

    restore: (ev) ->
      if (ev?.type == 'keydown')
        return if ev.keyCode != 13
      ev?.preventDefault()
      @model.restore().done (attrs) =>
        if @pages_path
          @windowLocation().href = "#{@pages_path}/#{attrs.url}/revisions"
        else
          @windowLocation().reload()
