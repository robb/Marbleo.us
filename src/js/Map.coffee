class Map
  constructor: (size) ->
    throw new Error "Size must be between 1 and 255" unless 1 < size < 255
    ### @constant ###
    @size = size

    ### @constant ###
    # initialize grid
    @grid = new Array Math.pow(@size, 3)
    for x in [0...Math.pow(@size, 3)]
      @grid[x] = null

    @rotation = 0
    @setNeedsRedraw yes

  setBlock: (block, x, y, z) ->
    @validateCoordinates x, y, z
    [x, y] = @applyRotation x, y if @rotation
    @grid[x + y * @size + z * @size * @size] = block
    @setNeedsRedraw yes

  getBlock: (x, y, z) ->
    @validateCoordinates x, y, z
    [x, y] = @applyRotation x, y if @rotation
    return @grid[x + y * @size + z * @size * @size]

  removeBlock: (x, y, z) ->
    block = @getBlock x, y, z
    @setBlock null, x, y, z
    return block

  heightAt: (x, y) ->
    @validateCoordinates x, y, 0

    height = 0
    while height < @size and @getBlock x, y, height
      height++
    return height

  getStack: (x, y, z = 0) ->
    @validateCoordinates x, y, z

    return [] if z > height = @heightAt x, y

    blocks = new Array
    for currentZ in [z...height]
      blocks.push @getBlock x, y, currentZ
    return blocks

  setStack: (blocks, x, y, z = 0) ->
    @validateCoordinates x, y, z
    unless blocks.length - 1 + z < @size
      throw new Error "Cannot place stack, height out of bounds"

    for block in blocks
      @setBlock block, x, y, z++

  removeStack: (x, y, z = 0) ->
    stack = @getStack x, y, z
    for currentZ in [z...z + stack.length]
      @setBlock null, x, y, currentZ
    return stack

  validateCoordinates: (x, y, z) ->
    throw new Error "Index out of bounds #{x}:#{y}:#{z}" unless 0 <= x < @size and
                                                                0 <= y < @size and
                                                                0 <= z < @size

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
               @getBlock(x - 1,     y,     z) and
               @getBlock(    x, y + 1,     z) and
               @getBlock(    x,     y, z + 1)

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
