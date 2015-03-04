Template.loginInline.helpers
  canCheckoutAsGuest: ->
    return ReactionCore.canCheckoutAsGuest

Template.loginInline.events
  'click .continue-guest': () ->
    Session.set "guestCheckoutFlow", true
