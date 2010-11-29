MOD = 1

BLOCK_SIZE         = Math.floor(101 * MOD)
BLOCK_SIZE_HALF    = Math.floor(BLOCK_SIZE / 2)
BLOCK_SIZE_QUARTER = Math.floor(BLOCK_SIZE_HALF / 2)
CANVAS_HEIGHT      = 8 * BLOCK_SIZE
CANVAS_WIDTH       = 7 * BLOCK_SIZE

TEXTURE_FILE       = '/img/textures.png'
TEXTURE_BLOCK_SIZE = 101

class Renderer
  _supportedTextures:
    #texture group:
    #  name: number of rotations
    'hitboxes':
      'block':           1
    'basic':
      'backline':        1
      'outline':         1
    'top':
      'curve':           4
      'straight':        2
      'crossing':        1
      'crossing-hole':   1
    'middle':
      'curve':           4
      'straight':        2
      'dive':            4


  constructor: (@map, canvasID, @onload) ->
    @canvas = $(canvasID)
    @canvas.attr "width",   CANVAS_WIDTH
    @canvas.attr "height", CANVAS_HEIGHT
    @context = @canvas.get(0).getContext "2d"

    # Load all textures from the texture file
    @textures = {}

    textureFile = new Image
    textureFile.onload = =>
      textureOffset = 0
      for textureGroup, textureDescription of @_supportedTextures
        for texture, rotationsCount of textureDescription
          console.log "loading #{textureGroup}.#{texture}" if DEBUG

          @textures[textureGroup] ?= {}
          @textures[textureGroup][texture] = new Array rotationsCount
          for rotation in [0...rotationsCount]
            canvas = document.createElement 'canvas'
            canvas.width  = BLOCK_SIZE
            canvas.height = BLOCK_SIZE
            context = canvas.getContext '2d'
            try
              context.drawImage textureFile,
                                rotation * TEXTURE_BLOCK_SIZE, textureOffset * TEXTURE_BLOCK_SIZE, TEXTURE_BLOCK_SIZE, TEXTURE_BLOCK_SIZE
                                                            0,                                  0,         BLOCK_SIZE,         BLOCK_SIZE
            catch error
              if DEBUG
                console.log "Encountered error #{error} while loading texture: #{texture}"
                console.log "Texture file may be too small" if error.name is "INDEX_SIZE_ERR"
              break

            @textures[textureGroup][texture][rotation] = canvas
          textureOffset++

      return @onload()

    textureFile.src = TEXTURE_FILE

  # This calculates the position of the top-left pixel of the square that the
  # textures get rendered in.
  # Please note that this position lies not in the block in terms of
  # hit-testing
  #
  # Relative to the point of origin of the canvas
  renderingCoordinatesForBlock: (x,y,z) ->
    screenX = (x + y) * BLOCK_SIZE_HALF
    screenY = CANVAS_HEIGHT - 3 * BLOCK_SIZE_QUARTER - (2 * z + x - y + @map.size) * BLOCK_SIZE_QUARTER

    [screenX, screenY]

  # Please note that x and y must be relative to the point of origin of the
  # canvas
  blockAtScreenCoordinates: (x, y) ->
    # Brute force at O(n^3) seems fast enough here
    for blockX in [0...@map.size]
      for blockY in [0...@map.size]
        for blockZ in [0...@map.size]
          continue unless currentBlock = @map.getBlock blockX, blockY, blockZ
          [screenX, screenY] = @renderingCoordinatesForBlock blockX, blockY, blockZ

          # TODO: There seems to be a minor difference on Safari – investigate
          if screenX <= x < (screenX + BLOCK_SIZE) and screenY <= y < (screenY + BLOCK_SIZE)
            pixel = @getTexture('hitboxes','block').getContext('2d').getImageData x - screenX, y - screenY, 1, 1

            return currentBlock if pixel.data[3] > 0

    return null

  getTexture: (group, type, rotation) ->
    unless rotation
      return @textures[group][type][0]

    rotationCount = @_supportedTextures[group][type]
    return @textures[group][type][rotation / 90 % rotationCount]

  drawMap: ->
    for x in [@map.size - 1..0]
      for y in [0...@map.size]
        for z in [0...@map.size]
          currentBlock = @map.getBlock(x,y,z)
          @drawBlock(currentBlock, x, y, z) #if currentBlock?

  drawBlock: (block, x, y, z) ->
    [screenX, screenY] = @renderingCoordinatesForBlock x, y, z

    if block?
      if block.properties.low
        low_texture = @getTexture 'low', block.properties.low, block.properties.lowRotation
        @context.drawImage low_texture, screenX, screenY, BLOCK_SIZE, BLOCK_SIZE

      if block.properties.middle
        mid_texture = @getTexture 'middle', block.properties.middle, block.properties.middleRotation
        @context.drawImage mid_texture, screenX, screenY, BLOCK_SIZE, BLOCK_SIZE

      if block.properties.top
        top_texture = @getTexture 'top', block.properties.top, block.properties.topRotation
        @context.drawImage top_texture, screenX, screenY, BLOCK_SIZE, BLOCK_SIZE

      @drawOutline screenX, screenY

  drawOutline: (x, y, color) ->
    @context.drawImage @getTexture('basic','outline'), x, y, BLOCK_SIZE, BLOCK_SIZE
