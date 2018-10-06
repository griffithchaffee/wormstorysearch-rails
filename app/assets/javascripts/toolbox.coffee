Toolbox = {}
@Toolbox = Toolbox

# stop event but let it bubble
Toolbox.stopEvent = (evt) ->
  $evt = $.Event(evt)
  $evt.preventDefault()
  $evt

# stop event and bubble
Toolbox.cancelEvent = (evt) ->
  $evt = Toolbox.stopEvent(evt)
  $evt.stopImmediatePropagation()
  $evt

# simplify timer argument order
Toolbox.timer = (time, func) ->
  setTimeout(func, time)

# determine if browser is touch device
Toolbox.isTouchDevice = ->
  "ontouchstart" of window or navigator.maxTouchPoints

Toolbox.setObjectDefaults = (object, defaults) ->
  $.extend({}, defaults, object)

# cookies
Toolbox.getCookie = (namespace) ->
  Cookies.getJSON(namespace)

Toolbox.setCookie = (namespace, value, options) ->
  options = Toolbox.setObjectDefaults(options, { expires: 365 })
  Cookies.set(namespace, value, options)
  value

Toolbox.deleteCookie = (namespace) ->
  value = Toolbox.getCookie(namespace)
  Cookies.remove(namespace)
  value
