setTimeZone = ->
  time = new Date()
  time_zone_offset = time.getTimezoneOffset()
  Identity.setCookieValue("time", "#{time}")
  Identity.setCookieValue("time_zone_offset", time_zone_offset)

$(document).on("page:change", setTimeZone)
