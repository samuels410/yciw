/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react'
import keycode from 'keycode'
import I18n from 'i18n!act_as'

import Modal, {ModalHeader, ModalBody} from 'instructure-ui/lib/components/Modal'
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent'
import Container from 'instructure-ui/lib/components/Container'
import Typography from 'instructure-ui/lib/components/Typography'
import Button from 'instructure-ui/lib/components/Button'
import Avatar from 'instructure-ui/lib/components/Avatar'
import Spinner from 'instructure-ui/lib/components/Spinner'
import Table from 'instructure-ui/lib/components/Table'

import ActAsMask from './ActAsMask'
import ActAsPanda from './ActAsPanda'

export default class ActAsModal extends React.Component {
  static propTypes = {
    user: React.PropTypes.shape({
      name: React.PropTypes.string,
      short_name: React.PropTypes.string,
      id: React.PropTypes.oneOfType([React.PropTypes.number, React.PropTypes.string]),
      avatar_image_url: React.PropTypes.string,
      sortable_name: React.PropTypes.string,
      email: React.PropTypes.string,
      login_id: React.PropTypes.oneOfType([React.PropTypes.number, React.PropTypes.string]),
      sis_id: React.PropTypes.oneOfType([React.PropTypes.number, React.PropTypes.string]),
      integration_id: React.PropTypes.oneOfType([React.PropTypes.number, React.PropTypes.string])
    }).isRequired
  }

  constructor (props) {
    super(props)

    this.state = {
      isLoading: false
    }

    this._button = null
  }

  componentWillMount () {
    if (window.location.href === document.referrer) {
      this.setState({isLoading: true})
      window.location.href = '/'
    }
  }

  handleModalRequestClose = () => {
    const defaultUrl = '/'

    if (!document.referrer) {
      window.location.href = defaultUrl
    } else {
      const currentPage = window.location.href
      window.history.back()
      // if we go nowhere, modal was opened in new tab,
      // and we return to the dashboard by default
      setTimeout(() => {
        if (window.location.href === currentPage) {
          window.location.href = defaultUrl
        }
      }, 1000)
    }
    this.setState({isLoading: true})
  }

  handleClick = (e) => {
    if (e.keyCode && (e.keyCode === keycode.codes.space || e.keyCode === keycode.codes.enter)) {
      // for the data to post correctly, we need an actual click
      // on enter and space press, we simulate a click event and return
      e.target.click()
      return
    }
    this.setState({isLoading: true})
  }

  renderUserTable () {
    const user = this.props.user
    return (
      <Table caption={<ScreenReaderContent>{I18n.t('User details')}</ScreenReaderContent>}>
        <thead>
          <tr>
            <th><ScreenReaderContent>{I18n.t('Category')}</ScreenReaderContent></th>
            <th><ScreenReaderContent>{I18n.t('User information')}</ScreenReaderContent></th>
          </tr>
        </thead>
        <tbody>
          {this.renderUserRow(I18n.t('Full Name:'), user.name)}
          {this.renderUserRow(I18n.t('Display Name:'), user.short_name)}
          {this.renderUserRow(I18n.t('Sortable Name:'), user.sortable_name)}
          {this.renderUserRow(I18n.t('Default Email:'), user.email)}
          {this.renderUserRow(I18n.t('Login ID:'), user.login_id)}
          {this.renderUserRow(I18n.t('SIS ID:'), user.sis_id)}
          {this.renderUserRow(I18n.t('Integration ID:'), user.integration_id)}
        </tbody>
      </Table>

    )
  }

  renderUserRow (category, info) {
    return (
      <tr>
        <td>
          <Typography size="small">{category}</Typography>
        </td>
        <td>
          <Container
            as="div"
            textAlign="end"
          >
            <Typography
              size="small"
              weight="bold"
            >
              {info}
            </Typography>
          </Container>
        </td>
      </tr>
    )
  }

  render () {
    const user = this.props.user

    return (
      <span>
        <Modal
          onRequestClose={this.handleModalRequestClose}
          transition="fade"
          size="fullscreen"
          label={I18n.t('Act as User')}
          closeButtonLabel={I18n.t('Close')}
          isOpen
        >
          <ModalHeader>
            <Typography size="large">
              {I18n.t('Act as User')}
            </Typography>
          </ModalHeader>
          <ModalBody>
            {this.state.isLoading ?
              <div className="ActAs__loading">
                <Spinner title={I18n.t('Loading')} />
              </div>
            :
              <div className="ActAs__body">
                <div className="ActAs__svgContainer">
                  <div className="ActAs__svg">
                    <ActAsPanda />
                  </div>
                  <div className="ActAs__svg">
                    <ActAsMask />
                  </div>
                </div>
                <div className="ActAs__text">
                  <Container
                    as="div"
                    size="small"
                  >
                    <Container
                      as="div"
                      textAlign="center"
                      padding="0 0 x-small 0"
                    >
                      <Typography
                        size="x-large"
                        weight="light"
                      >
                        {I18n.t('Act as %{name}', { name: user.short_name })}
                      </Typography>
                    </Container>
                    <Container
                      as="div"
                      textAlign="center"
                    >
                      <Typography
                        lineHeight="condensed"
                        size="small"
                      >
                        {I18n.t('"Act as" is essentially logging in as this user ' +
                          'without a password. You will be able to take any action ' +
                          'as if you were this user, and from other users\' points ' +
                          'of views, it will be as if this user performed them.')}
                      </Typography>
                    </Container>
                    <Container
                      as="div"
                      textAlign="center"
                    >
                      <Avatar
                        name={user.short_name}
                        src={user.avatar_image_url}
                        size="small"
                        margin="medium 0 x-small 0"
                      />
                    </Container>
                    <Container
                      as="div"
                      textAlign="center"
                    >
                      {this.renderUserTable()}
                    </Container>
                    <Container
                      as="div"
                      textAlign="center"
                    >
                      <Button
                        variant="primary"
                        href={`/users/${user.id}/masquerade`}
                        data-method="post"
                        onClick={this.handleClick}
                        margin="large 0 0 0"
                      >
                        {I18n.t('Proceed')}
                      </Button>
                    </Container>
                  </Container>
                </div>
              </div>
            }
          </ModalBody>
        </Modal>
      </span>
    )
  }
}
