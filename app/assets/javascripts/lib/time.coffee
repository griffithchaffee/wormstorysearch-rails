# http://momentjs.com/docs/#/displaying/
momentTimeFormats =
  today_full:  "[Today at] h:mm A"
  today_brief: "h:mm A"
  without_year_full:  "MMM D [at] h:mm A"
  without_year_brief: "MMM D"
  with_year_full:  "MMM D, Y [at] h:mm A"
  with_year_brief: "MMM D, Y"

momentDateFormats =
  today_full:  "[Today]"
  today_brief: "[Today]"
  without_year_full:  "MMM D"
  without_year_brief: "MMM D"
  with_year_full:  "MMM D, Y"
  with_year_brief: "MMM D, Y"

# Ex: { type: "time", unix: "1509306622", format: "calendar_full" }
parseMoments = ->
  $("[data-moment]").each (i, tag) ->
    $tag = $(tag)
    momentConfig = $tag.data("moment")
    # skip converted moments
    return if momentConfig.converted is "true"
    momentConfig.converted = "true"
    parsedMoment = moment.unix(momentConfig.unix)
    # helpers
    isToday    = -> parsedMoment.isSame(moment(), "day")
    isSameYear = -> parsedMoment.isSame(moment(), "year")
    isDate     = -> momentConfig.type is "date"
    setTagText = (format) ->
      if isDate()
        momentFormat = momentDateFormats[format] or format
      else
        momentFormat = momentTimeFormats[format] or format
      $tag.text(parsedMoment.format(momentFormat))
    # select format
    switch momentConfig.format
      when "calendar_full"
        if isToday()
          setTagText("today_full")
        else if isSameYear()
          setTagText("without_year_full")
        else
          setTagText("with_year_full")
      when "calendar_brief"
        if isToday()
          setTagText("today_brief")
        else if isSameYear()
          setTagText("without_year_brief")
        else
          setTagText("with_year_brief")
      else
        setTagText(momentConfig.format)

$(document).on("page:change", parseMoments)
$(document).on("page:partial:change", parseMoments)
