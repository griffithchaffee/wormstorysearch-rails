# popover
popoverBind = ->
  defaults = {}
  $("[data-toggle=popover]").popover(defaults)

$(document).on "page:change", popoverBind
$(document).on "page:partial:change", popoverBind

# tooltip
tooltipBind = ->
  defaults = {}
  $("[data-toggle=tooltip]").tooltip(defaults)

$(document).on "page:change", tooltipBind
$(document).on "page:partial:change", tooltipBind
