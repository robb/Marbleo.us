class HitTestLayer extends Layer
  constructor: (@renderer, @map) ->
    super

    @floor  = @getTexture('basic','floor-hitbox')
    @hitbox = @getTexture('basic','hitbox')

  sideAtScreenCoordinates: (x, y) ->
    pixel = @context.getImageData x, y, 1, 1
    if pixel.data[0] > 0
      return 'south'
    if pixel.data[1] > 0
      return 'east'
    if pixel.data[2] > 0
      return 'top'
    if pixel.data[3] > 0
      return 'floor'

    null

  redraw: ->
    @clear()

    @map.coordinatesEach (x, y, z) =>
      if z is 0
        [screenX, screenY] = @renderer.floorCoordinates x, y
        @context.drawImage @floor,
                           screenX,
                           screenY,
                           Settings.textureSize,
                           Settings.textureSize

      if (block = @map.getBlock(x, y, z)) and not block.dragged
        [screenX, screenY] = @renderer.renderingCoordinatesForBlock block
        @context.drawImage @hitbox,
                           screenX,
                           screenY,
                           Settings.textureSize,
                           Settings.textureSize
