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
    value = parseInt s[0]['time']
    if s[0]['songid'] == currentSong
      progress.stop true, false

      # sometimes, the current time value is less then (old value + 1).
      # in this case, for the first such incident, we increment value by
      # 1 and animate anyway. the second such incident in a row triggers
      # a pause, in which no animations will occur.

      if updateStatus.previous != value
        updateStatus.previous = value
        updateStatus.suspectingPause = false
      else if !updateStatus.suspectingPause
        value++
        updateStatus.suspectingPause = true;
      else
        return

      progress.css seek: 0
      progress.animate seek: 2,
        {duration: 2000, easing: "linear",
        step: (d)->progress.slider 'value', value+d }

    else
      mpd.currentsong (s) ->
        if s[0]
          progress.slider 'option', 'max', parseInt(s[0]['time'])
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
  mpd.seekid currentSong, Math.floor $('#progress').slider('option', 'value')

$ ->
  mpd 'commands', (commands) ->
    generate command.command for command in commands

    # slider. interval should be >1s because the slider looks much
    # smoother when corrections tend to be forward in time.
    $("#progress").slider(animate: 'fast', step: .01, stop: seek, slide: ->$('#progress').stop true, false)
    setInterval updateStatus, 1010

    mpd.playlistinfo (l) -> generateList $('#playlist'), l

    $('#playlist li').live 'click', ->
      song = $(this).data 'song'
      mpd.playid song['id']


