Toolbox = {}
@Toolbox = Toolbox

# simplify event cancellation
Toolbox.cancelEvent = (evt) ->
  $evt = $.Event(evt)
  $evt.preventDefault()
  $evt.stopImmediatePropagation()
  $evt

# simplify timer argument order
Toolbox.timer = (time, func) ->
  setTimeout(func, time)

# determine if browser is touch device
Toolbox.isTouchDevice = ->
  "ontouchstart" of window or navigator.maxTouchPoints

# UTC offset
Toolbox.getTimeZoneOffset = ->
  # get UTC Offset
  exactOffset = new Date().getTimezoneOffset()
  hourOffset = -(exactOffset / 60)
