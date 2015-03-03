Template.addressBookAdd.helpers
  addressBookExists: ->
    account = ReactionCore.Collections.Accounts.findOne()
    if account?.profile?.addressBook then return true

  thisAddress: ->
    account = ReactionCore.Collections.Accounts.findOne()
    thisAddress = {'fullName': account?.profile?.name, _id: Session.get "sessionId" }
    if Session.get("address")
      thisAddress.postal = Session.get("address").zipcode
      thisAddress.country = Session.get("address").countryCode
      thisAddress.city = Session.get("address").city
      thisAddress.region = Session.get("address").state
    thisAddress

Template.addressBookAdd.events
  'click #cancel-new, form submit': () ->
    Session.set "addressBookView", "view"

  'submit form': () ->
    Session.set "addressBookView", "view"
