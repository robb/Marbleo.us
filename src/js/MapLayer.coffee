class MapLayer extends Layer
  constructor: (@renderer, @map) ->
    super

    @cache = {}

  redraw: ->
    @clear()

    @drawFloor()

    @map.coordinatesEach (bX, bY, bZ) =>
      if block = @map.getBlock bX, bY, bZ
        @drawBlock @context, block

  drawFloor: ->
    for x in [0...@map.size]
      for y in [0...@map.size]
        [screenX, screenY] = @renderer.floorCoordinates x, y
        @context.drawImage @getTexture('basic','floor'),
                           screenX,
                           screenY,
                           Settings.textureSize,
                           Settings.textureSize

  drawBlock: (context, block, x, y) ->
    [x, y] = @renderer.renderingCoordinatesForBlock block unless x? and y?

    cache_key = block.toString()

    unless cached = @cache[cache_key]
      [topType, topRotation] = block.getProperty 'top'
      [midType, midRotation] = block.getProperty 'middle'
      [lowType, lowRotation] = block.getProperty 'low'

      @cache[cache_key] = cached = document.createElement 'canvas'
      cached.height = cached.width = Settings.textureSize
      buffer = cached.getContext "2d"

      # Render the inner contents of the block only if the block is not fully
      # opaque.
      if block.selected or block.opacity isnt 1.0
        backside = @getTexture 'basic', 'backside'
        buffer.drawImage backside, 0, 0

        # Render the low layer
        if lowType
          low_texture = @getTexture 'low', lowType, lowRotation
          if low_texture?
            buffer.drawImage low_texture, 0, 0

        # Render the middle layer
        if midType
          mid_texture = @getTexture 'middle', midType, midRotation
          if mid_texture?
            buffer.drawImage mid_texture, 0, 0

      if block.selected
        buffer.globalAlpha = 0.3
      else
        buffer.globalAlpha = block.opacity || 1.0

      solid = @getTexture 'basic', 'solid'
      buffer.drawImage solid, 0, 0

      buffer.globalAlpha = 1.0

      # Render the top layer
      if topType
        top_texture = @getTexture 'top', topType, topRotation
        if top_texture?
          buffer.globalAlpha = 0.6 if block.selected
          buffer.drawImage top_texture, 0, 0
          buffer.globalAlpha = 1.0

      # Render the middle holes on the side of block
      midHoles = MapLayer.MidHoles[midType]
      if midHoles
        for pos in midHoles
          if (pos + midRotation) % 360 == 0
            midHoleSouth = @getTexture 'basic', 'hole-middle', 0
            buffer.drawImage midHoleSouth, 0, 0

          if (pos + midRotation) % 360 == 90
            midHoleEast = @getTexture 'basic', 'hole-middle', 90
            buffer.drawImage midHoleEast, 0, 0

      # Render the lows holes on the side of block
      lowHoles = MapLayer.LowHoles[midType]
      if lowHoles
        for pos in lowHoles
          if (pos + midRotation) % 360 == 0
            lowHoleSouth = @getTexture 'basic', 'hole-low', 0
            buffer.drawImage lowHoleSouth, 0, 0

          if (pos + midRotation) % 360 == 90
            lowHoleEast = @getTexture 'basic', 'hole-low', 90
            buffer.drawImage lowHoleEast, 0, 0

      # Render the bottom holes that are formed if this block stands on top
      # of another.
      bottomHoles = MapLayer.BottomHoles[lowType]
      if bottomHoles
        for pos in bottomHoles
          if (pos + lowRotation) % 360 == 0
            bottomHoleSouth = @getTexture 'basic', 'hole-bottom', 0
            buffer.drawImage bottomHoleSouth, 0, 0

          if (pos + lowRotation) % 360 == 90
            bottomHoleEast = @getTexture 'basic', 'hole-bottom', 90
            buffer.drawImage bottomHoleEast, 0, 0

      # Draw the outline
      @drawOutline buffer, 0, 0

      # Remove transparent parts at the edges of the block.
      type = if topType is 'crossing-hole' then 'crossing' else topType
      cutouts = @getTexture 'cutouts-top', type, topRotation
      if cutouts
        buffer.globalCompositeOperation = 'destination-out'
        buffer.drawImage cutouts, 0, 0
        buffer.globalCompositeOperation = 'source-over'

      cutouts = @getTexture 'cutouts-bottom', lowType, lowRotation
      if cutouts
        buffer.globalCompositeOperation = 'destination-out'
        buffer.drawImage cutouts, 0, 0
        buffer.globalCompositeOperation = 'source-over'

    context.drawImage cached, x, y

  # Draws a block outline in the given graphics context.
  drawOutline: (context, x, y) ->
    context.drawImage @getTexture('basic','outline'), x, y

  # Defines which block types require top cutouts at what rotations.
  @Cutouts:
    'straight':          [0, 180]
    'curve':             [0,  90]
    'crossing': [0, 90, 180, 270]

  # Defines which block types require middle holes at what rotations.
  @MidHoles:
    'crossing': [0, 90, 180, 270]
    'curve':             [0,  90]
    'straight':          [0, 180]
    'dive':                 [  0]
    'drop-middle':          [  0]
    'exchange':             [  0]
    'exchange-alt':         [ 90]

  # Defines which block types require low holes at what rotations.
  @LowHoles:
    'dive':                 [180]
    'drop-low':             [  0]
    'exchange':             [ 90]
    'exchange-alt':         [  0]

  # Defines which block types require bottom cutouts at what rotations.
  @BottomHoles:
    'straight':          [0, 180]
    'curve':             [0,  90]
    'crossing': [0, 90, 180, 270]

