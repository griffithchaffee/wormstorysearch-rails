searchableTableBind = ->
  # build namespaced accessors
  $form        = $("form.searchable")
  $inputs      = $form.find(".filters input, input.filter").not("[type=checkbox],[type=radio]").not(".filter-ignore")
  $selects     = $form.find("select, select.filter").not(".filter-ignore")
  $checkboxes  = $form.find(".filters input[type=checkbox], input[type=checkbox].filter").not(".filter-ignore")
  $radios      = $form.find(".filters input[type=radio], input[type=radio].filter").not(".filter-ignore")
  $resets      = $form.find(".search-reset")
  $blankify    = $form.find(".filter-blankify")
  $page        = $inputs.filter("[name=page]")
  $whenSearchingHide = $form.find(".search-hide")
  $whenSearchingShow = $form.find(".search-show, .search-reset")
  # build namespace
  $blankify.add($inputs).add($selects).add($checkboxes).add($radios).each (i, filter) -> $(filter).data("search", {})
  # set default values used to hide/show filter resets
  $inputs.add($selects).each (i, filter) ->
    $(filter).data("search").default = "#{if $(filter).data("search-default")? then $(filter).data("search-default") else ""}"
  $checkboxes.each (i, checkbox) ->
    $(checkbox).data("search").default = "#{$(checkbox).data("search-default")}" is "true"
  $radios.each (i, radio) ->
    $(radio).data("search").default = "#{if $(radio).data("search-default")? then $(radio).data("search-default") else $(radio).val()}"
  # submit form on enter or change
  newSearchBind = (evt) ->
    # reset to default page (usually first)
    if $page.length is 1
      $page.val($page.data("search").default)
    # prevent url pollution by denaming blank filters
    $blankify.add($inputs).add($selects).each (i, filter) ->
      $filter = $(filter)
      if $filter.val() is "" and ($filter.data("search").default is "" or $filter.hasClass("filter-blankify"))
        $filter.data("search").name = $filter.prop("name")
        $filter.prop("name", "")
    $form.submit()
    # re-add name to blank filters
    $blankify.add($inputs).add($selects).each (i, filter) ->
      $filter = $(filter)
      if $filter.data("search").name
        $filter.prop("name", $filter.data("search").name)
        delete($filter.data("search").name)
  $inputs.add($selects).add($checkboxes).add($radios).change(newSearchBind)
  # enter key
  $inputs.keydown (evt) ->
    if evt.keyCode is 13
      Toolbox.cancelEvent(evt)
      newSearchBind()
  # reset filters
  $resets.click (evt) ->
    $inputs.add($selects).not(".filter-reset-ignore").each (i, filter) ->
      $(filter).val($(filter).data("search").default)
    $checkboxes.not(".filter-reset-ignore").each (i, checkbox) -> $(checkbox).prop("checked", $(checkbox).data("search").default)
    $radios.not(".filter-reset-ignore").each (i, radio) -> $(radio).prop("checked", false)
    newSearchBind()
  # toggle proper search status elements
  setSearchingStatus = (value) ->
    if value
      $whenSearchingHide.hide()
      $whenSearchingShow.show()
    else
      $whenSearchingHide.show()
      $whenSearchingShow.hide()
  # default to not searching
  setSearchingStatus(false)
  # determine if we are searching by comparing values with defaults
  $inputs.add($selects).not(".filter-reset-ignore").each (i, filter) ->
    if $(filter).val() isnt $(filter).data("search").default then setSearchingStatus(true)
  $checkboxes.not(".filter-reset-ignore").each (i, checkbox) ->
    $checkbox = $(checkbox)
    if $checkbox.prop("checked")
      if $checkbox.val() isnt $checkbox.data("search").default then setSearchingStatus(true)
    else
      if $checkbox.val() is $checkbox.data("search").default then setSearchingStatus(true)
  $radios.not(".filter-reset-ignore").each (i, radio) ->
    if $(radio).prop("checked") then setSearchingStatus(true)
  # build helpful tooltip for text fields if first search
  #if window.location.search is ""
    #$inputs.tooltip({ placement: "top left", title: "Press enter to apply", trigger: "focus", container: "body" })
    # remove help tooltip after displaying
    #$inputs.blur -> $inputs.tooltip("destroy")

$(document).on "page:change", searchableTableBind
