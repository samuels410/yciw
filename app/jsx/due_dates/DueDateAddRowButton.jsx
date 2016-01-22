define([
  'react',
  'i18n!assignments'
], (React, I18n) => {

  var DueDateAddRowButton = React.createClass({

    propTypes: {
      display: React.PropTypes.bool.isRequired
    },

    render(){
      if(!this.props.display){ return null }

      return(
        <button id        = "add_due_date"
                ref       = "addButton"
                className = "Button Button--add-row"
                onClick   = {this.props.handleAdd}
                type      = "button" >
          <i className="icon-plus" />
          <span className="screenreader-only">{I18n.t("Add new set of due dates")}</span>
          <span aria-hidden="true">{I18n.t("Add")}</span>
        </button>
      )
    }
  })

  return DueDateAddRowButton
});