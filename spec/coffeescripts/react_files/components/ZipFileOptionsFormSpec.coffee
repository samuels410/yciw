define [
  'jquery'
  'underscore'
  'react'
  'react-dom'
  'jsx/files/ZipFileOptionsForm'
  ], ($, _, React, ReactDOM, ZipFileOptionsForm ) ->

    TestUtils = React.addons.TestUtils

    module "ZipFileOptionsForm"

    test "creates a display message based on fileOptions ", ->
      props = {
        fileOptions: {file: {name: 'neat_file'}}
        onZipOptionsResolved: () ->
      }

      zFOF = TestUtils.renderIntoDocument(React.createElement(ZipFileOptionsForm, props))
      equal $(".modalMessage").text(), "Would you like to expand the contents of \"neat_file\" into the current folder, or upload the zip file as is?", "message is displayed"
      ReactDOM.unmountComponentAtNode(zFOF.getDOMNode().parentNode)

    test "handleExpandClick expands zip", ->
      zipOptionsResolvedStub = @stub()

      props = {
        fileOptions: {file: 'the_file_obj' }
        onZipOptionsResolved: zipOptionsResolvedStub
      }

      zFOF = TestUtils.renderIntoDocument(React.createElement(ZipFileOptionsForm, props))
      TestUtils.Simulate.click($(".btn-primary")[0])

      ok zipOptionsResolvedStub.calledWithMatch({file: 'the_file_obj', expandZip: false}), "resolves with correct options"

      ReactDOM.unmountComponentAtNode(zFOF.getDOMNode().parentNode)

    test "handleUploadClick uploads zip", ->
      zipOptionsResolvedStub = @stub()

      props = {
        fileOptions: {file: 'the_file_obj' }
        onZipOptionsResolved: (options)->
          console.log("Called With ", options)
          zipOptionsResolvedStub(options)
      }

      zFOF = TestUtils.renderIntoDocument(React.createElement(ZipFileOptionsForm, props))
      TestUtils.Simulate.click($(".btn")[0])

      ok zipOptionsResolvedStub.calledWithMatch({file: 'the_file_obj', expandZip: true}), "resolves with correct options"

      ReactDOM.unmountComponentAtNode(zFOF.getDOMNode().parentNode)
