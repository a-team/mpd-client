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

generateList = (songs) ->
  list = $('<ul></ul>')
  for song in songs
    list.append $('<li>' + song['title'] + '</li>')
  list

seek = (event) ->
  mpd.seekid currentSong, $('#progress').slider('option', 'value')

$ ->
  mpd 'commands', (commands) ->
    generate command.command for command in commands
    $("#progress").slider(stop: seek)
    setInterval updateProgress, 1000
    mpd.playlistinfo (l) -> $('#playlist').html generateList(l).html()
    updateProgress()
