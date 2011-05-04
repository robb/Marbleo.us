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

    $('.network.button').bind 'click', (event) ->
      event.preventDefault()
      url = $(this).attr 'href'

      window.open url,
                  'popup',
                  'location=1,width=600,height=290,toolbar=no,scrollbars=no'

    updateNetworks = (url) ->
      escaped = encodeURI(url).replace '#', '%23'

      $('.facebook').attr
        'href': "http://facebook.com/sharer.php?u=#{escaped}"

      $('.twitter').attr
        'href': "http://twitter.com/share?text=I've+built+a+marble+run+with+%23marbleous,+check+it+out&url=#{escaped}"

    # Setup share popup
    $('.button.share').bind 'click', =>
      $('.popup').removeClass 'visible'

      compressor = new Compressor
      string     = compressor.compress @game.map
      url        = 'http://marbleo.us/#' + string

      window.location.replace '#' + string

      $('#share input').val url
      updateNetworks url

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
          if result.status_code is 200
            $('#share input').val result.data.url

            updateNetworks result.data.url