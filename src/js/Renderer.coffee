##
# This class takes care of rendering blocks, stacks and maps.
#
class Renderer
  @defaultSettings:
    mainCanvasID:     '#main-canvas'
    draggedCanvasID:  '#dragged-canvas'
    blockSize:        101
    blockSizeHalf:    Math.floor(101 / 2)
    blockSizeQuarter: Math.floor(Math.floor(101 / 2) / 2)
    canvasHeight:     7 * 101
    canvasWidth:      7 * 101
    textureFile:      '/img/textures.png'
    textureBlockSize: 101

  constructor: (@map, @onload, @settings = {}) ->
    for key, value of Renderer.defaultSettings
      @settings[key] = @settings[key] || Renderer.defaultSettings[key]

    @canvas = $(@settings.mainCanvasID)
    @canvas.attr  'width', @settings.canvasWidth
    @canvas.attr 'height', @settings.canvasHeight
    @context = @canvas.get(0).getContext '2d'

    @hittestCanvas = document.createElement 'canvas'
    @hittestCanvas.width  = @settings.canvasWidth
    @hittestCanvas.height = @settings.canvasHeight
    @hittestContext = @hittestCanvas.getContext '2d'

    @draggedCanvas = $(@settings.draggedCanvasID)
    @draggedContext = @draggedCanvas.get(0).getContext '2d'

    # Load all textures from the texture file
    @textures = {}

    @Cache = {}

    onloadCallback = =>
      @setupTextures(textureFile)
      return @onload()

    textureFile = new Image
    textureFile.onload = onloadCallback
    textureFile.src = @settings.textureFile

  ##
  # Loads the textures from the texture file.
  #
  # The Renderer.TextureFileDescription hash describes the layout of the
  # texture file. The texture file is split into a number of smaller canvases
  # that can be accessed from the @textures object.
  #
  setupTextures: (textureFile) ->
    textureOffset = 0
    for textureGroup, textureDescription of Renderer.TextureFileDescription
      for texture, rotationsCount of textureDescription
        console.log "loading #{textureGroup}.#{texture}" if DEBUG

        @textures[textureGroup] ?= {}
        @textures[textureGroup][texture] = new Array rotationsCount
        # Iterate over the avaible rotations
        for rotation in [0...rotationsCount]
          canvas = document.createElement 'canvas'
          canvas.width  = @settings.blockSize
          canvas.height = @settings.blockSize
          context = canvas.getContext '2d'
          try
            textureBSize = @settings.textureBlockSize
            context.drawImage textureFile,
                              rotation * textureBSize, textureOffset * textureBSize,        textureBSize,        textureBSize
                                                    0,                            0, @settings.blockSize, @settings.blockSize
          catch error
            if DEBUG
              console.log "Encountered error #{error} while loading texture: #{texture}"
              console.log "Texture file may be too small" if error.name is "INDEX_SIZE_ERR"
            break

          @textures[textureGroup][texture][rotation] = canvas
        textureOffset++

  ##
  # Calculates the point of origin of the square that the textures get
  # rendered in.
  # Please note that this position lies not in the block in terms of
  # hit-testing
  #
  # Relative to the point of origin of the canvas
  #
  renderingCoordinatesForBlock: (x, y, z) ->
    screenX = (x + y) * @settings.blockSizeHalf
    screenY = @settings.canvasHeight \
              - 3 * @settings.blockSizeQuarter \
              - (2 * z + x - y + @map.size) * @settings.blockSizeQuarter

    [screenX, screenY]

  ##
  # Returns either 'top', 'south', 'east', 'floor' or null depending on what
  # side  of a block (if any) is displayed at the given coordinates
  #
  sideAtScreenCoordinates: (x, y) ->
    pixel = @hittestContext.getImageData x, y, 1, 1
    if pixel.data[0] > 0
      return 'south'
    else if pixel.data[1] > 0
      return 'east'
    else if pixel.data[2] > 0
      return 'top'
    else if pixel.data[3] > 0
      return 'floor'
    else
      return null

  ##
  # Returns information about the map contents at the given screen
  # coordinates.
  # Please note that x and y must be relative to the point of origin of the
  # canvas
  #
  resolveScreenCoordinates: (x, y) ->
    unless 0 < x < @settings.canvasWidth and 0 < y < @settings.canvasHeight
      return {}

    side = @sideAtScreenCoordinates(x, y)
    if side is 'floor'
      for blockX in [0...@map.size]
        for blockY in [@map.size - 1..0]
          [screenX, screenY] = @renderingCoordinatesForBlock blockX, blockY, 0

          continue unless screenX <= x < (screenX + @settings.blockSize) and
                          screenY <= y < (screenY + @settings.blockSize)

          pixel = @getTexture('basic','floor-hitbox')
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
            [screenX, screenY] = @renderingCoordinatesForBlock blockX, blockY, blockZ

            continue unless screenX <= x < (screenX + @settings.blockSize) and screenY <= y < (screenY + @settings.blockSize)

            pixel = @getTexture('basic','hitbox').getContext('2d').getImageData x - screenX, y - screenY, 1, 1
            if pixel.data[3] > 0
              return {
                block: currentBlock
                coordinates: [blockX, blockY, blockZ]
                side: side
              }
    else
      return {}

  ##
  # Returns a texture from the texture cache.
  #
  getTexture: (group, type, rotation) ->
    unless rotation
      return @textures[group][type][0] if Renderer.TextureFileDescription[group][type]?

    rotationCount = Renderer.TextureFileDescription[group][type]
    return null unless rotationCount?
    return @textures[group][type][rotation / 90 % rotationCount]

  ##
  # Updates both the onscreen map and the internal hitmap. If force is set to
  # yes, the map will be drawn even if no drawing is required based on
  # needsRedraw
  #
  drawMap: (force = no) ->
    return if (@isDrawing or not @map.needsRedraw) and not force
    console.time "draw" if DEBUG
    @isDrawing = yes

    @context.clearRect        0, 0, @settings.canvasWidth, @settings.canvasHeight
    @hittestContext.clearRect 0, 0, @settings.canvasWidth, @settings.canvasHeight

    @drawFloor()

    @map.blocksEach (block, x, y, z) =>
      return unless block

      [screenX, screenY] = @renderingCoordinatesForBlock x, y, z
      @drawBlock @context, block, screenX, screenY

    @drawHitmap()

    # Render the hitmap into the main canvas for debugging purposes
    if OVERLAY
      @context.globalAlpha = 0.4
      @context.drawImage @hittestCanvas, 0, 0, @settings.canvasWidth, @settings.canvasHeight
      @context.globalAlpha = 1.0

    @map.setNeedsRedraw no
    @isDrawing = no
    console.timeEnd "draw" if DEBUG

  ##
  # Updates the internal hitmap.
  #
  # It is used for speedy lookup of visible blocks as well as the position of
  # block sides.
  #
  drawHitmap: ->
    @map.blocksEach (block, x, y, z) =>
      if z is 0
        [screenX, screenY] = @renderingCoordinatesForBlock x, y, 0
        @hittestContext.drawImage @getTexture('basic','floor-hitbox'), screenX, screenY, @settings.blockSize, @settings.blockSize
      if block and not block.dragged
        [screenX, screenY] = @renderingCoordinatesForBlock x, y, z
        @hittestContext.drawImage @getTexture('basic','hitbox'), screenX, screenY, @settings.blockSize, @settings.blockSize

  ##
  # Draws the floor
  #
  drawFloor: ->
    for x in [0...@map.size]
      for y in [0...@map.size]
        [screenX, screenY] = @renderingCoordinatesForBlock x, y, 0
        @context.drawImage @getTexture('basic','floor'), screenX, screenY, @settings.blockSize, @settings.blockSize

  ##
  # Draws a block into the given graphics context.
  #
  # The drawing operation is cached based on the Block.toString() method.
  #
  drawBlock: (context, block, x = 0, y = 0) ->
    cache_key = block.toString()

    unless cached = @Cache[cache_key]
      [topType, topRotation] = block.getProperty 'top'
      [midType, midRotation] = block.getProperty 'middle'
      [lowType, lowRotation] = block.getProperty 'low'

      @Cache[cache_key] = cached = document.createElement 'canvas'
      cached.height = cached.width = @settings.blockSize
      buffer = cached.getContext "2d"

      # Render the inner contents of the block only if the block is not fully
      # opaque.
      if block.selected or block.opacity isnt 1.0
        backside = @getTexture 'basic', 'backside'
        buffer.drawImage backside, 0, 0, @settings.blockSize, @settings.blockSize

        # Render the low layer
        if lowType
          low_texture = @getTexture 'low', lowType, lowRotation
          if low_texture?
            buffer.drawImage low_texture, 0, 0, @settings.blockSize, @settings.blockSize

        # Render the middle layer
        if midType
          mid_texture = @getTexture 'middle', midType, midRotation
          if mid_texture?
            buffer.drawImage mid_texture, 0, 0, @settings.blockSize, @settings.blockSize

      if block.selected
        buffer.globalAlpha = 0.3
      else
        buffer.globalAlpha = block.opacity || 1.0

      solid = @getTexture 'basic', 'solid'
      buffer.drawImage solid, 0, 0, @settings.blockSize, @settings.blockSize

      buffer.globalAlpha = 1.0

      # Render the top layer
      if topType
        top_texture = @getTexture 'top', topType, topRotation
        if top_texture?
          buffer.globalAlpha = 0.6 if block.selected
          buffer.drawImage top_texture, 0, 0, @settings.blockSize, @settings.blockSize
          buffer.globalAlpha = 1.0

      # Render the middle holes on the side of block
      midHoles = Renderer.MidHoles[midType]
      if midHoles
        for pos in midHoles
          if (pos + midRotation) % 360 == 0
            midHoleSouth = @getTexture 'basic', 'hole-middle', 0
            buffer.drawImage midHoleSouth, 0, 0, @settings.blockSize, @settings.blockSize

          if (pos + midRotation) % 360 == 90
            midHoleEast = @getTexture 'basic', 'hole-middle', 90
            buffer.drawImage midHoleEast, 0, 0, @settings.blockSize, @settings.blockSize

      # Render the lows holes on the side of block
      lowHoles = Renderer.LowHoles[midType]
      if lowHoles
        for pos in lowHoles
          if (pos + midRotation) % 360 == 0
            lowHoleSouth = @getTexture 'basic', 'hole-low', 0
            buffer.drawImage lowHoleSouth, 0, 0, @settings.blockSize, @settings.blockSize

          if (pos + midRotation) % 360 == 90
            lowHoleEast = @getTexture 'basic', 'hole-low', 90
            buffer.drawImage lowHoleEast, 0, 0, @settings.blockSize, @settings.blockSize

      # Render the bottom holes that are formed if this block stands on top
      # of another.
      bottomHoles = Renderer.BottomHoles[lowType]
      if bottomHoles
        for pos in bottomHoles
          if (pos + lowRotation) % 360 == 0
            bottomHoleSouth = @getTexture 'basic', 'hole-bottom', 0
            buffer.drawImage bottomHoleSouth, 0, 0, @settings.blockSize, @settings.blockSize

          if (pos + lowRotation) % 360 == 90
            bottomHoleEast = @getTexture 'basic', 'hole-bottom', 90
            buffer.drawImage bottomHoleEast, 0, 0, @settings.blockSize, @settings.blockSize

      # Draw the outline
      @drawOutline buffer, 0, 0

      # Remove transparent parts at the edges of the block.
      type = if topType is 'crossing-hole' then 'crossing' else topType
      cutouts = @getTexture 'cutouts-top', type, topRotation
      if cutouts
        buffer.globalCompositeOperation = 'destination-out'
        buffer.drawImage cutouts, 0, 0, @settings.blockSize, @settings.blockSize
        buffer.globalCompositeOperation = 'source-over'

      cutouts = @getTexture 'cutouts-bottom', lowType, lowRotation
      if cutouts
        buffer.globalCompositeOperation = 'destination-out'
        buffer.drawImage cutouts, 0, 0, @settings.blockSize, @settings.blockSize
        buffer.globalCompositeOperation = 'source-over'

    context.drawImage cached, x, y, @settings.blockSize, @settings.blockSize

  ##
  # Draws a block outline in the given graphics context.
  drawOutline: (context, x, y) ->
    context.drawImage @getTexture('basic','outline'), x, y, @settings.blockSize, @settings.blockSize

  ##
  # Draws the stack of currently dragged blocks into the dragged canvas.
  drawDraggedBlocks: (stack) ->
    width  = @settings.blockSize
    height = if stack.length is 1
               @settings.blockSize
             else
               @settings.blockSize + @settings.blockSizeHalf * (stack.length - 1)

    @draggedCanvas.attr  'width', width
    @draggedCanvas.attr 'height', height

    for block, index in stack
      @drawBlock @draggedContext, block, 0, height - @settings.blockSize - (index) * @settings.blockSizeHalf

  ##
  # This hash descripes the make-up of the texture files.
  # The file is split into multiple groups that consist of block types at
  # their different rotations, each occupying one row in the file.
  #
  @TextureFileDescription:
    'basic':
      # This hitbox is used to detect which side of the block
      # is at a given pixel by looking up the color.
      #   RGBA       side
      # #0000FFFF => Top
      # #00FF00FF => East
      # #FF0000FF => South
      'hitbox':          1
      # #000000FF => Floor
      'floor-hitbox':    1
      'solid':           1
      'floor':           1
      'backside':        1
      'outline':         1
      'hole-middle':     2
      'hole-low':        2
      'hole-bottom':     2
      # TODO: Add cutouts for straights/crossings
    'cutouts-top':
      'crossing':        1
      'curve':           4
      'straight':        2
    'cutouts-bottom':
      'crossing':        1
      'curve':           4
      'straight':        2
    'top':
      'crossing':        1
      'crossing-hole':   1
      'curve':           4
      'straight':        2
    'middle':
      'crossing':        1
      'curve':           4
      'straight':        2
      'dive':            4
      'drop-middle':     4
      'drop-low':        4
      'exchange-alt':    4
      'exchange':        4
    'low':
      'crossing':        1
      'curve':           4
      'straight':        2

  ##
  # Defines which block types require top cutouts at what rotations.
  @Cutouts:
    'straight':          [0, 180]
    'curve':             [0,  90]
    'crossing': [0, 90, 180, 270]

  ##
  # Defines which block types require middle holes at what rotations.
  @MidHoles:
    'crossing': [0, 90, 180, 270]
    'curve':             [0,  90]
    'straight':          [0, 180]
    'dive':                 [  0]
    'drop-middle':          [  0]
    'exchange':             [  0]
    'exchange-alt':         [ 90]

  ##
  # Defines which block types require low holes at what rotations.
  @LowHoles:
    'dive':                 [180]
    'drop-low':             [  0]
    'exchange':             [ 90]
    'exchange-alt':         [  0]

  ##
  # Defines which block types require bottom cutouts at what rotations.
  @BottomHoles:
    'straight':          [0, 180]
    'curve':             [0,  90]
    'crossing': [0, 90, 180, 270]
