searchableTableBind = ->
  # build namespaced accessors
  $form        = $("form.searchable")
  $checkboxes = $form.find(".filters input[type=checkbox], input[type=checkbox].filter").not(".filter-ignore")
  $radios      = $form.find(".filters input[type=radio],    input[type=radio].filter").not(".filter-ignore")
  $inputs      = $form.find(".filters input, input.filter").not("[name=utf8],[type=checkbox],[type=radio]").not(".filter-ignore")
  $selects     = $form.find("select, select.filter").not(".filter-ignore")
  $resets      = $form.find(".search-reset")
  $page        = $form.find("#page")
  $searchHide = $form.find(".search-hide")
  $searchShow = $form.find(".search-show, .search-reset")
  # set default values used to hide/show filter resets
  $inputs.each (i, input) ->
    $(input).data("search", { default:  "#{if $(input).data("search-default")? then $(input).data("search-default") else ""}" })
  $selects.each (i, select) ->
    $(select).data("search", { default: "#{if $(select).data("search-default")? then $(select).data("search-default") else ""}" })
  $radios.each (i, radio) ->
    $(radio).data("search", { default:  "#{if $(radio).data("search-default")? then $(radio).data("search-default") else $(radio).val()}" })
  $checkboxes.each (i, checkbox) ->
    $(checkbox).data("search", { default: "#{$(checkbox).data("search-default")}" is "true" })
  # reset filters
  resetBind = (evt) ->
    $inputs.not(".filter-reset-ignore").each (i, input) -> $(input).val($(input).data("search").default)
    $selects.not(".filter-reset-ignore").each (i, select) -> $(select).val($(select).data("search").default)
    $checkboxes.not(".filter-reset-ignore").each (i, checkbox) -> $(checkbox).prop("checked", $(checkbox).data("search").default)
    $radios.not(".filter-reset-ignore").each (i, radio) -> $(radio).prop("checked", false)
    $form.submit()
  $resets.not("input, select").click resetBind
  $resets.filter("input, select").change resetBind
  # submit form on enter or change
  newSearchBind = (evt) ->
    $page.val($page.data("search").default)
    $form.submit()
  $inputs.change(newSearchBind)
  $checkboxes.change(newSearchBind)
  $radios.change(newSearchBind)
  $selects.change(newSearchBind)
  $inputs.keydown (evt) ->
    if evt.keyCode is 13
      Toolbox.cancelEvent(evt)
      newSearchBind()
  # show resets if non-default search
  searching = (value) ->
    if value
      $searchHide.hide()
      $searchShow.show()
    else
      $searchHide.show()
      $searchShow.hide()
  searching(false)
  $inputs.not(".filter-reset-ignore").each (i, input) ->
    if $(input).val() isnt $(input).data("search").default then searching(true)
  $selects.not(".filter-reset-ignore").each (i, select) ->
    if $(select).val() isnt $(select).data("search").default then searching(true)
  $radios.not(".filter-reset-ignore").each (i, radio) ->
    if $(radio).prop("checked") then searching(true)
  $checkboxes.not(".filter-reset-ignore").each (i, checkbox) ->
    $checkbox = $(checkbox)
    if $checkbox.prop("checked")
      if $checkbox.val() isnt $checkbox.data("search").default then searching(true)
    else
      if $checkbox.val() is $checkbox.data("search").default then searching(true)

$(document).on "page:change", searchableTableBind
