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

window.currentSong = -1

updateProgress = ->
  mpd.status (s) ->
    if s[0]['songid'] == currentSong
      $('#progress').slider 'option', 'value', parseInt s[0]['time']
    else
      mpd.currentsong (s) ->
        if s[0]
          $('#progress').slider 'option', 'max', parseInt(s[0]['time'])
          window.currentSong = s[0]['id']
          updateProgress()

seek = (event) ->
  mpd.seekid currentSong, $('#progress').slider('option', 'value')

$ ->
  $("#progress").slider(stop: seek)
  setInterval updateProgress, 1000
  updateProgress()
