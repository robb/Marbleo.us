# Set up game
$(document).ready ->
  @game = new Game {}, =>
    if window.location.hash.length > 1
      try
        compressor = new Compressor
        compressor.decompress window.location.hash.slice(1), @game.map
        @game.updateCanvasMargin()
      catch e
        console.error "Coudl not parse map correctly: #{e}" if DEBUG

    $('.share').bind 'click', =>
      compressor = new Compressor
      string = compressor.compress @game.map
      window.location.replace('#' + string);

      $('#popup input').val window.location

      $('#popup').addClass 'visible'
      $('#popup #dismiss').bind 'click', =>
        $('#popup').removeClass 'visible'