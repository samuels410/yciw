define([
  'react',
  'underscore',
  'i18n!react_files',
  'compiled/react_files/components/ShowFolder',
  'jsx/files/FilePreview',
  'jsx/files/FolderChild',
  'jsx/files/UploadDropZone',
  'jsx/files/ColumnHeaders',
  'jsx/files/CurrentUploads',
  'jsx/files/LoadingIndicator'
], function (React, _, I18n, ShowFolder, FilePreview, FolderChild, UploadDropZone, ColumnHeaders, CurrentUploads, LoadingIndicator) {

  ShowFolder.renderFilePreview = function () {
    /* Prepare and render the FilePreview if needed.
       As long as ?preview is present in the url.
    */
    if (this.getQuery().preview != null){
      return (
        <FilePreview
          isOpen={true}
          usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
          currentFolder={this.props.currentFolder}
          params={this.getParams()}
          query={this.getQuery()}
        />
      );
    }
  }

  ShowFolder.renderFolderChildOrEmptyContainer = function () {
    if(this.props.currentFolder.isEmpty()) {
      return (
        <div ref='folderEmpty' className='muted'>
          {I18n.t('this_folder_is_empty', 'This folder is empty')}
        </div>
      );
    }
    else {
      return (
        this.props.currentFolder.children(this.getQuery()).map((child) => {
          return(
            <FolderChild
              key={child.cid}
              model={child}
              isSelected={(_.indexOf(this.props.selectedItems, child)) >= 0}
              toggleSelected={ this.props.toggleItemSelected.bind(null, child) }
              userCanManageFilesForContext={this.props.userCanManageFilesForContext}
              usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
              externalToolsForContext={this.props.externalToolsForContext}
              previewItem={this.props.previewItem.bind(null, child)}
              dndOptions={this.props.dndOptions}
              modalOptions={this.props.modalOptions}
              clearSelectedItems={this.props.clearSelectedItems}
              onMove={this.props.onMove}
            />
          );
        })
      );
    }
  }

  ShowFolder.render = function () {
    var currentState = this.state || {};
    if (currentState.errorMessages) {
      return (
        <div>
          {
            currentState.errorMessages.map(function(error){
              <div className='muted'>
                {error.message}
              </div>
            })
          }
        </div>
      );
    }

    if (!this.props.currentFolder) {
      return(<div ref='emptyDiv'></div>);
    }

    var folderOrRootFolder;
    if (this.getParams().splat){
      folderOrRootFolder = 'folder';
    }else{
      folderOrRootFolder = 'rootFolder';
    }

    var foldersNextPageOrFilesNextPage = this.props.currentFolder.folders.fetchingNextPage || this.props.currentFolder.files.fetchingNextPage;

    return (
      <div role='grid' style={{flex: "1 1 auto"}} >
        <div
          ref='accessibilityMessage'
          className='ShowFolder__accessbilityMessage col-xs'
          tabIndex={0}
        >
          {I18n.t("Warning: For improved accessibility in moving files, please use the Move To Dialog option found in the menu.")}
        </div>
        <UploadDropZone currentFolder={this.props.currentFolder} />
        <CurrentUploads />
        <ColumnHeaders
          ref='columnHeaders'
          to={folderOrRootFolder}
          query={this.getQuery()}
          params={this.getParams()}
          toggleAllSelected={this.props.toggleAllSelected}
          areAllItemsSelected={this.props.areAllItemsSelected}
          usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
          splat={this.getParams().splat}
        />
        { this.renderFolderChildOrEmptyContainer() }
        <LoadingIndicator isLoading={foldersNextPageOrFilesNextPage} />
        {this.renderFilePreview() }
      </div>
    );
  }

  return React.createClass(ShowFolder);
});
