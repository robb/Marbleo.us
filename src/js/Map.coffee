##
# This class models a map.
#
# A map in the context of marbleo.us is a three-dimensional grid of blocks.
#
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

  ##
  # Sets the block at the given coordinates to the given block.
  #
  setBlock: (block, x, y, z) ->
    @validateCoordinates x, y, z
    [x, y] = @applyRotation x, y if @rotation
    @grid[x + y * @size + z * @size * @size] = block
    @setNeedsRedraw yes

  ##
  # Returns the block at the given coordinates.
  #
  getBlock: (x, y, z) ->
    @validateCoordinates x, y, z
    [x, y] = @applyRotation x, y if @rotation
    return @grid[x + y * @size + z * @size * @size]

  ##
  # Returns the block at the given coordinates and removes it from the map.
  #
  removeBlock: (x, y, z) ->
    block = @getBlock x, y, z
    @setBlock null, x, y, z
    return block

  ##
  # Returns the height of the block stack at the given coordinates.
  #
  heightAt: (x, y) ->
    @validateCoordinates x, y, 0

    height = 0
    while height < @size and @getBlock x, y, height
      height++
    return height

  ##
  # Returns all blocks at the given coordinates.
  #
  getStack: (x, y, z = 0) ->
    @validateCoordinates x, y, z

    return [] if z > height = @heightAt x, y

    blocks = new Array
    for currentZ in [z...height]
      blocks.push @getBlock x, y, currentZ
    return blocks

  ##
  # Blaces a stack of blocks at the given coordinates
  #
  setStack: (blocks, x, y, z = 0) ->
    @validateCoordinates x, y, z
    unless blocks.length - 1 + z < @size
      throw new Error "Cannot place stack, height out of bounds"

    for block in blocks
      @setBlock block, x, y, z++

  ##
  # Returns the stack at the given coordinates and removes it from the map.
  #
  removeStack: (x, y, z = 0) ->
    stack = @getStack x, y, z
    for currentZ in [z...z + stack.length]
      @setBlock null, x, y, currentZ
    return stack

  ##
  # Validates the map.
  # TODO: Currently only checks for floating blocks. Validate block stacks
  #       regarding matching low and top properties.
  #
  validate: ->
    @blocksEach (block, x, y, z) =>
      if block and z > 0 and not @getBlock x, y, z - 1
        throw new Error "Encountered floating block at #{x}:#{y}:#{z}"

  ##
  # Makes sure that the given coordinates are within the bounds of the map.
  ä
  validateCoordinates: (x, y, z) ->
    throw new Error "Index out of bounds #{x}:#{y}:#{z}" unless 0 <= x < @size and
                                                                0 <= y < @size and
                                                                0 <= z < @size

  ##
  # Given a pair of coordinates, transforms the coordinates based on the
  # rotation of the map.
  #
  applyRotation: (x, y) ->
    switch @rotation
      when  90 then return [@size - 1 - y,             x]
      when 180 then return [@size - 1 - x, @size - 1 - y]
      when 270 then return [            y, @size - 1 - x]
      else
        return [x, y]

  ##
  # Sets the needs redraw state of the block.
  #
  setNeedsRedraw: (@needsRedraw) ->

  ##
  # Iterates over all positions of the map, applies the given function.
  #
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

  ##
  # Rotates the map 90 degrees clockwise
  rotateCW:  -> @rotate  true

  ##
  # Rotates the map 90 degrees counter-clockwise
  rotateCCW: -> @rotate false

  rotate: (clockwise) ->
    if clockwise
      @rotation = (@rotation +  90) % 360
    else
      @rotation = (@rotation + 270) % 360

    for block in @grid
      block.rotate clockwise if block
    @setNeedsRedraw yes
