Template.cartCheckout.helpers
  cart: ->
    # TODO:
    # some cleanup for checkout sessions
    # this should prevent steps selected when a user has been here
    # then switched accounts, or server restarted
    # and the session values are incorrect
    # account = ReactionCore.Collections.Accounts.findOne()
    # unless account?.profile?.addressBook
    #   Session.set("billingUserAddressId", undefined)
    #   Session.set("shippingUserAddressId", undefined)

    return Cart.findOne()

  loginStatus: () ->
    if !getGuestLoginState()
      status = false
    else
      status = "checkout-step-badge-completed"
    return status

  addressStatus: () ->
    if (getGuestLoginState() and Session.get("billingUserAddressId") and Session.get("shippingUserAddressId"))
      status = "checkout-step-badge-completed"
    else if getGuestLoginState()
      status =  "checkout-step-badge"
    else
      status = false
    return status

  shippingOptionStatus: () ->
    if (getGuestLoginState() and Session.get("billingUserAddressId") and Session.get("shippingUserAddressId") and Session.get("shipmentMethod"))
      status = "checkout-step-badge-completed"
    else if (getGuestLoginState() and Session.get("billingUserAddressId") and Session.get("shippingUserAddressId"))
      status = "checkout-step-badge"
    else
      status = false
    return status

  checkoutReviewStatus: () ->
    if (getGuestLoginState() and Session.get("billingUserAddressId") and Session.get("shippingUserAddressId") and Session.get("shipmentMethod"))
      status = true
    return status

Template.cartCheckout.rendered = ->
  Session.set "displayCartDrawer", false
