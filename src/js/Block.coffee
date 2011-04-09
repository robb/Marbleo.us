# This class models a block.
# A block in the context of marbleo.us consists of 3 layers: `top`, `middle`
# and `low`.
# Each layer consists of a layer and a rotation that describe it, all three
# layers together describe the block.
#
class Block extends EventEmitter
  # Determines wether a given block can be stacked on top of another one.
  @canStack: (bottom, top) ->
    [midType, midRotation] = top.getProperty 'middle'
    [topType, topRotation] = bottom.getProperty 'top'

    if topType
      if midType is 'drop-low'
        return no
      if midType is 'dive' or
         midType is 'exchange' or
         midType is 'exchange-alt'
        return no

    return yes

  # Given a type and an optional rotation, returns a block matching that
  # description.
  # See Block.Types for a list of all blocks supported by this method.
  @ofType: (type, rotation = 0) ->
    throw new Error "Unknown type #{type}" unless Block.Types[type]
    return new Block Block.Types[type], rotation

  # Creates a block given a description.
  #
  # Description is an object of the following layout:
  #
  #     properties =
  #       'top':    [topType, topRotation]
  #       'middle': [topType, topRotation]
  #       'low':    [topType, topRotation]
  #
  # Unspecified properties default to `[null, 0]`.
  #
  constructor: (description) ->
    @properties =
      'top':    [null, 0],
      'middle': [null, 0],
      'low':    [null, 0]

    for key, value of @properties
      @properties[key] = description[key] || value

    @validate()
    @setMaxListeners 1

  # Validates the internal consistency of a block, as layers of certain types
  # may not be combined in one block, e.g. a block that has a `top` type of
  # `crossing-hole` cannot have a layer type that is not `drop-low` or
  # `drop-middle`
  #
  validate: (properties = @properties) ->
    for level, [type, rotation] of @properties
      if type and not (type in Block.Components[level])
        throw new Error "Unknown #{level} type #{type}"
      unless rotation in [0, 90, 180, 270]
        throw new Error "Rotation must be multiple of 90, was #{type}"

    [topType, topRotation] = @getProperty 'top'
    [midType, midRotation] = @getProperty 'middle'
    [lowType, lowRotation] = @getProperty 'low'

    if topType is   'crossing-hole' and
       midType isnt 'drop-middle'   and
       midType isnt 'drop-low'
      throw new Error "Top type crossing with hole requires middle type drop, was #{midType}"

    if topType isnt 'crossing-hole' and
       midType in   ['drop-middle', 'drop-low']
      throw new Error "Middle type drop requires top type crossing with hole, was #{topType}"

    if lowType and midType is 'drop-low'
      throw new Error "Middle type #{midType} is incompatible with low type #{lowType}"

  # Sets the rendering opactiy of the block.
  setOpacity: (opacity, silent = no) ->
    throw new Error "Illegal value for opacity" unless 0 <= opacity <= 1.0
    @opacity = opacity

    @emit 'change' unless silent

  # Sets the selected state of the block.
  setSelected: (@selected, silent = no) ->
    @emit 'change' unless silent

  # Sets the dragged state of the block.
  setDragged: (@dragged) ->

  # Returns a size-two-array (i.e. a tuple) that contains the type and rotation
  # of a given layer.
  getProperty: (property) ->
    unless property in ['top', 'middle', 'low']
      throw new Error "Unknown property #{property}"

    return @properties[property] # [type, rotation]

  # Sets a property to the given type and value.
  setProperty: (property, type, rotation, silent = no) ->
    [oldType, oldRotation] = @getProperty property

    newProperties = {}

    if rotation is null then rotation = oldRotation

    newProperties[property] = [type, rotation]
    @setProperties newProperties, no

    @emit 'change' unless silent

  # Sets multiple properties of the block at once.
  # See the constructor for the requirements to the properties object.
  setProperties: (properties, silent) ->
    newProperties = {}
    for key, value of @properties
      newProperties[key] = properties[key] || value

    # Check if new properties are actually valid
    @validate newProperties

    for key, value of @properties
      @properties[key] = properties[key] || value

    @emit 'change' unless silent

  # Rotates the block 90 degrees clockwise
  rotateCW:  -> @rotate  true

  # Rotates the block 90 degrees counter-clockwise
  rotateCCW: -> @rotate false

  # Rotates the block, the direction of the rotation can be specified.
  #
  # By default, the block will be rotated fully, however, additional parameters
  # may constrain the rotation to any combination of layers.
  rotate: (clockwise, top = yes, middle = yes, low = yes, silent = no) ->
    [topType, topRotation] = @properties['top']
    [midType, midRotation] = @properties['middle']
    [lowType, lowRotation] = @properties['low']

    if clockwise
      @setProperties {
        'top':    [topType, (topRotation +  90) % 360] if top
        'middle': [midType, (midRotation +  90) % 360] if middle
        'low':    [lowType, (lowRotation +  90) % 360] if low
      }
    else
      # `-90 % 360` in JavaScript returns -90, hence we go the other way ’round
      @setProperties {
        'top':    [topType, (topRotation + 270) % 360] if top
        'middle': [midType, (midRotation + 270) % 360] if middle
        'low':    [lowType, (lowRotation + 270) % 360] if low
      }

    @emit 'change' unless silent

  # Generates a string that uniquely defines the block.
  # May be used as a key for efficient caching of rendered blocks.
  toString: ->
    [topType, topRotation] = @properties['top']
    [midType, midRotation] = @properties['middle']
    [lowType, lowRotation] = @properties['low']

    return "#{topType}#{topRotation}" +
           "#{midType}#{midRotation}" +
           "#{lowType}#{lowRotation}" +
           "#{@opacity}#{@selected}"


  # All the supported components a block can be composed of, per layer.
  @Components:
    'top':
      ['crossing',
       'crossing-hole',
       'curve',
       'straight']
    'middle':
      ['crossing',
       'curve',
       'straight',
       'dive',
       'drop-middle',
       'drop-low',
       'exchange-alt',
       'exchange']
    'low':
      ['crossing',
       'curve',
       'straight']

  # All the types of blocks we support
  @Types:
    'blank':
      {}
    'double-straight':
      'top':    ['straight', 0]
      'middle': ['straight', 0]
    'curve-straight':
      'top':    ['curve',    270]
      'middle': ['straight',   0]
    'curve-straight-alt':
      'top':    ['curve',    180]
      'middle': ['straight',   0]
    'double-curve':
      'top':    ['curve', 270]
      'middle': ['curve',   0]
    'double-curve-alt':
      'top':    ['curve', 90]
      'middle': ['curve',  0]
    'curve-exchange':
      'top':    ['curve',    270]
      'middle': ['exchange',   0]
    'curve-exchange-alt':
      'top':    ['curve',        180]
      'middle': ['exchange-alt',   0]
    'straight-exchange':
      'top':    ['straight',  0]
      'middle': ['exchange',  0]
    'straight-exchange-alt':
      'top':    ['straight',       0]
      'middle': ['exchange-alt',   0]
    'curve-dive':
      'top':    ['curve', 270]
      'middle': ['dive',    0]
    'curve-dive-alt':
      'top':    ['curve', 0]
      'middle': ['dive',  0]
    'crossing-straight':
      'top':    ['crossing', 270]
      'middle': ['straight',   0]
    'crossing-hole':
      'top':    ['crossing-hole', 270]
      'middle': ['drop-middle',     0]
    'crossing-hole-alt':
      'top':    ['crossing-hole', 270]
      'middle': ['drop-low',        0]
