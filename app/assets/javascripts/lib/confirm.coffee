$(document).on "click", "a[data-confirm]", (evt) ->
  $a = $(@)
  if window.confirm($a.data("confirm"))
    eval($a.data("onconfirm")) if $a.data("onconfirm")
  else
    Toolbox.cancelEvent(evt)
