argsToArray = (args) -> Array.prototype.slice.call(args)

window.mpd = ->
  array     = argsToArray arguments
  callback  = array.pop() if typeof array[array.length - 1] == 'function'
  callback ?= ->
  url       = '/' + array.join '/'
  $.get url, callback

generate = (m) ->
  mpd[m] = ->
    mpd m, argsToArray(arguments)...

mpd 'commands', (commands) ->
  generate command.command for command in commands
