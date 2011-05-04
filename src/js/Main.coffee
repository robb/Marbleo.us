$(document).ready ->
  @game = new Game =>
    # If there is a something in the fragment, decode and put it into the
    # game map
    if window.location.hash.length > 1
      try
        compressor = new Compressor
        compressor.decompress window.location.hash.slice(1), @game.map
        @game.updateCanvasMargin()
      catch e
        console.error "Coudl not parse map correctly: #{e}" if DEBUG

    @game.updateButton()

    $('#share input').focus -> @select()

    # Setup share popup
    $('.button.share').bind 'click', =>
      $('.popup').removeClass 'visible'

      compressor = new Compressor
      string     = compressor.compress @game.map
      url        = 'http://marbleo.us/#' + string

      window.location.replace '#' + string

      $('#share input').val url

      $('#share').addClass 'visible'

      $('#share .dismiss').bind 'click', ->
        $('#share').removeClass 'visible'

      # Shorten URL using bit.ly
      $.ajax
        url:     'http://api.bitly.com/v3/shorten'
        data:
          format:  'json'
          login:   'robertboehnke'
          apiKey:  BITLY_API_KEY
          longUrl: url
        success: (result, status) ->
          $('#share input').val result.data.url if result.status_code is 200