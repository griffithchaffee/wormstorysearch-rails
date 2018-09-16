$(document).on "click", "a[data-track]", (evt) ->
  $a = $(@)
  $.ajax({
    url: $a.data("track"),
    type: "GET",
  })
