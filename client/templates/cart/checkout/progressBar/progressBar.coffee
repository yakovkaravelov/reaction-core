###
progressbar status: "visited first","previous visited","active","next"
###
Template.checkoutProgressBar.helpers
  loginStatus: () ->
    if getGuestLoginState()
      status = "previous visited"
    else
      status = "active"
    return status

  shippingStatus: () ->
    if (getGuestLoginState() and Session.get("billingUserAddressId") and Session.get("shippingUserAddressId"))
      status = "previous visited"
    else if getGuestLoginState()
      status = "active"
    return status

  shippingOptionStatus: () ->
    if (getGuestLoginState() and Session.get("billingUserAddressId") and Session.get("shippingUserAddressId") and Session.get("shipmentMethod"))
      status = "previous visited"
    else if (getGuestLoginState() and Session.get("billingUserAddressId") and Session.get("shippingUserAddressId"))
      status = "active"
    return status

  paymentStatus: () ->
    if (getGuestLoginState() and Session.get("billingUserAddressId") and Session.get("shippingUserAddressId") and Session.get("shipmentMethod") and Session.get("paymentMethod"))
      status = "previous visited"
    else if (getGuestLoginState() and Session.get("billingUserAddressId") and Session.get("shippingUserAddressId") and Session.get("shipmentMethod"))
      status = "active"
    return status
