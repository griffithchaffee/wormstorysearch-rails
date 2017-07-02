Toolbox = {}

Toolbox.cancelEvent = (evt) ->
  $evt = $.Event(evt)
  $evt.preventDefault()
  $evt.stopImmediatePropagation()
  $evt

Toolbox.timer = (time, func) ->
  setTimeout(func, time)

Toolbox.isTouchDevice = ->
  "ontouchstart" of window or navigator.maxTouchPoints

@Toolbox = Toolbox
