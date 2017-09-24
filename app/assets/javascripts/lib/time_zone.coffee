setTimeZone = ->
  Identity.setCookieValue("time_zone_offset", Toolbox.getTimeZoneOffset())

$(document).on("page:change", setTimeZone)
