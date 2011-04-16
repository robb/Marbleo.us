# Takes care of collision detection as well as positioning of the marble.
# This class has a better understanding of the three-dimensional world, 
# whereas the Renderer is more concerned with its 2d representation.
class Animator extends EventEmitter
  constructor: (@map, @marble) ->
    @map.addListener 'didChange', @updatePath
    @map.addListener 'didRotate', @handleRotation

    @updatePath()

  updatePath: =>
    @path = Path.forMap @map

  handleRotation: (clockwise) =>
    rotateCoordinates = (x, y, z) ->
      if clockwise
        [y, (Settings.blockSize - 1) * Settings.mapSize - x, z]
      else
        [(Settings.blockSize - 1) * Settings.mapSize - y, x, z]

    [x, y, z] = @marble.getCoordinates()
    @marble.setCoordinates rotateCoordinates(x, y, z)...

    @path = Path.forMap @map

    if @marble.isOnTrack
      newTargetNode = @path.nodeAt rotateCoordinates(@marble.targetNode.getCoordinates()...)...
      newLastNode   = @path.nodeAt rotateCoordinates(@marble.lastNode.getCoordinates()...)...

      if newTargetNode and newLastNode
        @marble.targetNode = newTargetNode
        @marble.lastNode   = newLastNode
      else
        @marble.isOnTrack  = no
        @marble.targetNode = null
        @marble.lastNode   = null
    else
      [vX, vY, vZ] = @marble.getVelocities()
      if clockwise
        @marble.setVelocities vY, -vX, vZ
      else
        @marble.setVelocities -vY, vX, vZ

  blockAtWorldCoordinates: (x, y, z) ->
    bX = Math.floor(x / Settings.blockSize)
    bY = Math.floor(y / Settings.blockSize)
    bZ = Math.floor(z / Settings.blockSize)

    if 0 <= bX < @map.size and
       0 <= bY < @map.size and
       0 <= bZ < @map.size
      @map.getBlock(bX, bY, bZ)
    else
      null

  applyFriction: (velocity) ->
    if ROUGHLY(velocity, 0, 0.09)
      0
    else
      velocity * Settings.friction

  animate: ->
    [mX, mY, mZ] = @marble.getCoordinates()
    [vX, vY, vZ] = @marble.getVelocities()
    r            = @marble.radius

    [old_mX, old_mY, old_mZ] = [mX, mY, mZ]

    trackTest = (x3, y3, z3, nodeA, nodeB) ->
      [x2, y2, z2] = nodeA.getCoordinates()
      [x1, y1, z1] = nodeB.getCoordinates()

      slope = (x1, x2, y1, y2) ->
        (y1 - y2) / (x1 - x2) or 0 # if NaN

      isInfinite = (x) ->
        not isFinite(x)

      slopeXY = slope(x1, x2, y1, y2)
      linearEquationXY = (marbleX) ->
        slopeXY * marbleX + y1 - slopeXY * x1

      slopeXZ = slope(x1, x2, z1, z2)
      linearEquationXZ = (marbleX) ->
        slopeXZ * marbleX + z1 - slopeXZ * x1

      slopeYZ = slope(y1, y2, z1, z2)
      linearEquationYZ = (marbleY) ->
        slopeYZ * marbleY + z1 - slopeYZ * y1

      xy = if isInfinite(slopeXY) then ROUGHLY(x1, x3, 3) else ROUGHLY(y3, linearEquationXY(x3), 4)

      xz = if isInfinite(slopeXZ) then ROUGHLY(x1, x3, 3) else ROUGHLY(z3, linearEquationXZ(x3), 3)

      yz = if isInfinite(slopeYZ) then ROUGHLY(y1, y3, 6) else ROUGHLY(z3, linearEquationYZ(y3), 6)

      if xy and xz and yz
        x = if isInfinite(slopeXY) then x1 else x3
        y = if isInfinite(slopeXY) then y3 else linearEquationXY(x)
        z = if isInfinite(slopeXZ) then z3 else linearEquationXZ(x)

        if Math.min(x1, x2) - 3 <= x <= Math.max(x1, x2) + 3 and
           Math.min(y1, y2) - 3 <= y <= Math.max(y1, y2) + 3 and
           Math.min(z1, z2) - 8 <= z <= Math.max(z1, z2) + 2
          [x, y, z]
        else
          null
      else
        null

    # Detect if marble is on tracks
    unless @marble.isOnTrack
      # Get the block under the marble, if any
      block = @blockAtWorldCoordinates(mX, mY, mZ - r - 1)
      if block? and (vZ <= 0 or block isnt @marble.currentBlock and vZ >= 0)
        do =>
          for node in Path.nodesForBlock block
            for neighbour in node.getNeighbours()
              if hitNode = trackTest(mX, mY, mZ - r - 1, node, neighbour)
                [mX, mY, mZ] = hitNode
                [pX, pY, pZ] = node.getCoordinates()
                [nX, nY, nZ] = neighbour.getCoordinates()

                # If the direction of the path is not aligned with the current
                # velocities, swap nodes to avoid making a U-turn.
                if SIGNUM(pX - nX) isnt 0 and SIGNUM(pX - nX) is SIGNUM(vX) or
                   SIGNUM(pY - nY) isnt 0 and SIGNUM(pY - nY) is SIGNUM(vY) or
                   SIGNUM(pZ - nZ) isnt 0 and SIGNUM(pZ - nZ) is SIGNUM(vZ)
                  [node, neighbour] = [neighbour, node]

                # We don’t want the marble to lose speed when diving into
                # a crossing-hole.
                [topType, topRotation] = block.getProperty 'top'
                unless topType is 'crossing-hole'
                  vX = vX * SIGNUM(pX - nX)
                  vY = vY * SIGNUM(pY - nY)
                  vZ = vZ * SIGNUM(pZ - nZ)

                @marble.setTrackSpeed VECTOR_LENGTH(vX, vY, vZ)

                @marble.currentBlock = block

                console.log "Targeting node at ", [nX, nY, nZ], "from ", [pX, pY, pZ]

                @marble.targetNode = @path.nodeAt neighbour.getCoordinates()...
                @marble.lastNode   = @path.nodeAt node.getCoordinates()...

                @marble.isOnTrack = yes
                return
          @marble.isOnTrack = no

    # # Movement on track
    if @marble.isOnTrack

      @marble.currentBlock = @blockAtWorldCoordinates(mX, mY, mZ) or
                             @marble.currentBlock

      [tX, tY, tZ] = @marble.targetNode.getCoordinates()
      [lX, lY, lZ] = @marble.lastNode.getCoordinates()
      dX = tX - mX
      dY = tY - mY
      dZ = tZ - mZ

      distance = VECTOR_LENGTH(dX, dY, dZ)

      # Check if the marble would collide with the next block
      if distance < @marble.radius and
         @marble.targetNode.getNeighbours().length is 1 and
         @marble.targetNode.getNeighbours()[0] is @marble.lastNode
        [bX, bY, bZ] = @marble.currentBlock.getCoordinates()

        nextBlock = @map.getBlock bX + SIGNUM(tX - lX),
                                  bY + SIGNUM(tY - lY),
                                  bZ + SIGNUM(tZ - lZ)

        if nextBlock
          console.log nextBlock

          [@marble.targetNode, @marble.lastNode] = [@marble.lastNode, @marble.targetNode]
          @marble.setTrackSpeed @marble.getTrackSpeed() * Settings.blockDampening
          [tX, tY, tZ] = @marble.targetNode.getCoordinates()
          [lX, lY, lZ] = @marble.lastNode.getCoordinates()
          dX = tX - mX
          dY = tY - mY
          dZ = tZ - mZ

          distance = VECTOR_LENGTH(dX, dY, dZ)

      # Apply graviation based on slope
      dXY   = Math.sqrt dX * dX + dY * dY
      slope = unless (isNaN(dZ / dXY)) then (dZ / dXY) else Infinity
      a     = Math.atan(slope) / (Math.PI / 2)

      oldSpeed = @marble.getTrackSpeed()

      @marble.setTrackSpeed @marble.getTrackSpeed() - Settings.gravity * a
      @marble.setTrackSpeed @applyFriction(@marble.getTrackSpeed())

      newSpeed = @marble.getTrackSpeed()

      # Flip target and last node if the marble changed direction due to
      # gravitational pull.
      if (tZ > mZ > lZ) and SIGNUM(dZ / newSpeed) is -1 or
         (tZ < mZ < lZ) and SIGNUM(dZ / newSpeed) is  1
        [@marble.targetNode, @marble.lastNode] = [@marble.lastNode, @marble.targetNode]
        [tX, tY, tZ] = @marble.targetNode.getCoordinates()
        [lX, lY, lZ] = @marble.lastNode.getCoordinates()
        dX = tX - mX
        dY = tY - mY
        dZ = tZ - mZ

      # Lock the marble in position if mZ underflow.
      #
      # This works but it’s probably very imprecise.
      else if mZ < tZ and SIGNUM(dZ / newSpeed) is -1
        @marble.setTrackSpeed 0
        mZ = lZ

      if distance > @marble.getTrackSpeed()
        s = distance / @marble.getTrackSpeed()

        mX += dX / s
        mY += dY / s
        mZ += dZ / s

      else
        [mX, mY, mZ] = [tX, tY, tZ]

        # find next target node
        for neighbour in @marble.targetNode.getNeighbours()
          console.log "Trying #{neighbour}"
          unless neighbour is @marble.lastNode
            next = neighbour

        if next
          console.log "next found"
          @marble.lastNode   = @marble.targetNode
          @marble.targetNode = next
        else
          console.log "No next block found, last was at #{mX}:#{mY}:#{mZ}"

          # construct new velocity vector based on last two nodes
          dX = tX - lX
          dY = tY - lY
          dZ = tZ - lZ

          s = VECTOR_LENGTH(dX, dY, dZ) / @marble.getTrackSpeed()

          new_vX = dX / s
          new_vY = dY / s
          new_vZ = dZ / s

          @marble.isOnTrack = no

          [vX, vY, vZ] = [new_vX, new_vY, new_vZ]

          @marble.targetNode = null
          @marble.lastNode   = null

    # # Normal physic
    unless @marble.isOnTrack
      mX += vX
      mY += vY
      mZ += vZ

      vZ -= Settings.gravity

      # Do a hit test with every block.
      @map.blocksEach (block) =>
        # If the marble falls off the track, it would immediately collide with
        # the block it just left. Therefore, we don’t consider this block for
        # hit testing until we hit with another block or the ground.
        return if block is @marble.currentBlock

        [bX, bY, bZ] = block.getCoordinates()

        if @marble.currentBlock
          [cX, cY, cZ] = @marble.currentBlock.getCoordinates()

          if bX is cX and
             bY is cY and
             bZ is cZ + 1
            return

        # Check if the marble and the block potentially hit by comparing their
        # coordinates. If two of these match, the marble and the block are aligned
        # on one axis.
        xMatch = mX >= bX * Settings.blockSize and
                 mX <  (bX + 1) * Settings.blockSize
        yMatch = mY >= bY * Settings.blockSize and
                 mY <  (bY + 1) * Settings.blockSize
        zMatch = mZ >= bZ * Settings.blockSize and
                 mZ <  (bZ + 1) * Settings.blockSize

        # Hit test with block in z direction.
        # First check if the x and y coordinates match, i.e. if the marble
        # is vertically aligned with the block.
        # Then check if the marble is below the blocks top.
        # If it is, push the marble out of the block and let it bounce off.
        if xMatch and yMatch
          if mZ - r < (bZ + 1) * Settings.blockSize
            mZ = Math.round(mZ / Settings.blockSize) * Settings.blockSize + r

            vZ = -vZ * Settings.blockDampening
            vZ = 0 if Math.abs(vZ) < 0.5

            hit = yes

        # Hit test with block in y direction
        # First check if the x and z coordinates match, i.e. if the marble and
        # the block are aligned on the y axis.
        if xMatch and zMatch
          blockLowY  = bY * Settings.blockSize
          blockMidY  = bY * Settings.blockSize + Settings.blockSize / 2
          blockHighY = (bY + 1) * Settings.blockSize

          # Check if the block and the marble overlap. Determine in which half
          # of the block the marble lies and push it out accordingly.
          if mY + r > blockLowY and mY - r < blockHighY
            vY = -vY * Settings.blockDampening
            if mY <= blockMidY
              mY = Math.round(mY / Settings.blockSize) * Settings.blockSize - r
            else
              mY = Math.round(mY / Settings.blockSize) * Settings.blockSize + r

            hit = yes

        # Hit test with block in x direction
        # First check if the y and z coordinates match, i.e. if the marble and
        # the block are aligned on the x axis.
        if yMatch and zMatch
          blockLowX  = bX * Settings.blockSize
          blockMidX  = bX * Settings.blockSize + Settings.blockSize / 2
          blockHighX = (bX + 1) * Settings.blockSize

          # Check if the block and the marble overlap. Determine in which half
          # of the block the marble lies and push it out accordingly.
          if mX + r > blockLowX and mX - r < blockHighX
            vX = -vX * Settings.blockDampening
            if mX <= blockMidX
              mX = Math.round(mX / Settings.blockSize) * Settings.blockSize - r
            else
              mX = Math.round(mX / Settings.blockSize) * Settings.blockSize + r

            hit = yes

        @marble.currentBlock = null if hit

      # Hit test with ground
      if mZ - @marble.radius < 0
        mZ = @marble.radius
        vZ = -vZ * 0.3
        vZ = 0 if Math.abs(vZ) < 0.5

        @marble.currentBlock = null

      if mZ is old_mZ
        vX = @applyFriction vX
        vY = @applyFriction vY

    @marble.setCoordinates mX, mY, mZ
    @marble.setVelocities  vX, vY, vZ

    if old_mZ isnt mZ or old_mY isnt mY or old_mX isnt mX
      @emit 'marble:moved'
