define([
  'underscore',
  'react',
  'jquery',
  'i18n!dashcards',
  'jsx/shared/ColorPicker',
  'classnames'
], function(_, React, $, I18n, ColorPicker, cx) {

  // ================
  //   COLOR PICKER
  // ================

  var SPACE_NEEDED_FOR_TOOLTIP = 300;

  var ColorPickerTooltip = React.createClass({

    // =================
    //     LIFECYCLE
    // =================

    componentDidMount: function () {
      this.setHandlers();
    },

    componentWillUnmount: function() {
      this.unsetHandlers();
    },

    // =================
    //      ACTIONS
    // =================

    closeIfClickedOutsideOf: function(e){
      if (this.isMounted()) {
        var container = this.getDOMNode();
        var settingsToggle = this.props.settingsToggle.getDOMNode();
        if (!$(container).is(e.target) &&
              !$(settingsToggle).is(e.target) &&
              $(container).has(e.target).length === 0
           ) {
          this.props.doneEditing();
        }
      }
    },

    checkEsc: function(e){
      if (e.keyCode == 27) {
        this.props.doneEditing();
      }
    },

    setHandlers: function(){
      $(window).resize( this.props.doneEditing );
      $(document).mouseup(this.closeIfClickedOutsideOf);
      $(document).keyup(this.checkEsc);
    },

    unsetHandlers: function(){
      $(document).unbind("keyup", this.checkEsc);
      $(document).unbind("mouseup", this.closeIfClickedOutsideOf);
      $(window).unbind("resize", this.props.doneEditing);
    },

    // =================
    //     RENDERING
    // =================

    rightOfScreen: function(){
      return $(window).width();
    },

    leftPlusElement: function(){
      var parentWidth = $(this.props.parentNode).outerWidth();
      return $(this.props.parentNode).offset().left + parentWidth;
    },

    tooltipOnRight: function(){
      var spaceToRight = this.rightOfScreen() - this.leftPlusElement();
      var spaceNeeded = SPACE_NEEDED_FOR_TOOLTIP;
      return spaceToRight >= spaceNeeded;
    },

    topPosition: function(){
      return $(this.props.parentNode).position().top - 6;
    },

    leftPosition: function(){
      return this.tooltipOnRight() ?
        (this.leftPlusElement() - 80) :
        (this.leftPlusElement() - 360)
    },

    pickerToolTipStyle: function(){
      return {
        position: 'absolute',
        top: this.topPosition(),
        left: this.leftPosition(),
        zIndex: 9999
      };
    },

    render: function () {
      var classes = cx({
        'ic-DashboardCardColorPicker': true,
        'right': !this.tooltipOnRight(),
        'horizontal': true
      });

      return (
        <div id        = {this.props.elementID}
             className = {classes}
             style     = {this.pickerToolTipStyle()} >
          <ColorPicker isOpen           = {true}
                       assetString      = {this.props.assetString}
                       afterClose       = {this.props.doneEditing}
                       afterUpdateColor = {this.props.handleColorChange}
                       hidePrompt       = {true}
                       nonModal         = {true}
                       hideOnScroll     = {false}
                       currentColor     = {this.props.backgroundColor}
                       nicknameInfo     = {this.props.nicknameInfo}
          />
        </div>
      )
    }
  })

  return ColorPickerTooltip;
});
