$(document).on "click", "a.dynamic-modal", (evt) ->
  $a = $(@)
  Toolbox.cancelEvent(evt)
  $modal = $("#dynamic-modal").modal("show")
  # replace modal content with response content
  $.ajax({ url: @href, type: "GET" }).done (response, status, evt) ->
    $response = $(response)
    $.each ["header", "body", "footer"], (i, section) ->
      $modal.find(".modal-#{section}").replaceWith($response.find(".modal-#{section}"))

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
