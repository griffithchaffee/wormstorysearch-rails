Identity = {}
@Identity = Identity

Identity.config =
  cookie: "browser.identity"

Identity.getCookie = ->
  cookie = Cookies.getJSON(Identity.config.cookie)
  if $.isPlainObject(cookie)
    cookie
  else
    Identity.resetCookie()

Identity.setCookie = (newCookie) ->
  if $.isPlainObject(newCookie)
    Cookies.set(Identity.config.cookie, newCookie, { expires: 365 })
    newCookie
  else
    Identity.getCookie()

Identity.getCookieValue = (key, defaultValue) ->
  currentValue = Identity.getCookie()[key]
  if !currentValue and defaultValue
    Identity.setCookieValue(key, defaultValue)
    defaultValue
  else
    currentValue

Identity.setCookieValue = (key, newValue) ->
  cookie = Identity.getCookie()
  cookie[key] = newValue
  Identity.setCookie(cookie)

Identity.resetCookie = ->
  Identity.setCookie({})
