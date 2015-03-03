loginButtonsSession = Accounts._loginButtonsSession

Template.checkoutLogin.rendered = ->
  # initial screen in checkout should be to create an account
  loginButtonsSession.set "inSignupFlow", true
