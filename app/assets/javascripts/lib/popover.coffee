# popover
popoverBind = ->
  defaults = {}
  $("[data-toggle=popover]").popover(defaults)
  $("[data-toggle=popover-desktop]").popover(defaults) if not Toolbox.isTouchDevice()

$(document).on("page:change", popoverBind)
$(document).on("page:partial:change", popoverBind)

# tooltip
tooltipBind = ->
  defaults = {}
  $("[data-toggle=tooltip]").tooltip(defaults)
  $("[data-toggle=tooltip-desktop]").tooltip(defaults) if not Toolbox.isTouchDevice()

$(document).on("page:change", tooltipBind)
$(document).on("page:partial:change", tooltipBind)
