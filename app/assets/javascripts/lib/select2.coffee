select2Bind = ->
  $("select.select2").each (i, select2) ->
    $select2 = $(select2)
    unless $select2.data("select2")
      options = { theme: "bootstrap" }
      if $select2.parents(".modal")
        options.dropdownParent = $select2.parents(".modal")
      $select2.select2(options)

$(document).on("page:change", select2Bind)
$(document).on("page:partial:change", select2Bind)
