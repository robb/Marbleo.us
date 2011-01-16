# Set up game
$(document).ready ->
  @game = new Game {}, =>
    if window.location.hash.length > 1
      compressor = new Compressor
      compressor.decompress window.location.hash.slice(1), @game.map
      @game.updateCanvasMargin()

    $('.share').bind 'click', =>
      compressor = new Compressor
      string = compressor.compress @game.map
      window.location.replace('#' + string);

      $('#popup input').val window.location

      $('#popup').addClass 'visible'
      $('#popup #dismiss').bind 'click', =>
        $('#popup').removeClass 'visible'