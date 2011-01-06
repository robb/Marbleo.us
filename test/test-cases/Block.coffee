module 'Block'

test 'Standart block types', ->
  for blockType of Block.Types
    ok Block.ofType(blockType), "Creating block of type #{blockType}"

test 'Unknown block types', ->
  for blockType in ['cheese', 'lego', 'concrete', 'redstone', 'water']
    raises ->
      Block.ofType blockType
    , "Creating block of type #{blockType} should throw Error"

test 'Illegal blocks', ->
  raises ->
    new Block top: ['looping', 0]
  , "Creating block with unknown components"

  raises ->
    new Block {
      'top':    ['crossing-hole',  0]
      'middle':         ['curve',  0]
    }
  , "Creating block with top type 'crossing-hole' and incompatible middle type 'curve'"

test 'Modifying Block', ->
  block = Block.ofType 'blank'
  block.setProperty 'top', 'crossing', 0

  [type, rotation] = block.getProperty 'top'

  equals 'crossing', type

test 'Rotation', ->
  block = new Block {
    'top':    ['straight',  0],
    'middle':    ['curve', 90]
  }

  block.rotateCW()
  [dontcare, topRotation] = block.getProperty 'top'
  [dontcare, midRotation] = block.getProperty 'middle'
  equals  90, topRotation
  equals 180, midRotation

  block.rotateCCW()
  [dontcare, topRotation] = block.getProperty 'top'
  [dontcare, midRotation] = block.getProperty 'middle'
  equals   0, topRotation
  equals  90, midRotation

  block.rotateCCW()
  [dontcare, topRotation] = block.getProperty 'top'
  [dontcare, midRotation] = block.getProperty 'middle'
  equals 270, topRotation
  equals   0, midRotation

  block.rotateCCW()
  [dontcare, topRotation] = block.getProperty 'top'
  [dontcare, midRotation] = block.getProperty 'middle'
  equals 180, topRotation
  equals 270, midRotation
