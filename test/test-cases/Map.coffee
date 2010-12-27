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
  map.setBlock new Block('blank'), 0, 0, 0
  map.setBlock new Block('blank'), 0, 0, 1
  map.rotateCW()

  equal 2, map.heightAt 0, 6

test 'Stack operation: getStack', ->
  map = new Map 7

  block1 = new Block 'blank'
  block2 = new Block 'double-straight', 90
  block3 = new Block 'curve-straight'

  map.setBlock block1, 3, 4, 0
  map.setBlock block2, 3, 4, 1
  map.setBlock block3, 3, 4, 2

  equal 3, map.heightAt(3, 4)
  deepEqual [block1, block2, block3], map.getStack(3, 4)

test 'Stack operation: setStack', ->
  mapA = new Map 7
  mapB = new Map 7

  mapA.setBlock new Block('blank'),        6, 6, 0
  mapA.setBlock new Block('blank'),        6, 6, 1
  mapA.setBlock new Block('crossing-low'), 6, 6, 2

  mapB.setStack [new Block('blank'),
                 new Block('blank'),
                 new Block('crossing-low')], 6, 6
  deepEqual mapA, mapB

test 'Stack operation: removeStack', ->
  mapA     = new Map 7
  mapB     = new Map 7
  emptyMap = new Map 7

  mapA.setBlock new Block('curve-straight'), 2, 2, 0
  mapA.setBlock new Block('blank')         , 2, 2, 1
  mapA.setBlock new Block('blank')         , 2, 2, 2
  mapA.setBlock new Block('blank')         , 2, 2, 3
  mapA.setBlock new Block('blank')         , 2, 2, 4
  mapA.setBlock new Block('blank')         , 2, 2, 5
  mapA.setBlock new Block('blank')         , 2, 2, 6

  mapB.setBlock new Block('curve-straight'), 2, 2, 0
  mapB.setBlock new Block('blank')         , 2, 2, 1
  mapB.setBlock new Block('blank')         , 2, 2, 2
  mapB.setBlock new Block('blank')         , 2, 2, 3
  mapB.setBlock new Block('blank')         , 2, 2, 4
  mapB.setBlock new Block('blank')         , 2, 2, 5
  mapB.setBlock new Block('blank')         , 2, 2, 6

  blocks = mapA.removeStack 2, 2
  deepEqual emptyMap, mapA, "map should be empty"

  mapA.setStack blocks, 2, 2
  deepEqual mapB, mapA, "original map should be restored"
