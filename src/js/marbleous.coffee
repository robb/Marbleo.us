MOD = 1
BLOCK_SIZE    = 101 * MOD
CANVAS_HEIGHT = 630 * MOD
CANVAS_WIDTH  = 800 * MOD

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
    middle:         'straight'
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

    @canvas = $(canvasID)
    @canvas.attr "width",  CANVAS_WIDTH
    @canvas.attr "height", CANVAS_HEIGHT
    
    # TODO load block textures
    
    @context = @canvas.get(0).getContext "2d"

  # TODO: Move this to a dedicated drawing class
  drawMap: ->
    console.log @grid
    
    for x in [0...@size]
      for y in [0...@size]
        for z in [0...@size]
          currentBlock = @getBlock(x,y,z)          
          @drawBlock(currentBlock, x, y, z) if currentBlock?

  drawBlock: (block, x, y, z) ->
    offsetY = -0.5 + CANVAS_HEIGHT - 3 / 4 * BLOCK_SIZE - (2 * z + x - y + @size) * BLOCK_SIZE / 4
    offsetX =  1.5 + (x + y) * BLOCK_SIZE / 2

    @drawOutline x, y, z, offsetX, offsetY

    console.log "Drawing block of type #{block.type} at #{x} #{y}#{z}"

  # TODO: Replace this with a bitmap operation instead
  drawOutline: (x, y, z, offsetX, offsetY, color) ->
    # Draw outline
    @context.setLineWidth 1
    @context.strokeStyle = color || '#000';
    
    @context.moveTo offsetX,                  offsetY + BLOCK_SIZE / 4
    @context.lineTo offsetX + BLOCK_SIZE / 2, offsetY
    @context.lineTo offsetX + BLOCK_SIZE,     offsetY + BLOCK_SIZE / 4
    @context.lineTo offsetX + BLOCK_SIZE / 2, offsetY + BLOCK_SIZE / 2
    @context.lineTo offsetX,                  offsetY + BLOCK_SIZE / 4

    @context.lineTo offsetX,                  offsetY + BLOCK_SIZE / 2 + BLOCK_SIZE / 4
    @context.lineTo offsetX + BLOCK_SIZE / 2, offsetY + BLOCK_SIZE
    @context.lineTo offsetX + BLOCK_SIZE,     offsetY + BLOCK_SIZE / 2 + BLOCK_SIZE / 4
    @context.lineTo offsetX + BLOCK_SIZE,     offsetY + BLOCK_SIZE / 4

    @context.moveTo offsetX + BLOCK_SIZE / 2, offsetY + BLOCK_SIZE / 2
    @context.lineTo offsetX + BLOCK_SIZE / 2, offsetY + BLOCK_SIZE
    
    @context.stroke()

  getBlock: (x, y, z) ->
    throw new Error unless x? and y? and z?
    if @grid[x][y][z]?
      return @grid[x][y][z]
    else
      return null
  
  compress: ->
    throw new Error "Compression has not yet been implemented"

$(document).ready ->
  @map = new Map(7)

  @map.drawMap()
