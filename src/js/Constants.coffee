# TODO: Have these injected by the Cakefile instead using this file

###* @const ###
# Please make sure that this is set to off when compiling for production
DEBUG       = off
OVERLAY     = off
POINT_DEBUG = on

MAP_SIZE     =   7
TEXTURE_SIZE = 101

Settings =
  mapSize:            MAP_SIZE
  mainCanvasID:       '#main-canvas'
  draggedCanvasID:    '#dragged-canvas'
  selectorID:         '#selector'
  paletteID:          '#palette'
  defaultCursor:      'auto'
  dragCursor:         $.browser.webkit  and '-webkit-grab' or
                      $.browser.mozilla and    '-moz-grab' or
                      'auto'
  draggingCursor:     $.browser.webkit  and '-webkit-grabbing' or
                      $.browser.mozilla and    '-moz-grabbing' or
                      'auto'
  draggingOffset:     10 # Consider modifying for touch devices.
  textureSize:        TEXTURE_SIZE
  textureSizeHalf:    Math.floor(TEXTURE_SIZE / 2)
  textureSizeQuarter: Math.floor(Math.floor(TEXTURE_SIZE / 2) / 2)
  canvasHeight:       MAP_SIZE * TEXTURE_SIZE
  canvasWidth:        MAP_SIZE * TEXTURE_SIZE
  textureFile:        'img/textures.png'
  gravity:            0.7
  blockDampening:     0.3
  groundDampening:    0.3
  friction:           0.995
  blockSize:          51

# # Global helper methods
# I wish CoffeeScript would support macros.

ROUGHLY = (x, y, offset) ->
  Math.abs(x - y) < offset

ARRAY_EQUAL = (a, b) ->
  return no if a.length isnt b.length

  for i of a
    if a[i] isnt b[i]
      return no

  yes

VECTOR_LENGTH = (a, b, c) ->
  Math.sqrt a * a + b * b + c * c

SIGNUM = (x) ->
  if x < 0
    -1
  else if x > 0
    1
  else
    0

