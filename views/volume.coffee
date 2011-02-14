update = (event) ->
  mpd.setvol $('#volume').slider('option', 'value')

$ ->
  $("#volume").slider(stop: update)