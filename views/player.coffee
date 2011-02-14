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

window.currentSong = -1

updateStatus = ->
  mpd.status (s) ->
    progress = $('#progress')
    if s[0]['songid'] == currentSong
      value = 1000 * parseInt s[0]['time']
      console.log value
      progress.stop true, false
      if updateStatus.previous != value || !updateStatus.suspectingPause
        updateStatus.previous = value
        if updateStatus.suspectingPause
          value++
        updateStatus.suspectingPause = false
        progress.css seek: 0
        progress.animate seek: 2000,
          {duration: 2000, easing: "linear",
          step: (d) -> progress.slider 'value', value+d }
      else
        updateStatus.suspectingPause = true
        progress.slider 'value', value

    else
      mpd.currentsong (s) ->
        if s[0]
          progress.slider 'option', 'max', 1000 * parseInt(s[0]['time'])
          oldValue = $('#pl_' + currentSong)
          oldValue.removeClass 'currentSong'
          oldValue.addClass 'ui-priority-secondary'
          window.currentSong = s[0]['id']
          newValue = $('#pl_' + s[0]['id'])
          newValue.addClass 'currentSong'
          newValue.removeClass 'ui-priority-secondary'
          updateStatus()

generateList = (list, songs) ->
  for song in songs
    element = $('<li id="pl_' + song['id'] + '" class="ui-state-default ui-priority-secondary">' + song['title'] + '</li>')
    element.data 'song', song
    list.append element
  list

seek = (event) ->
  $('#progress').stop true, false
  console.log event
  mpd.seekid currentSong, Math.floor $('#progress').slider('option', 'value') / 1000
  updateStatus()

$ ->
  mpd 'commands', (commands) ->
    generate command.command for command in commands
    $("#progress").slider(stop: seek)
    setInterval updateStatus, 1000
    mpd.playlistinfo (l) -> generateList $('#playlist'), l

    $('#playlist li').live 'click', ->
      song = $(this).data 'song'
      mpd.playid song['id']

    updateStatus()



