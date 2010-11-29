class Map
  constructor: (@size, canvasID) ->
    ### @constant ###
    @size    ?=             7
    ### @constant ###
    canvasID ?= '#main-canvas'

    ### @constant ###
    # initialize grid
    @grid = new Array Math.pow(@size, 3)

    @setNeedsRedraw yes

  setBlock: (block, x, y, z) ->
    @grid[x + y * @size + z * @size * @size] = block

  getBlock: (x, y, z) ->
    throw new Error unless x? and y? and z?
    return @grid[x + y * @size + z * @size * @size]
  
  selectBlock: (@selectedBlock) ->
    @setNeedsRedraw yes
    return @selectedBlock

  setNeedsRedraw: (@needsRedraw) ->

  compress: ->
    throw new Error "Compression has not yet been implemented"
