# Models the path a marble can take a directed graph
# where each node’s maximum degree is two.
class Path
  @nodesForBlock: (block) ->
    [bX, bY, bZ]           = block.getCoordinates()
    [topType, topRotation] = block.getProperty 'top'
    [midType, midRotation] = block.getProperty 'middle'

    rotateNodeCoordinates = (rotation, x, y, z) ->
      switch rotation
        when  90 then return [                     y, Settings.blockSize - x, z]
        when 180 then return [Settings.blockSize - x, Settings.blockSize - y, z]
        when 270 then return [Settings.blockSize - y,                      x, z]
        else
          return [x, y, z]

    # Create path nodes from the description
    nodesForDescription = (description, rotation) ->
      currentNodes = {}
      for nodeID, [x, y, z, neighbours...] of description
        x *= Settings.blockSize
        y *= Settings.blockSize
        z *= Settings.blockSize

        [x, y, z] = rotateNodeCoordinates rotation, x, y, z

        x += Settings.blockSize * bX
        y += Settings.blockSize * bY
        z += Settings.blockSize * bZ

        currentNodes[nodeID] = new PathNode x, y, z

      # Connect path nodes based on description
      for nodeID, [x, y, z, neighbours...] of description
        node = currentNodes[nodeID]

        for neighbourID in neighbours
          node.addNeighbour currentNodes[neighbourID]

      node for nodeID, node of currentNodes

    topNodes = nodesForDescription Path.Descriptors.top[topType], topRotation
    midNodes = nodesForDescription Path.Descriptors.middle[midType], midRotation

    [topNodes..., midNodes...]

  @nodesForMap: (map) ->
    nodes = []
    map.blocksEach (block) =>
      for node in Path.nodesForBlock block
        nodes.push node

    nodes

  @forBlock: (block) ->
    new Path @nodesForBlock(block)...

  @forMap: (map) ->
    new Path @nodesForMap(map)...

  constructor: (nodes...) ->
    @nodes     = {}

    for node in nodes
      key = node.toString()
      if @nodes[key]?
        @nodes[key] = PathNode.byJoining @nodes[key], node
      else
        @nodes[key] = node

    @nodeArray = []
    @nodeArray.push node for coordinates, node of @nodes

  getNodes: ->
    @nodeArray

  nodeAt: (x, y, z) ->
    @nodes["#{x}:#{y}:#{z}"] or null

  rotate: (clockwise) ->
    rotatedNodes = {}

    rotateNode: (node) ->
      [x, y, z] = node.getCoordinates()
      if clockwise
        [x, y] = [Settings.mapSize * Settings.blockSize - y, x]
      else
        [x, y] = [y, Settings.mapSize * Settings.blockSize - x]
      node.setCoordinates x, y, z

    for coordinates, node of @nodes
      rotateNode node
      rotatedNodes[node.toString()] = node

    @nodes = rotatedNodes

    @nodeArray = []
    @nodeArray.push node for coordinates, node of @nodes

  class PathNode
    @byJoining: (nodeA, nodeB) ->
      unless ARRAY_EQUAL nodeA.getCoordinates(), nodeB.getCoordinates()
        throw new Error "Node must be at same position."

      if nodeA is nodeB
        throw new Error "Cannot join node with itself."

      if nodeA.getNeighbours().length is 2 or
         nodeB.getNeighbours().length is 2
        throw new Error "Resulting node would have a degree bigger than 2."

      newNode = new PathNode nodeA.getCoordinates()...

      neighbourA = nodeA.getNeighbours()[0]
      neighbourB = nodeB.getNeighbours()[0]

      newNode.addNeighbour neighbourA
      newNode.addNeighbour neighbourB

      if neighbourA?.removeNeighbour nodeA
        neighbourA.addNeighbour    newNode
      if neighbourB?.removeNeighbour nodeB
        neighbourB.addNeighbour    newNode

      newNode

    constructor: (x, y, z) ->
      @coordinates = [x, y, z]

    setCoordinates: (x, y, z) ->
      @coordinates = [x, y, z]

    getCoordinates: -> @coordinates

    addNeighbour: (node) ->
      throw new Error "Maximum degree for a node is two" if @neighbour1 and
                                                            @neighbour2

      unless @neighbour1?
        @neighbour1 = node
      else unless @neighbour2?
        @neighbour2 = node

      @getNeighbours()

    getNeighbours: ->
      if @neighbour1 and @neighbour2
        return [@neighbour1, @neighbour2]
      else if @neighbour1
        return [@neighbour1]
      else if @neighbour2
        return [@neighbour2]
      else
        return []

    removeNeighbour: (node) ->
      if @neighbour1 is node
        @neighbour1 = null
        yes
      else if @neighbour2 is node
        @neighbour2 = null
        yes
      else
        no

    toString: ->
      [x, y, z] = @coordinates
      "#{x}:#{y}:#{z}"

  # Describes the paths for a given blocksegment.
  @Descriptors =
    top:
      'straight':
        'a': [  0, 1/2,   1, 'b']
        'b': [  1, 1/2,   1, 'a']
      'crossing':
        'a': [  0, 1/2,   1, 'b']
        'b': [  1, 1/2,   1, 'a']
        'c': [1/2,   0,   1, 'd']
        'd': [1/2,   1,   1, 'c']
      'curve':
        'a': [  0, 1/2,   1, 'b']
        'b': [1/8, 4/8,   1, 'a', 'c']
        'c': [3/8, 5/8,   1, 'b', 'd']
        'd': [4/8, 7/8,   1, 'c', 'e']
        'e': [1/2,   1,   1, 'd']
    middle:
      'straight':
        'a': [  0, 1/2, 1/2, 'b']
        'b': [  1, 1/2, 1/2, 'a']
      'crossing':
        'a': [  0, 1/2, 1/2, 'b']
        'b': [  1, 1/2, 1/2, 'a']
        'c': [1/2,   0, 1/2, 'd']
        'd': [1/2,   1, 1/2, 'c']
      'curve':
        'a': [  0, 4/8, 1/2, 'b']
        'b': [1/8, 4/8, 1/2, 'a', 'c']
        'c': [3/8, 5/8, 1/2, 'b', 'd']
        'd': [4/8, 7/8, 1/2, 'c', 'e']
        'e': [4/8,   1, 1/2, 'd']
      'dive':
        'a': [  0, 1/2, 4/8, 'b']
        'b': [  1, 1/2, 1/8, 'a']
      'exchange':
        'a': [  0, 4/8, 4/8, 'a']
        'b': [1/8, 4/8, 4/8, 'a', 'c']
        'c': [3/8, 5/8, 2/8, 'b', 'd']
        'd': [4/8, 7/8, 1/8, 'c', 'e']
        'e': [4/8,   1, 1/8, 'd']
      'exchange-alt':
        'a': [  0, 4/8, 1/1, 'a']
        'b': [1/8, 4/8, 1/8, 'a', 'c']
        'c': [3/8, 5/8, 2/8, 'b', 'd']
        'd': [4/8, 7/8, 4/8, 'c', 'e']
        'e': [4/8,   1, 4/8, 'd']
      'drop-middle':
        'a': [  0, 1/2,   1, 'm']
        'b': [  1, 1/2,   1, 'm']
        'c': [1/2,   0,   1, 'm']
        'd': [1/2,   1,   1, 'm']
        'm': [1/2, 1/2,   1, 'e']
        'e': [1/2, 1/2, 6/8, 'm', 'f']
        'f': [3/8, 1/2, 5/8, 'e', 'g']
        'g': [1/8, 1/2, 4/8, 'f', 'h']
        'h': [  0, 1/2, 4/8, 'g']
      'drop-low':
        'a': [  0, 1/2,   1, 'm']
        'b': [  1, 1/2,   1, 'm']
        'c': [1/2,   0,   1, 'm']
        'd': [1/2,   1,   1, 'm']
        'm': [1/2, 1/2,   1, 'e']
        'e': [1/2, 1/2, 4/8, 'm', 'f']
        'f': [3/8, 1/2, 2/8, 'e', 'g']
        'g': [1/8, 1/2, 1/8, 'f', 'h']
        'h': [  0, 1/2, 1/8, 'g']
