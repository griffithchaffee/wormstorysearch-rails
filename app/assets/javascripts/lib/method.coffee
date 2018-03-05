$(document).on "click", "a[data-method]", (evt) ->
  $a = $(@)
  linkMethod = ($a.data("method") or "GET").toUpperCase()
  formMethod = if linkMethod is "GET" then "GET" else "POST"
  # build method form
  $form = $("<form></form>")
  $form.attr("method", formMethod)
  $form.attr("action", @href)
  $form.hide()
  # build form method input
  $formMethodField = $("<input />")
  $formMethodField.attr("name", "_method")
  $formMethodField.val(linkMethod)
  $form.append($formMethodField)
  Toolbox.cancelEvent(evt)
  $("body").append($form)
  $form.submit()
