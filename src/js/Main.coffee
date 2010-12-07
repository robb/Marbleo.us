# Set up game
$(document).ready ->
  @game = new Game {}, ->
    console.log "Finished loading" if DEBUG
