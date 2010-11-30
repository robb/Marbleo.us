class Map
  constructor: (size, canvasID) ->
    ### @constant ###
    @size    =            size
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

  blocksEach: (functionToApply) ->
    x = @size - 1
    while x + 1
      y = 0
      while y < @size
        z = 0
        while z < @size
          functionToApply @grid[x + y * @size + z * @size * @size], x, y, z
          z++
        y++
      x--

  visibleBlocksEach: (functionToAppy) ->
    @blocksEach (block, x, y, z) =>
      hidden = 0       <= (x - 1) and
               (y + 1) <  @size   and
               (z + 1) <  @size   and
               @grid[(x - 1) +      y  * @size +      z  * @size * @size] isnt undefined and
               @grid[     x  + (y + 1) * @size +      z  * @size * @size] isnt undefined and
               @grid[     x  +      y  * @size + (z + 1) * @size * @size] isnt undefined

      functionToAppy block, x, y, z unless hidden

  compress: ->
    throw new Error "Compression has not yet been implemented"
