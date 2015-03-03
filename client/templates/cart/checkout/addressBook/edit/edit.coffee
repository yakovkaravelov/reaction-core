Template.addressBookEdit.helpers
  thisAddress: ->
    account = ReactionCore.Collections.Accounts.findOne()
    addressId = Session.get "addressBookView"
    for address in account.profile.addressBook
      if address._id is addressId
        thisAddress = address
    return thisAddress


Template.addressBookEdit.events
  'click #cancel-address-edit': () ->
    Session.set "addressBookView", "view"

  'submit form': () ->
    Session.set "addressBookView", "view"
