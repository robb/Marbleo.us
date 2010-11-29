# Set up game
$(document).ready ->
  @map      = new Map(7)

  for x in [0...7]
    for y in [0...7]
      for z in [0...7]
        @map.setBlock new Block('curve-straight', 90), x, y, z

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
      @map.selectBlock @renderer.blockAtScreenCoordinates event.layerX, event.layerY

    renderingLoop = =>
      @renderer.drawMap()
    setInterval renderingLoop, 20