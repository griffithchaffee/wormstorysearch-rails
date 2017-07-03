searchableTableBind = ->
  # build namespaced accessors
  $form        = $("form.searchable")
  $check_boxes = $form.find(".filters input[type=checkbox], input[type=checkbox].filter").not(".filter-ignore")
  $radios      = $form.find(".filters input[type=radio],    input[type=radio].filter").not(".filter-ignore")
  $inputs      = $form.find(".filters input, input.filter").not("[name=utf8],[type=checkbox],[type=radio]").not(".filter-ignore")
  $selects     = $form.find("select, select.filter").not(".filter-ignore")
  $resets      = $form.find(".search-reset")
  $search_hide = $form.find(".search-hide")
  $search_show = $form.find(".search-show, .search-reset")
  # set default values used to hide/show filter resets
  $inputs.each (i, input) ->
    $(input).data("search", { default:  "#{if $(input).data("search-default")? then $(input).data("search-default") else ""}" })
  $selects.each (i, select) ->
    $(select).data("search", { default: "#{if $(select).data("search-default")? then $(select).data("search-default") else ""}" })
  $radios.each (i, radio) ->
    $(radio).data("search", { default:  "#{if $(radio).data("search-default")? then $(radio).data("search-default") else $(radio).val()}" })
  $check_boxes.each (i, check_box) ->
    $(check_box).data("search", { default: "#{$(check_box).data("search-default")}" is "true" })
  # reset filters
  resetBind = (evt) ->
    $inputs.not(".filter-reset-ignore").each (i, input) -> $(input).val($(input).data("search").default)
    $selects.not(".filter-reset-ignore").each (i, select) -> $(select).val($(select).data("search").default)
    $check_boxes.not(".filter-reset-ignore").each (i, check_box) -> $(check_box).prop("checked", $(check_box).data("search").default)
    $radios.not(".filter-reset-ignore").each (i, radio) -> $(radio).prop("checked", false)
    $form.submit()
  $resets.not("input, select").click resetBind
  $resets.filter("input, select").change resetBind
  # submit form on enter or change
  $inputs.change      (evt) -> $form.submit()
  $check_boxes.change (evt) -> $form.submit()
  $radios.change      (evt) -> $form.submit()
  $selects.change     (evt) -> $form.submit()
  $inputs.keydown     (evt) ->
    if evt.keyCode is 13
      Toolbox.cancelEvent(evt)
      $form.submit()
  # show resets if non-default search
  searching = (value) ->
    if value
      $search_hide.hide()
      $search_show.show()
    else
      $search_hide.show()
      $search_show.hide()
  searching(false)
  $inputs.not(".filter-reset-ignore").each (i, input) ->
    if $(input).val() isnt $(input).data("search").default then searching(true)
  $selects.not(".filter-reset-ignore").each (i, select) ->
    if $(select).val() isnt $(select).data("search").default then searching(true)
  $radios.not(".filter-reset-ignore").each (i, radio) ->
    if $(radio).prop("checked") then searching(true)
  $check_boxes.not(".filter-reset-ignore").each (i, check_box) ->
    $check_box = $(check_box)
    if $check_box.prop("checked")
      if $check_box.val() isnt $check_box.data("search").default then searching(true)
    else
      if $check_box.val() is $check_box.data("search").default then searching(true)

$(document).on "page:change", searchableTableBind
