class Map
  constructor: (size) ->
    ### @constant ###
    @size    =            size

    ### @constant ###
    # initialize grid
    @grid = new Array Math.pow(@size, 3)
    @rotation = 0
    @setNeedsRedraw yes

  setBlock: (block, x, y, z) ->
    [x, y] = @applyRotation x, y if @rotation
    @grid[x + y * @size + z * @size * @size] = block

  getBlock: (x, y, z) ->
    [x, y] = @applyRotation x, y if @rotation
    return @grid[x + y * @size + z * @size * @size]

  popBlock: (x, y, z) ->
    block = @getBlock x, y, z
    @setBlock null, x, y, z
    return block

  applyRotation: (x, y) ->
    switch @rotation
      when  90 then return [@size - 1 - y,             x]
      when 180 then return [@size - 1 - x, @size - 1 - y]
      when 270 then return [            y, @size - 1 - x]
      else
        return [x, y]

  setNeedsRedraw: (@needsRedraw) ->

  blocksEach: (functionToApply) ->
    x = @size - 1
    while x + 1
      y = 0
      while y < @size
        z = 0
        while z < @size
          functionToApply @getBlock(x, y, z), x, y, z
          z++
        y++
      x--

  visibleBlocksEach: (functionToAppy) ->
    @blocksEach (block, x, y, z) =>
      return unless block
      hidden = 0       <= (x - 1) and
               (y + 1) <  @size   and
               (z + 1) <  @size   and
               @grid[(x - 1) +      y  * @size +      z  * @size * @size] and
               @grid[     x  + (y + 1) * @size +      z  * @size * @size] and
               @grid[     x  +      y  * @size + (z + 1) * @size * @size]

      functionToAppy block, x, y, z unless hidden

  rotateCW:  -> @rotate  true
  rotateCCW: -> @rotate false
  rotate: (clockwise) ->
    if clockwise
      @rotation = (@rotation +  90) % 360
    else
      @rotation = (@rotation + 270) % 360

    for block in @grid
      block.rotate clockwise if block
    @setNeedsRedraw yes

  compress: ->
    throw new Error "Compression has not yet been implemented"
