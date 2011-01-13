# Set up game
$(document).ready ->
  @game = new Game {}, =>
    if window.location.hash.length > 1
      compressor = new Compressor
      compressor.decompress window.location.hash.slice(1), @game.map
