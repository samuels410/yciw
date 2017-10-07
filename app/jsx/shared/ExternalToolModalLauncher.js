/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import _ from 'underscore'
import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import Modal from 'jsx/shared/modal'
import ModalContent from 'jsx/shared/modal-content'
import I18n from 'i18n!external_tools'

export default React.createClass({
  displayName: 'ExternalToolModalLauncher',

  propTypes: {
    tool: PropTypes.object,
    isOpen: PropTypes.bool.isRequired,
    onRequestClose: PropTypes.func.isRequired,
    contextType: PropTypes.string.isRequired,
    contextId: PropTypes.number.isRequired,
    launchType: PropTypes.string.isRequired,
  },

  getInitialState () {
    const dimensions = this.getLaunchDimensions();

    return {
      beforeExternalContentAlertClass: 'screenreader-only',
      afterExternalContentAlertClass: 'screenreader-only',
      modalStyle: this.getModalStyle(dimensions),
      modalBodyStyle: this.getModalBodyStyle(dimensions),
      modalLaunchStyle: this.getModalLaunchStyle(dimensions),
    }
  },

  componentDidMount () {
    $(window).on('externalContentReady', this.onExternalToolCompleted);
    $(window).on('externalContentCancel', this.onExternalToolCompleted);
  },

  componentWillUnmount () {
    $(window).off('externalContentReady', this.onExternalToolCompleted);
    $(window).off('externalContentCancel', this.onExternalToolCompleted);
  },

  onExternalToolCompleted () {
    this.props.onRequestClose();
  },

  getIframeSrc () {
    if (this.props.isOpen && this.props.tool) {
      return [
        '/', this.props.contextType, 's/',
        this.props.contextId,
        '/external_tools/', this.props.tool.definition_id,
        '?display=borderless&launch_type=',
        this.props.launchType,
      ].join('');
    }
  },

  getLaunchDimensions () {
    const dimensions = {
      'width': 700,
      'height': 700,
    };

    if (
      this.props.isOpen &&
      this.props.tool &&
      this.props.launchType &&
      this.props.tool['placements'] &&
      this.props.tool['placements'][this.props.launchType]) {

      const placement = this.props.tool['placements'][this.props.launchType];

      if (placement.launch_width) {
        dimensions.width = placement.launch_width;
      }

      if (placement.launch_height) {
        dimensions.height = placement.launch_height;
      }
    }

    return dimensions;
  },

  getModalLaunchStyle (dimensions) {
    return {
      ...dimensions,
      border: 'none',
    };
  },

  getModalBodyStyle (dimensions) {
    return {
      ...dimensions,
      padding: 0,
      display: 'flex',
      flexDirection: 'column',
    };
  },

  getModalStyle (dimensions) {
    return {
      width: dimensions.width,
    };
  },

  handleAlertBlur (event) {
    const dimensions = this.getLaunchDimensions();
    const newState = {
      modalLaunchStyle: {
        ...this.getModalLaunchStyle(dimensions),
        border: 'none',
      }
    }
    if (event.target.className.search('before') > -1) {
      newState.beforeExternalContentAlertClass = 'screenreader-only'
    } else if (event.target.className.search('after') > -1) {
      newState.afterExternalContentAlertClass = 'screenreader-only'
    }
    this.setState(newState)
  },

  handleAlertFocus (event) {
    const newState = {
      modalLaunchStyle: {
        ...this.state.modalLaunchStyle,
        width: this.iframe.offsetWidth - 4,
        border: '2px solid #008EE2'
      }
    }
    if (event.target.className.search('before') > -1) {
      newState.beforeExternalContentAlertClass = ''
    } else if (event.target.className.search('after') > -1) {
      newState.afterExternalContentAlertClass = ''
    }
    this.setState(newState)
  },

  render () {
    const beforeAlertStyles = `before_external_content_info_alert ${this.state.beforeExternalContentAlertClass}`
    const afterAlertStyles = `after_external_content_info_alert ${this.state.afterExternalContentAlertClass}`

    return (
      <Modal className="ReactModal__Content--canvas"
        overlayClassName="ReactModal__Overlay--canvas"
        style={this.state.modalStyle}
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
        title={this.props.title}
      >
        <ModalContent style={this.state.modalBodyStyle}>
          <div
            onFocus={this.handleAlertFocus}
            onBlur={this.handleAlertBlur}
            className={beforeAlertStyles}
            tabIndex="0"
            ref={(e) => { this.beforeAlert = e; }}
          >
            <div className="ic-flash-info">
              <div className="ic-flash__icon" aria-hidden="true">
                <i className="icon-info" />
              </div>
              {I18n.t('The following content is partner provided')}
            </div>
          </div>
          <iframe
            src={this.getIframeSrc()}
            style={this.state.modalLaunchStyle}
            tabIndex={0}
            ref={(e) => { this.iframe = e; }}
          />
          <div
            onFocus={this.handleAlertFocus}
            onBlur={this.handleAlertBlur}
            className={afterAlertStyles}
            tabIndex="0"
            ref={(e) => { this.afterAlert = e; }}
          >
            <div className="ic-flash-info">
              <div className="ic-flash__icon" aria-hidden="true">
                <i className="icon-info" />
              </div>
              {I18n.t('The preceding content is partner provided')}
            </div>
          </div>
        </ModalContent>
      </Modal>
    );
  }
});
