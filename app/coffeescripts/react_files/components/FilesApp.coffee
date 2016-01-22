define [
  'react'
  'react-router'
  'underscore'
  'i18n!react_files'
  'compiled/str/splitAssetString'
  'jsx/files/Toolbar'
  'jsx/files/Breadcrumbs'
  'jsx/files/FolderTree'
  'jsx/files/FilesUsage'
  '../mixins/MultiselectableMixin'
  '../mixins/dndMixin'
  '../modules/filesEnv'
], (React, ReactRouter, _, I18n, splitAssetString, Toolbar, Breadcrumbs, FolderTree, FilesUsage, MultiselectableMixin, dndMixin, filesEnv) ->


  FilesApp =
    displayName: 'FilesApp'

    mixins: [ ReactRouter.State ]

    onResolvePath: ({currentFolder, rootTillCurrentFolder, showingSearchResults, searchResultCollection, pathname}) ->
      updatedModels = @state.updatedModels

      if currentFolder && !showingSearchResults
        updatedModels.forEach (model, index, models) ->
          if currentFolder.id.toString() isnt model.get("folder_id") and
             removedModel = currentFolder.files.findWhere({id: model.get("id")})
            currentFolder.files.remove removedModel
            models.splice(index, 1)

      @setState
        currentFolder: currentFolder
        key: @getHandlerKey()
        pathname: pathname
        rootTillCurrentFolder: rootTillCurrentFolder
        showingSearchResults: showingSearchResults
        selectedItems: []
        searchResultCollection: searchResultCollection
        updatedModels: updatedModels

    getInitialState: ->
      {
        updatedModels: []
        currentFolder: null
        rootTillCurrentFolder: null
        showingSearchResults: false
        showingModal: false
        pathname: window.location.pathname
        key: @getHandlerKey()
        modalContents: null  # This should be a React Component to render in the modal container.
      }

    mixins: [MultiselectableMixin, dndMixin, ReactRouter.Navigation, ReactRouter.State]

    # For react-router handler keys
    getHandlerKey: ->
      childDepth = 1
      childName = @getRoutes()[childDepth].name
      id = @getParams().id
      key = childName + id
      key

    # for MultiselectableMixin
    selectables: ->
      if @state.showingSearchResults
        @state.searchResultCollection.models
      else
        @state.currentFolder.children(@getQuery())

    onMove: (modelsToMove) ->
      updatedModels = _.uniq(@state.updatedModels.concat(modelsToMove), "id")
      @setState {updatedModels}

    getPreviewQuery: ->
      retObj =
        preview: @state.selectedItems[0]?.id or true
      if @state.selectedItems.length > 1
        retObj.only_preview = @state.selectedItems.map((item) -> item.id).join(',')
      if @getQuery()?.search_term
        retObj.search_term = @getQuery().search_term
      retObj

    getPreviewRoute: ->
      if @getQuery()?.search_term
        'search'
      else if @state.currentFolder?.urlPath()
        'folder'
      else
        'rootFolder'

    openModal: (contents, afterClose) ->
      @setState
        modalContents: contents
        showingModal: true
        afterModalClose: afterClose

    closeModal: ->
      @setState(showingModal: false, -> @state.afterModalClose())

    previewItem: (item) ->
      @clearSelectedItems =>
        @toggleItemSelected item, null, =>
          params = {splat: @state.currentFolder?.urlPath()}
          @transitionTo(@getPreviewRoute(), params, @getPreviewQuery())
