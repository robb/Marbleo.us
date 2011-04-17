# This class takes care of rendering blocks, stacks and maps.
class Renderer
  constructor: (@animator, @map, @marble, onload) ->
    @mainCanvas = $(Settings.mainCanvasID)
    @mainCanvas.attr  'width', Settings.canvasWidth
    @mainCanvas.attr 'height', Settings.canvasHeight
    @mainContext = @mainCanvas.get(0).getContext '2d'

    @canvas = document.createElement 'canvas'
    @canvas.width  = Settings.canvasWidth
    @canvas.height = Settings.canvasHeight
    @context = @canvas.getContext '2d'

    @marbleCanvas = document.createElement 'canvas'
    @marbleCanvas.width  = Settings.canvasWidth
    @marbleCanvas.height = Settings.canvasHeight
    @marbleContext = @marbleCanvas.getContext '2d'

    @draggedCanvas  = $(Settings.draggedCanvasID)
    @draggedContext = @draggedCanvas.get(0).getContext '2d'

    @textureStore = new TextureStore =>
      @hitTestLayer    = new HitTestLayer    @, @map
      @mapLayer        = new MapLayer        @, @map
      @visibilityLayer = new VisibilityLayer @, @map, @marble

      @map.addListener 'didChange', @updateMap
      @map.addListener 'didRotate', @updateEverything

      @animator.addListener 'marble:moved', @updateMarble

      @updateEverything()
      onload()

  getTextureStore: ->
    @textureStore

  clear: (context) ->
    context.clearRect 0, 0, Settings.canvasWidth, Settings.canvasHeight

  updateMap: =>
    console.log "Redrawing map" if DEBUG

    @hitTestLayer.redraw()
    @mapLayer.redraw()
    @visibilityLayer.redraw()

    # TODO: Redraw Marble and visibility layer

    @joinLayers()
    @updateMainCanvas()

  updateMarble: =>
    @clear @marbleContext

    @visibilityLayer.redraw()

    drawMarble = (context, marble) =>
      [x, y] = @renderingCoordinatesForMarble marble

      context.beginPath()
      context.arc x, y, marble.radius, 0, Math.PI * 2, yes
      context.closePath()
      context.fill()

    @marbleContext.globalCompositeOperation = 'source-over'
    drawMarble @marbleContext, @marble

    @marbleContext.globalCompositeOperation = 'destination-out'

    @marbleContext.globalAlpha = 0.4
    @marbleContext.drawImage @visibilityLayer.getCanvas(),
                             0,
                             0,
                             Settings.canvasWidth,
                             Settings.canvasHeight
    @marbleContext.globalAlpha = 1

    @updateMainCanvas()

  updateEverything: =>
    @updateMap()
    @updateMarble()

  joinLayers: ->
    join = (layer, alpha = 1.0) =>
      @context.globalCompositeOperation = 'source-over'
      @context.globalAlpha = alpha
      @context.drawImage layer.getCanvas(),
                         0,
                         0,
                         Settings.canvasWidth,
                         Settings.canvasHeight

    @clear @context

    join @mapLayer
    join @hitTestLayer,     0.4 if OVERLAY

  updateMainCanvas: ->
    @clear @mainContext

    @mainContext.drawImage @canvas, 0, 0, Settings.canvasWidth, Settings.canvasHeight
    @mainContext.drawImage @marbleCanvas, 0, 0, Settings.canvasWidth, Settings.canvasHeight

  drawBlock: (context, block, x = 0, y = 0) ->
    @mapLayer.drawBlock context, block, x, y

  # Draws the stack of currently dragged blocks into the dragged canvas.
  drawDraggedBlocks: (stack) ->
    width  = Settings.textureSize
    height = if stack.length is 1
               Settings.textureSize
             else
               Settings.textureSize + Settings.textureSizeHalf * (stack.length - 1)

    @draggedCanvas.attr  'width', width
    @draggedCanvas.attr 'height', height

    for block, index in stack
      @drawBlock @draggedContext, block, 0, height - Settings.textureSize - (index) * Settings.textureSizeHalf

  # Returns information about the map contents at the given screen
  # coordinates.
  # Please note that x and y must be relative to the point of origin of the
  # canvas
  resolveScreenCoordinates: (x, y) ->
    unless 0 < x < Settings.canvasWidth and 0 < y < Settings.canvasHeight
      return {}

    side = @sideAtScreenCoordinates(x, y)
    if side is 'floor'
      for blockX in [0...@map.size]
        for blockY in [@map.size - 1..0]
          [screenX, screenY] = @floorCoordinates blockX, blockY

          continue unless screenX <= x < (screenX + Settings.textureSize) and
                          screenY <= y < (screenY + Settings.textureSize)

          pixel = @textureStore.getTexture('basic','floor-hitbox')
                               .getContext('2d')
                               .getImageData x - screenX, y - screenY, 1, 1

          if pixel.data[3] > 0
            return {
              coordinates: [blockX, blockY, 0]
              side: 'floor'
            }

    else if side
      for blockX in [0...@map.size]
        for blockY in [@map.size - 1..0]
          for blockZ in [@map.size - 1..0]
            currentBlock = @map.getBlock blockX, blockY, blockZ
            continue if not currentBlock or currentBlock.dragged

            [screenX, screenY] = @renderingCoordinatesForBlock currentBlock

            continue unless screenX <= x < (screenX + Settings.textureSize) and
                            screenY <= y < (screenY + Settings.textureSize)

            pixel = @textureStore.getTexture('basic','hitbox')
                                 .getContext('2d')
                                 .getImageData x - screenX, y - screenY, 1, 1

            if pixel.data[3] > 0
              return {
                block:       currentBlock
                coordinates: [blockX, blockY, blockZ]
                side:        side
              }
    else
      return {}

  sideAtScreenCoordinates: (x, y) ->
    @hitTestLayer.sideAtScreenCoordinates x, y

  renderingCoordinatesForMarble: (marble) ->
    [x, y, z] = marble.getCoordinates()

    screenX = (x + y)
    screenY = Settings.canvasHeight - 7 * Settings.textureSizeQuarter \
              - (2 * z + x - y) / 2

    [screenX, screenY]

  renderingCoordinatesForBlock: (block) ->
    [x, y, z] = block.getCoordinates()

    screenX = (x + y) * Settings.textureSizeHalf
    screenY = Settings.canvasHeight \
              - 3 * Settings.textureSizeQuarter \
              - (2 * z + x - y + @map.size) * Settings.textureSizeQuarter

    [screenX, screenY]

  floorCoordinates: (x, y) =>
    screenX = (x + y) * Settings.textureSizeHalf
    screenY = Settings.canvasHeight -
              3 * Settings.textureSizeQuarter -
              (x - y + @map.size) * Settings.textureSizeQuarter

    [screenX, screenY]
