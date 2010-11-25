DEBUG = on && console?

#TODO: Rather provide different texture files for different scales
#      instead of using a global multiplier as browser tend to handle
#      anti-aliasing differently.

MOD = 1

BLOCK_SIZE         = Math.floor(101 * MOD)
BLOCK_SIZE_HALF    = Math.floor(BLOCK_SIZE / 2)
BLOCK_SIZE_QUARTER = Math.floor(BLOCK_SIZE_HALF / 2)
CANVAS_HEIGHT      = 8 * BLOCK_SIZE
CANVAS_WIDTH       = 7 * BLOCK_SIZE

TEXTURE_FILE       = 'img/outline.png'
TEXTURE_BLOCK_SIZE = 101

# All the types of blocks we support
Types =
  'blank':
    topRotation:             0
    middleRotation:          0
  'double-straight':
    top:            'straight'
    topRotation:            90
    middle:         'straight'
    middleRotation:         90
  'curve-straight':
    top:               'curve'
    topRotation:             0
    middle:         'straight'
    middleRotation:         90
  'curve-straight-alt':
    top:               'curve'
    topRotation:           270
    middle:         'straight'
    middleRotation:         90
  'curve-exchange':
    top:               'curve'
    topRotation:             0
    middle:         'exchange'
    middleRotation:        270
  'curve-exchange-alt':
    top:               'curve'
    topRotation:           270
    middle:     'exchange-alt'
    middleRotation:          0
  'straight-exchange':
    top:            'straight'
    topRotation:            90
    middle:         'exchange'
    middleRotation:          0
  'straight-exchange-alt':
    top:            'straight'
    topRotation:            90
    middle:     'exchange-alt'
    middleRotation:          0
  'curve-dive':
    top:               'curve'
    topRotation:             0
    middle:             'dive'
    middleRotation:         90
  'curve-dive-alt':
    top:               'curve'
    topRotation:            90
    middle:             'dive'
    middleRotation:         90
  'crossing-straight':
    top:            'crossing'
    topRotation:             0
    middle:   'tunnel-straight'
    middleRotation:          0
  'crossing-hole':
    top:       'crossing-hole'
    topRotation:             0
    middle:       'drop-middle'
    middleRotation:         90
  'crossing-hole':
    top:       'crossing-hole'
    topRotation:             0
    middle:         'drop-low'
    middleRotation:         90

class Block
  constructor: (@type, rotation) ->
    @properties = Types[@type] || Types['blank']

    switch rotation
      when 90
        @rotateCW
      when 180
        @rotateCW
        @rotateCW
      when 270
        @rotateCCW

  rotateCW:  -> @rotate  true
  rotateCCW: -> @rotate false
  rotate: (clockwise) ->
    if clockwise
      @properties.topRotation    = (@properties.topRotation    + 90) % 360
      @properties.middleRotation = (@properties.middleRotation + 90) % 360
    else
      @properties.topRotation    = (@properties.topRotation    - 90) % 360
      @properties.middleRotation = (@properties.middleRotation - 90) % 360

class Map
  constructor: (@size, canvasID) ->
    @size    ?=             7
    canvasID ?= '#main-canvas'
    
    # initialize grid
    @grid = new Array(@size)
    for x in [0...@size]
      @grid[x] = new Array(@size)
      for y in [0...@size]
        @grid[x][y] = new Array(@size)

  getBlock: (x, y, z) ->
    throw new Error unless x? and y? and z?
    if @grid[x][y][z]?
      return @grid[x][y][z]
    else
      return null
  
  compress: ->
    throw new Error "Compression has not yet been implemented"

class Renderer
  _supportedTextures:
    #name       number of rotations
    'outline':  1
    'curve':    4
    'straight': 2

  constructor: (@map, canvasID, @onload) ->
    @canvas = $(canvasID)
    @canvas.attr "width",  CANVAS_WIDTH
    @canvas.attr "height", CANVAS_HEIGHT
    @context = @canvas.get(0).getContext "2d"

    # Load all textures from the texture file
    @textures = {}

    textureFile = new Image
    textureFile.onload = =>
      textureOffset = 0
      for texture, rotationsCount of @_supportedTextures
        console.log "loading #{texture}" if DEBUG

        @textures[texture] = new Array rotationsCount
        for rotation in [0...rotationsCount]
          canvas = document.createElement 'canvas'
          canvas.width  = BLOCK_SIZE
          canvas.height = BLOCK_SIZE
          context = canvas.getContext '2d'
          try
            context.drawImage textureFile,
                              rotation * BLOCK_SIZE, textureOffset, TEXTURE_BLOCK_SIZE, TEXTURE_BLOCK_SIZE
                                                  0,             0, BLOCK_SIZE, BLOCK_SIZE
          catch error
            if DEBUG
              console.log "Encountered error #{error} while loading texture: #{texture}"
              console.log "Texture file may be too small" if error.name is "INDEX_SIZE_ERR"
            break

          @textures[texture][rotation] = canvas
        textureOffset++

      return @onload()

    textureFile.src = TEXTURE_FILE

  getTexture: (name, rotation) ->
    rotation ?= 0
    
    return @textures[name][rotation]

  # TODO: Move this to a dedicated drawing class
  drawMap: ->
    for x in [0...@map.size]
      for y in [0...@map.size]
        for z in [0...@map.size]
          currentBlock = @map.getBlock(x,y,z)          
          @drawBlock(currentBlock, x, y, z) # if currentBlock?

  drawBlock: (block, x, y, z) ->
    offsetY = CANVAS_HEIGHT - 3 * BLOCK_SIZE_QUARTER - (2 * z + x - y + @map.size) * BLOCK_SIZE_QUARTER
    offsetX = (x + y) * BLOCK_SIZE_HALF

    @drawOutline offsetX, offsetY

  # TODO: Replace this with a bitmap operation instead
  drawOutline: (x, y, color) ->
    @context.drawImage @getTexture('outline'), x, y, BLOCK_SIZE, BLOCK_SIZE

$(document).ready ->
  @map      = new Map(7)

  @renderer = new Renderer @map, '#main-canvas', =>
    @renderer.drawMap()