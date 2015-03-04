# Additional match method Optional or null, undefined
Match.OptionalOrNull = (pattern) -> Match.OneOf undefined, null, pattern

###
#  getCurrentCart(sessionId)
#  create, merge the session and user carts and return cart cursor
#
# There should be one cart for each independent, non logged in user session
# When a user logs in that cart now belongs to that user and we use the a single user cart.
# If they are logged in on more than one devices, regardless of session, the user cart will be used
# If they had more than one cart, on more than one device,logged in at seperate times then merge the carts
#
###
@getCurrentCart = (sessionId, shopId, userId) ->
  check sessionId, String
  check shopId, Match.OptionalOrNull(String)
  check userId, Match.OptionalOrNull(String)

  shopid = shopId || ReactionCore.getShopId(@)
  userId = userId || "" # no null
  Cart = ReactionCore.Collections.Cart

  # try to create cart
  try
    sessionCart = Cart.findOne sessionId: sessionId, shopId: shopId
    userCart = Cart.findOne userId: userId, shopId: shopId

    ReactionCore.Events.debug "** getCurrentCart method called **"
    ReactionCore.Events.debug "starting cart check for session: " + sessionId
    ReactionCore.Events.debug "we're checking carts for user: " + userId
    ReactionCore.Events.debug "session cart: " + sessionCart?._id
    ReactionCore.Events.debug "user cart: " + userCart?._id

    #
    # if there isnt a sessionCart, create and return sessionCart
    #
    if !sessionCart
      newCartId = Cart.insert {sessionId: sessionId, shopId: shopId, userId: userId}
      ReactionCore.Events.debug "Created new session cart", newCartId
      currentCart = Cart.find newCartId
      return currentCart

    #
    # if sessionCart just logged out, remove sessionId and create new sessionCart
    #
    if !userId and userCart?.userId
      Cart.update userCart._id, $set: sessionId: null
      ReactionCore.Events.debug "User cart and session cart the same"
      currentCart =  Cart.find sessionCart._id
      return currentCart
    #
    # if sessionCart is authenticated add user to cart
    #
    if userId and !userCart # Do we have an existing user cart?
      Cart.update sessionCart._id, $set: userId: userId
      ReactionCore.Events.debug "Updated session cart", sessionCart._id, "with userId"
      currentCart = Cart.find userId: userId
      return currentCart
    #
    # if the session cart has a userId, but we're not authenticated,
    # remove sessionId from user cart and create new session cart
    #
    if !userId and sessionCart?.userId
      Cart.update sessionCart._id, $set: sessionId: ''
      # create a new sessionCart for logged out user
      newCartId = Cart.insert {sessionId: sessionId, shopId: shopId}
      ReactionCore.Events.debug "Created new session cart", newCartId
      currentCart = Cart.find newCartId
      return currentCart
    #
    # if using userCart, copy sessionCart into userCart and remove sessionCart items
    #
    if userCart?.items and sessionCart?.items
      unless _.isEqual userCart?.items, sessionCart?.items
        if sessionCart?.items.length >= (userCart?.items.length || 0)
          ReactionCore.Events.debug "Merging user cart", userCart._id, "into session cart", sessionCart._id
          Cart.update userCart._id, $addToSet: items: $each: sessionCart.items
          # do we want a logged out user to have no items,
          # or to have the items they had before logging in?
          Cart.update sessionCart._id, $set: 'items': ''
        currentCart = Cart.find userId: userId
        return currentCart

    # all condition indicate a regular session cart
    if userId
      ReactionCore.Events.info "Using current user cart: " + userCart._id
      return Cart.find userCart._id
    else
      ReactionCore.Events.info "Using current session cart: " + sessionCart._id
      return Cart.find sessionCart._id

  #if all else fails, report error.
  catch error
    ReactionCore.Events.warn "getCurrentCart error: ", error

###
#  Cart Methods
###
Meteor.methods
  ###
  # when we add an item to the cart, we want to break all relationships
  # with the existing item. We want to fix price, qty, etc into history
  # however, we could check reactively for price /qty etc, adjustments on
  # the original and notify them
  ###
  addToCart: (cartSession, productId, variantData, quantity) ->
    check cartSession, {sessionId: String, userId: Match.OneOf(String, null)}
    check productId, String
    check variantData, Object
    check quantity, String
    cartSession.userId = cartSession.userId || "" # no null query
    shopId = ReactionCore.getShopId(@)

    # determine if cart is guest or user
    if cartSession.userId
      # user cart
      currentCart = Cart.findOne 'userId': @userId, 'shopId': shopId
    else
      # sessionCart
      currentCart = Cart.findOne 'sessionId': cartSession.sessionId, 'shopId': shopId

    if !currentCart
      getCurrentCart cartSession.sessionId
      currentCart = Cart.findOne 'sessionId': cartSession.sessionId,

    # TODO: refactor to check currentCart instead of another findOne
    cartVariantExists = Cart.findOne _id: currentCart._id, "items.variants._id": variantData._id
    if cartVariantExists
      Cart.update
        _id: currentCart._id,
        "items.variants._id": variantData._id,
        { $set: {updatedAt: new Date()}, $inc: {"items.$.quantity": quantity}},
      (error, result) ->
        ReactionCore.Events.info "error adding to cart" if error
        ReactionCore.Events.info Cart.simpleSchema().namedContext().invalidKeys() if error
    # add new cart items
    else
      Cart.update _id: currentCart._id,
        $addToSet:
          items:
            _id: Random.id()
            productId: productId
            quantity: quantity
            variants: variantData
      , (error, result) ->
        ReactionCore.Events.info "error adding to cart" if error
        ReactionCore.Events.warn error if error

  ###
  # removes a variant from the cart
  ###
  removeFromCart: (sessionId, cartId, variantData) ->
    check sessionId, String
    check cartId, String
    check variantData, Object
    console.log @userId
    # We select on sessionId or userId, too, for security
    return Cart.update
      _id: cartId
      $or: [
        {userId: @userId}
        {sessionId: sessionId}
      ]
    , {$pull: {"items": {"variants": variantData} } }


  ###
  # adjust inventory when an order is placed
  ###
  inventoryAdjust: (orderId) ->
    check orderId, String

    order = Orders.findOne orderId
    return false unless order
    for product in order.items
      Products.update {_id: product.productId, "variants._id": product.variants._id}, {$inc: {"variants.$.inventoryQuantity": -product.quantity }}
    return

  ###
  # when a payment is processed we want to copy the cart
  # over to an order object, and give the user a new empty
  # cart. reusing the cart schema makes sense, but integrity of
  # the order, we don't want to just make another cart item
  ###
  copyCartToOrder: (cartId) ->
    check cartId, String
    # extra validation + transform methods
    cart = ReactionCore.Collections.Cart.findOne(cartId)
    invoice = {}

    # transform cart pricing into order invoice
    invoice.shipping = cart.cartShipping()
    invoice.subtotal = cart.cartSubTotal()
    invoice.taxes = cart.cartTaxes()
    invoice.discounts = cart.cartDiscounts()
    invoice.total =  cart.cartTotal()
    cart.payment.invoices = [invoice]

    # todo: these defaults should be done in schema
    now = new Date()
    cart.createdAt = now
    cart.updatedAt = now

    # set workflow status
    cart.state = "orderCreated"
    cart.status = "new"

    ###
    # final sanity check
    # todo add `check cart, ReactionCore.Schemas.Order`
    # and add some additional validation that all is good
    # and no tampering has occurred
    ###

    try
      orderId = Orders.insert cart
      Cart.remove _id: cart._id
      ReactionCore.Events.info "Closing session for " + cart.sessionId
      ServerSessions.remove(cart.sessionId)

    catch error
      ReactionCore.Events.info "error in order insert"
      ReactionCore.Events.warn error, Orders.simpleSchema().namedContext().invalidKeys()
      return error

    # return new orderId
    return orderId
