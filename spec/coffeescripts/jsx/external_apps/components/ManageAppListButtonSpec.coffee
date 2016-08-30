define [
  'react'
  'react-modal'
  'jsx/external_apps/components/ManageAppListButton',
], (React, Modal, ManageAppListButton) ->

  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  Modal.setAppElement(wrapper)

  onUpdateAccessToken = ->

  createElement = ->
    React.createElement(ManageAppListButton, {
      onUpdateAccessToken: onUpdateAccessToken
    })

  renderComponent = ->
    React.render(createElement(), wrapper)

  test 'open and close modal', ->
    component = renderComponent({})
    Simulate.click(component.getDOMNode())
    ok component.state.modalIsOpen, 'modal is open'
    ok component.refs.btnClose
    ok component.refs.btnUpdateAccessToken
    Simulate.click(component.refs.btnClose.getDOMNode())
    ok !component.state.modalIsOpen, 'modal is not open'
    ok !component.refs.btnClose
    ok !component.refs.btnUpdateAccessToken

  test 'maskedAccessToken', ->
    component = renderComponent({})
    equal component.maskedAccessToken(null), null
    equal component.maskedAccessToken('token'), 'token...'
