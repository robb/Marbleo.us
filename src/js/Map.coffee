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
    return @grid[x][y][z]
  
  compress: ->
    throw new Error "Compression has not yet been implemented"
