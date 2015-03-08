Template.cartCompleted.helpers
  orderStatus: () ->
    status = this?.status || "processing"
    if status is "new" then status = i18n.t('cartCompleted.submitted')
    return status
