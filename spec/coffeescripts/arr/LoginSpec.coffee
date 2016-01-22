define [
  'login'
],(loginUtils)->

  module "Login page helper functions - email validation"

  test 'it passes normal emails', ->
    ok(loginUtils.validResetEmail('user@example.com'))

  test 'its ok with emails to long domains', ->
    ok(loginUtils.validResetEmail('user@example.asdf.qwerty.com'))

  test 'it supports capital letters', ->
    ok(loginUtils.validResetEmail('UsErGuY@eXaMpLe.CoM'))

  test 'it supports numbers', ->
    ok(loginUtils.validResetEmail('user42@example42.com'))

  test 'it fails blank strings', ->
    ok(!loginUtils.validResetEmail(''))

  test 'it fails if you forget the @', ->
    ok(!loginUtils.validResetEmail('userexample.com'))

  test 'it fails whitespace', ->
    ok(!loginUtils.validResetEmail('       '))
