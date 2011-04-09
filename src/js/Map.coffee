# This class models a map.
#
# A map in the context of marbleo.us is a three-dimensional grid of blocks.
class Map extends EventEmitter
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

    @emit 'didChange'

  forceUpdate: ->
    @emit 'didChange'

  blockDidChangeListener: =>
    @emit 'didChange'

  # Sets the block at the given coordinates to the given block.
  setBlock: (block, x, y, z, silent = no) ->
    @validateCoordinates x, y, z
    block.setCoordinates x, y, z if block

    [x, y] = @applyRotation x, y if @rotation
    position = x + y * @size + z * @size * @size

    @grid[position]?.removeListener 'didChange', @blockDidChangeListener
    @grid[position] = block
    @grid[position]?.addListener 'didChange', @blockDidChangeListener

    @emit 'didChange' unless silent

  # Returns the block at the given coordinates.
  getBlock: (x, y, z) ->
    @validateCoordinates x, y, z
    [x, y] = @applyRotation x, y if @rotation
    return @grid[x + y * @size + z * @size * @size]

  # Returns the block at the given coordinates and removes it from the map.
  removeBlock: (x, y, z, silent = no) ->
    block = @getBlock x, y, z
    @setBlock null, x, y, z, yes

    block?.removeListener 'didChange', @blockDidChangeListener
    block?.setCoordinates null, null, null

    @emit 'didChange' unless silent

    return block

  # Returns the height of the block stack at the given coordinates.
  heightAt: (x, y) ->
    @validateCoordinates x, y, 0

    height = 0
    while height < @size and @getBlock x, y, height
      height++
    return height

  # Returns all blocks at the given coordinates.
  getStack: (x, y, z = 0) ->
    @validateCoordinates x, y, z

    return [] if z > height = @heightAt x, y

    blocks = new Array
    for currentZ in [z...height]
      blocks.push @getBlock x, y, currentZ
    return blocks

  # Blaces a stack of blocks at the given coordinates
  setStack: (blocks, x, y, z = 0, silent = no) ->
    @validateCoordinates x, y, z
    unless blocks.length - 1 + z < @size
      throw new Error "Cannot place stack, height out of bounds"

    for block in blocks
      @setBlock block, x, y, z++, yes

    @emit 'didChange' unless silent

  # Returns the stack at the given coordinates and removes it from the map.
  removeStack: (x, y, z = 0, silent = no) ->
    stack = @getStack x, y, z

    for currentZ in [z...z + stack.length]
      @setBlock null, x, y, z++, yes

    @emit 'didChange' unless silent

    return stack

  # Validates the map.
  # TODO: Currently only checks for floating blocks. Validate block stacks
  #       regarding matching low and top properties.
  validate: ->
    @blocksEach (block) =>
      [x, y, z] = block.getCoordinates()
      if block and z > 0 and not @getBlock x, y, z - 1
        throw new Error "Encountered floating block at #{x}:#{y}:#{z}"

  # Makes sure that the given coordinates are within the bounds of the map.
  validateCoordinates: (x, y, z) ->
    throw new Error "Index out of bounds #{x}:#{y}:#{z}" unless 0 <= x < @size and
                                                                0 <= y < @size and
                                                                0 <= z < @size

  # Given a pair of coordinates, transforms the coordinates based on the
  # rotation of the map.
  applyRotation: (x, y) ->
    switch @rotation
      when  90 then return [@size - 1 - y,             x]
      when 180 then return [@size - 1 - x, @size - 1 - y]
      when 270 then return [            y, @size - 1 - x]
      else
        return [x, y]

  # Iterates over all block on the map, applies the given function.
  blocksEach: (functionToApply) ->
    x = @size - 1
    while x + 1
      y = 0
      while y < @size
        z = 0
        while z < @size
          functionToApply block if block = @getBlock(x, y, z)
          z++
        y++
      x--

  coordinatesEach: (functionToApply) ->
    x = @size - 1
    while x + 1
      y = 0
      while y < @size
        z = 0
        while z < @size
          functionToApply(x, y, z)
          z++
        y++
      x--

  # Rotates the map 90 degrees clockwise
  rotateCW: -> @rotate true

  # Rotates the map 90 degrees counter-clockwise
  rotateCCW: -> @rotate false

  rotate: (clockwise, silent = no) ->
    if clockwise
      @rotation = (@rotation +  90) % 360
    else
      @rotation = (@rotation + 270) % 360

    for block in @grid
      if block
        block.rotate clockwise, yes, yes, yes, yes
        [x, y, z] = block.getCoordinates()
        if clockwise
          [x, y] = [            y, @size - 1 - x]
        else
          [x, y] = [@size - 1 - y,             x]
        block.setCoordinates x, y, z


  getPath: ->
    if @needsRedraw or not @path?
      @path = Path.forMap @
    else
      @path
    @emit 'didChange' unless silent
