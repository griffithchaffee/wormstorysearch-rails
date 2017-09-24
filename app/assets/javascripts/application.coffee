#= require jquery-v3.2.1
#= require js-cookie-v2.1.4
#= require bootstrap-v3.3.7
#= require_self
#= require toolbox
#= require identity
#= require_tree ./lib

# initialize
$ ->
  # trigger page change
  $(document).trigger("page:change")
  # trigger partial change when modal loaded
  $(document).on 'loaded.bs.modal', ->
    $(document).trigger("page:partial:change")
