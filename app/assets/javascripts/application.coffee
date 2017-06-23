#= require jquery-v3.2.1
#= require bootstrap-v3.3.7
#= require_self
#= require toolbox
#= require_tree ./lib

# init
App = {}
$ ->
  $(document).trigger("page:change")
  $(document).on 'loaded.bs.modal', ->
    $(document).trigger("page:partial:change")
