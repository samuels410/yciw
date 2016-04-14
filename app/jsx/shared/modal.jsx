define([
  'react',
  'jquery',
  'underscore',
  'compiled/fn/preventDefault',
  'react-modal',
  './modal-content',
  './modal-buttons',
], function (React, $, _, preventDefault,  ReactModal, ModalContent, ModalButtons) {

  var Modal = React.createClass({

    getInitialState() {
      return {
        modalIsOpen: this.props.isOpen
      }
    },
    getDefaultProps(){
      return {
        className: "ReactModal__Content--canvas" // Override with "ReactModal__Content--canvas ReactModal__Content--mini-modal" for a mini modal
      }
    },
    componentWillReceiveProps(props){
      this.setState({modalIsOpen: props.isOpen});
    },

    openModal() {
      this.setState({modalIsOpen: true});
    },
    closeModal() {
      this.setState({modalIsOpen: false}, function(){
        this.props.onRequestClose();
        $(this.getAppElement()).removeAttr('aria-hidden');
      });
    },
    closeWithX() {
      if(_.isFunction(this.props.closeWithX))
        this.props.closeWithX()
      this.closeModal();
    },
    onSubmit(){
      var promise = this.props.onSubmit();
      $(this.refs.modal.getDOMNode()).disableWhileLoading(promise);
    },
    getAppElement () {
      // Need to wait for the dom to load before we can get the default #application dom element
      return this.props.appElement || document.getElementById('application');
    },
    processMultipleChildren(props){
      var content = null;
      var buttons = null;

      React.Children.forEach(props.children, function(child){
        if(child.type == ModalContent){
          content = child;
        }
        if(child.type == ModalButtons){
          buttons = child;
        }
      });

      // Warning if you don't include a component of the right type
      if(content == null){
        console.warn('You should wrap your content in the modal-content component');
      }
      if(buttons == null){
        console.warn('You should wrap your buttons in the modal-buttons component');
      }

      if(this.props.onSubmit){
        return (
          <form className="ModalForm" onSubmit={preventDefault(this.onSubmit)}>
            { [content, buttons] }
          </form>
        )
      }
      else
      {
        return [content, buttons]; // This order needs to be maintained
      }
    },
    render() {
      return (
        <div className="canvasModal">
          <ReactModal
                 ariaHideApp={this.state.modalIsOpen}
                 isOpen={this.state.modalIsOpen}
                 onRequestClose={this.closeModal}
                 className={this.props.className}
                 overlayClassName={this.props.overlayClassName}
                 appElement={this.getAppElement()}>
            <div ref="modal" className="ReactModal__Layout">

              <div className="ReactModal__Header">
                <div className="ReactModal__Header-Title">
                  <h4>{this.props.title}</h4>
                </div>
                <div className="ReactModal__Header-Actions">
                  <button ref="closeWithX" className="Button Button--icon-action" type="button" onClick={this.closeWithX}>
                    <i className="icon-x"></i>
                    <span className="screenreader-only">Close</span>
                  </button>
                </div>
              </div>

              {this.processMultipleChildren(this.props)}

            </div>
          </ReactModal>
        </div>
      );
    }

  });

  return Modal;
});
