class VisibilityLayer extends Layer
  constructor: (@map, @renderer, @marble) ->
    super @map, @renderer

    @cache = {}

  redraw: ->
    @clear()

    [mX, mY, mZ]         = @marble.getCoordinates()
    [mScreenX, mScreenY] = @renderer.renderingCoordinatesForMarble @marble
    r                    = @marble.radius

    @map.coordinatesEach (x, y, z) =>
      # Ignore blocks behind the marble
      if      x  * Settings.blockSize >= mX + @marble.radius or
         (y + 1) * Settings.blockSize <= mY - @marble.radius or
         (z + 1) * Settings.blockSize <= mZ - @marble.radius
        return

      return unless block = @map.getBlock x, y, z

      [screenX,  screenY] = @renderer.renderingCoordinatesForBlock block
      return unless screenX <= mScreenX + r and mScreenX - r < mScreenX + Settings.textureSize and
                    screenY <= mScreenY + r and mScreenY - r < mScreenY + Settings.textureSize

      if (x + 1) * Settings.blockSize < mX - r or
              y  * Settings.blockSize > mY + r or
              z  * Settings.blockSize > mZ + r# * 4
        @drawBlock @context, block, screenX, screenY
      else
        @drawTopMask @context, block, screenX, screenY

  drawBlock: (context, block, x, y) ->
    cacheKey = block.toString()

    unless cached = @cache[cacheKey]
      [topType, topRotation] = block.getProperty 'top'
      [midType, midRotation] = block.getProperty 'middle'
      [lowType, lowRotation] = block.getProperty 'low'

      @cache[cacheKey] = cached = document.createElement 'canvas'
      cached.height = cached.width = Settings.textureSize
      buffer = cached.getContext "2d"

      hitbox = @getTexture 'basic', 'hitbox'
      buffer.globalCompositeOperation = 'source-over'
      buffer.drawImage hitbox, 0, 0

      # Remove transparent parts at the edges of the block.
      type = if topType is 'crossing-hole' then 'crossing' else topType

      cutouts = @getTexture 'cutouts-top', type, topRotation

      buffer.globalCompositeOperation = 'destination-out'
      if cutouts
        buffer.drawImage cutouts, 0, 0

      cutouts = @getTexture 'cutouts-bottom', lowType, lowRotation
      if cutouts
        buffer.drawImage cutouts, 0, 0

    context.globalCompositeOperation = 'source-over'
    context.drawImage cached, x, y

  drawTopMask: (context, block, x, y) ->
    [topType, topRotation] = block.getProperty 'top'
    [midType, midRotation] = block.getProperty 'middle'
    [lowType, lowRotation] = block.getProperty 'low'

    context.globalCompositeOperation = 'source-over'
    hitbox = @getTexture 'basic', 'hitbox'
    context.drawImage hitbox, x, y

    context.globalCompositeOperation = 'destination-out'

    topLayer = @getTexture 'top', topType, topRotation
    context.drawImage topLayer, x, y if topLayer

    type = if topType is 'crossing-hole' then 'crossing' else topType

    cutoutsTop = @getTexture 'cutouts-top', type, topRotation
    context.drawImage cutoutsTop, x, y if cutoutsTop

    cutoutsBottom = @getTexture 'cutouts-bottom', lowType, lowRotation
    context.drawImage cutoutsBottom, x, y if cutoutsBottom

    # Render the middle holes on the side of block
    if midHoles = VisibilityLayer.MidHoles[midType]
      for pos in midHoles
        if (pos + midRotation) % 360 == 0
          midHoleSouth = @getTexture 'basic', 'hole-middle', 0
          context.drawImage midHoleSouth, x, y

        if (pos + midRotation) % 360 == 90
          midHoleEast = @getTexture 'basic', 'hole-middle', 90
          context.drawImage midHoleEast, x, y

    # Render the lows holes on the side of block
    if lowHoles = VisibilityLayer.LowHoles[midType]
      for pos in lowHoles
        if (pos + midRotation) % 360 == 0
          lowHoleSouth = @getTexture 'basic', 'hole-low', 0
          context.drawImage lowHoleSouth, x, y

        if (pos + midRotation) % 360 == 90
          lowHoleEast = @getTexture 'basic', 'hole-low', 90
          context.drawImage lowHoleEast, x, y

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