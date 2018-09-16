$(document).on "submit", "form", (evt) ->
  $form = $(@)
  # prevent double form submits
  if $form.hasClass("timeout")
    Toolbox.cancelEvent(evt)
  else
    $form.addClass("timeout")
    Toolbox.timer 1000, -> $form.removeClass("timeout")
  # disable submit button
  $form.find("input[type=submit][data-disable]").each (i, submit) ->
    $submit = $(submit)
    disableText = $submit.data("disable")
    $submit.val(disableText) if disableText

$(document).on "click", "a[data-disable]", (evt) ->
  $a = $(@)
  $a.addClass("disabled")
  disableText = $a.data("disable")
  $a.html(disableText)

$(document).on "click", "a.disabled", (evt) ->
  Toolbox.cancelEvent(evt)
