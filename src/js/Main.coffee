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

    # TODO: Fails to reset the cursor if mousemove doesn go over
    #       the canvas, move this to the body
    $('#main-canvas').bind 'mousemove', (event) =>
      x = event.offsetX || event.layerX - $(event.target).position().left
      y = event.offsetY || event.layerY - $(event.target).position().top
      if side = @renderer.sideAtScreenCoordinates x, y
        cursor = if $.browser.webkit then '-webkit-grab' else \
                 if $.browser.mozilla then '-moz-grab'
      else
        cursor = 'auto'
      $('body').css 'cursor', cursor

      console.log side

    $('#main-canvas').bind 'click', (event) =>
      x = event.offsetX || event.layerX - $(event.target).position().left
      y = event.offsetY || event.layerY - $(event.target).position().top

      if info = @renderer.resolveScreenCoordinates x, y
        console.log info

    renderingLoop = =>
      @renderer.drawMap()
    setInterval renderingLoop, 20
