# Set up game
$(document).ready ->
  @map      = new Map(7)

  @map.grid[0][0][0] = new Block 'curve-straight',     90
  @map.grid[1][0][0] = new Block 'double-straight',    90
  @map.grid[2][0][0] = new Block 'curve-straight-alt', 90

  @renderer = new Renderer @map, '#main-canvas', =>
    console.time "rendering" if DEBUG
    @renderer.drawMap()
    console.timeEnd "rendering" if DEBUG

    $('#main-canvas').bind 'mousemove', (event) =>
      blockAtMouse = @renderer.blockAtScreenCoordinates event.layerX, event.layerY
      if blockAtMouse
        if $.browser.webkit
          cursor = "-webkit-grab"
        else if $.browser.mozilla
          cursor = "-moz-grab"
        $('body').css "cursor", cursor
      else
        $('body').css "cursor", "auto"

    $('#main-canvas').bind 'click', (event) =>
      console.time "hit-test" if DEBUG
      blockAtMouse = @renderer.blockAtScreenCoordinates event.layerX, event.layerY
      console.log "Clicked block of type #{blockAtMouse.type}" if blockAtMouse
      console.timeEnd "hit-test" if DEBUG

      return this
