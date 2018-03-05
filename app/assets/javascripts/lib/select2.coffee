select2Bind = ->
  $("select.select2").each (i, select2) ->
    $select2 = $(select2)
    unless $select2.data("select2")
      $select2.select2(theme: "bootstrap")

$(document).on("page:change", select2Bind)
$(document).on("page:partial:change", select2Bind)
