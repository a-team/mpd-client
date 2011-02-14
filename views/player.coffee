argsToArray = (args) -> Array.prototype.slice.call(args)

source = ->
  $("script[src='player.js']")[0].src

require = (libName) ->
  jsName = source().replace("player.js", "player/" + libName + ".js")
  try
    # inserting via DOM fails in Safari 2.0, so brute force approach
    document.write '<script type="text/javascript" src="' + jsName + '"><\/script>'
  catch e
    # for xhtml+xml served content, fall back to DOM methods
    script = document.createElement('script')
    script.type = 'text/javascript'
    script.src = jsName
    document.getElementsByTagName('head')[0].appendChild(script)

require "volume"

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

updateStatus = ->
  mpd.status (s) ->
    if s[0]['songid'] == currentSong
      $('#progress').slider 'option', 'value', parseInt s[0]['time']
    else
      mpd.currentsong (s) ->
        if s[0]
          $('#progress').slider 'option', 'max', parseInt(s[0]['time'])
          window.currentSong = s[0]['id']
          updateStatus()

seek = (event) ->
  mpd.seekid currentSong, $('#progress').slider('option', 'value')

$ ->
  $("#progress").slider(stop: seek)
  setInterval updateStatus, 1000
