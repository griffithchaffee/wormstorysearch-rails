$(document).on "click", "a.dynamic-modal", (evt) ->
  $triggerElement = $(@)
  Toolbox.cancelEvent(evt)
  $modal = $("#dynamic-modal").modal("show")
  $modal.data("$triggerElement", $triggerElement)
  # replace modal content with response content
  $.ajax({
    url: @href,
    type: "GET",
    headers: { "x-view-layout": "modal" }
  }).done (response, status, evt) ->
    # trigger normal bootstrap remote loading event
    $response = $(response)
    $.each ["header", "body", "footer"], (i, section) ->
      $modal.find(".modal-#{section}").replaceWith($response.find(".modal-#{section}"))
    # reset focus
    $modal.focus()
    $(document).trigger("loaded.bs.modal")

# save original html for reset after close
$(document).on "show.bs.modal", "#dynamic-modal", (evt) ->
  $modal = $(@)
  original = {}
  $.each ["header", "body", "footer"], (i, section) ->
    original[section] = $modal.find(".modal-#{section}").clone(true, true)
  $modal.data("original.bs.modal", original)

# after hiding a modal clear its data and reset to original html
$(document).on "hidden.bs.modal", "#dynamic-modal", (evt) ->
  $modal = $(@)
  $modal.removeData("bs.modal")
  if $modal.data("original.bs.modal")
    $.each $modal.data("original.bs.modal"), (section, html) ->
      $modal.find(".modal-#{section}").replaceWith(html)

# universal modal callbacks
$(document).on "click", "[data-toggle=modal]", (evt) ->
  $triggerElement = $(@)
  $modal = $($triggerElement.data("target"))
  $modal.data("$triggerElement", $triggerElement)

# universal modal callbacks
$(document).on "hidden.bs.modal", (evt) ->
  $modal = $(@)
  # put focus back on original element
  $modal.data("$triggerElement")?.focus()
