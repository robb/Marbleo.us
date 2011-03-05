module 'Map'

test 'Map creation', ->
  map = new Map 7
  ok map?

test 'Illegal map size', ->
  raises ->
    map = new Map 0

test 'Access block outside bounds', ->
  map = new Map 7
  raises ->
    map.getBlock(9,9,9)

test 'Stack operation: heightAt', ->
  map = new Map 7
  map.setBlock Block.ofType('blank'), 0, 0, 0
  map.setBlock Block.ofType('blank'), 0, 0, 1
  map.rotateCW()

  equal 2, map.heightAt 0, 6

test 'Stack operation: getStack', ->
  map = new Map 7

  block1 = Block.ofType 'blank'
  block2 = Block.ofType 'double-straight', 90
  block3 = Block.ofType 'curve-straight'

  map.setBlock block1, 3, 4, 0
  map.setBlock block2, 3, 4, 1
  map.setBlock block3, 3, 4, 2

  equal 3, map.heightAt(3, 4)
  deepEqual [block1, block2, block3], map.getStack(3, 4)

test 'Stack operation: setStack', ->
  mapA = new Map 7
  mapB = new Map 7

  mapA.setBlock Block.ofType('blank'),    6, 6, 0
  mapA.setBlock Block.ofType('blank'),    6, 6, 1
  mapA.setBlock Block.ofType('crossing-straight'), 6, 6, 2

  mapB.setStack [Block.ofType('blank'),
                 Block.ofType('blank'),
                 Block.ofType('crossing-straight')], 6, 6
  deepEqual mapA, mapB

test 'Stack operation: removeStack', ->
  mapA     = new Map 7
  mapB     = new Map 7
  emptyMap = new Map 7

  mapA.setBlock Block.ofType('curve-straight'), 2, 2, 0
  mapA.setBlock Block.ofType('blank')         , 2, 2, 1
  mapA.setBlock Block.ofType('blank')         , 2, 2, 2
  mapA.setBlock Block.ofType('blank')         , 2, 2, 3
  mapA.setBlock Block.ofType('blank')         , 2, 2, 4
  mapA.setBlock Block.ofType('blank')         , 2, 2, 5
  mapA.setBlock Block.ofType('blank')         , 2, 2, 6

  mapB.setBlock Block.ofType('curve-straight'), 2, 2, 0
  mapB.setBlock Block.ofType('blank')         , 2, 2, 1
  mapB.setBlock Block.ofType('blank')         , 2, 2, 2
  mapB.setBlock Block.ofType('blank')         , 2, 2, 3
  mapB.setBlock Block.ofType('blank')         , 2, 2, 4
  mapB.setBlock Block.ofType('blank')         , 2, 2, 5
  mapB.setBlock Block.ofType('blank')         , 2, 2, 6

  blocks = mapA.removeStack 2, 2
  deepEqual emptyMap, mapA, "map should be empty"

  mapA.setStack blocks, 2, 2
  deepEqual mapB, mapA, "original map should be restored"

test 'Block coordinates comply with map coordinates', ->
  size = 5
  map = new Map size

  map.setBlock Block.ofType('blank'), 0, 0, 0
  map.setBlock Block.ofType('blank'), 0, 0, 1
  map.setBlock Block.ofType('blank'), 0, 0, 2

  for x in [0...size]
    for y in [0...size]
      for z in [0...size]
        continue unless block = map.getBlock x, y, z
        deepEqual [x, y, z], block.getCoordinates()

  map.rotateCW()

  for x in [0...size]
    for y in [0...size]
      for z in [0...size]
        continue unless block = map.getBlock x, y, z
        deepEqual [x, y, z], block.getCoordinates()
