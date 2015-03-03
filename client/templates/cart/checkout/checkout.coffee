Template.cartCheckout.helpers
  cart: ->
    return Cart.findOne()

  loginStatus: () ->
    loginStatus = Session.equals "guest-checkout", true || Meteor.userId()
    if !loginStatus
      status = false
    else
      status = "checkout-step-badge-completed"
    return status

  addressStatus: () ->
    loginStatus = Session.equals "guest-checkout", true || Meteor.userId()
    if (loginStatus and Session.get("billingUserAddressId") and Session.get("shippingUserAddressId"))
      status = "checkout-step-badge-completed"
    else if loginStatus
      status =  "checkout-step-badge"
    else
      status = false
    return status

  shippingOptionStatus: () ->
    loginStatus = Session.equals "guest-checkout", true || Meteor.userId()
    if (loginStatus and Session.get("billingUserAddressId") and Session.get("shippingUserAddressId") and Session.get("shipmentMethod"))
      status = "checkout-step-badge-completed"
    else if (loginStatus and Session.get("billingUserAddressId") and Session.get("shippingUserAddressId"))
      status = "checkout-step-badge"
    else
      status = false
    return status

  checkoutReviewStatus: () ->
    loginStatus = Session.equals "guest-checkout", true || Meteor.userId()
    if (loginStatus and Session.get("billingUserAddressId") and Session.get("shippingUserAddressId") and Session.get("shipmentMethod"))
      status = true
    return status

Template.cartCheckout.rendered = ->
  Session.set "displayCartDrawer", false
