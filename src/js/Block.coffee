class Block
  @canStack: (bottom, top) ->
    [midType, midRotation] = top.getProperty 'middle'
    [topType, topRotation] = bottom.getProperty 'top'

    if topType
      # Drops can only be placed on blocks without a groov on the top
      if midType is 'drop-middle' or midType is 'drop-low'
        return no
      if midType is 'dive' or midType is 'exchange'
        return no

    return yes

  @ofType: (type, rotation = 0) ->
    throw new Error "Unknown type #{type}" unless Block.Types[type]
    return new Block Block.Types[type], rotation

  constructor: (description) ->
    @properties =
      'top':    [null, 0],
      'middle': [null, 0],
      'low':    [null, 0]

    for key, value of @properties
      @properties[key] = description[key] || value

    @validate()

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

    if lowType and midType in ['drop-middle', 'drop-low']
      throw new Error "Middle type #{midType} is incompatible with low type #{lowType}"

  setOpacity: (opacity) ->
    throw new Error "Illegal value for opacity" unless 0 <= opacity <= 1.0
    @opacity = opacity

  setSelected: (@selected) ->
  setDragged: (@dragged) ->

  getProperty: (property) ->
    unless property in ['top', 'middle', 'low']
      throw new Error "Unknown property #{property}"

    return @properties[property] # [type, rotation]

  setProperty: (property, type, rotation) ->
    [oldType, oldRotation] = @getProperty property

    newProperties = {}

    if rotation is null then rotation = oldRotation

    newProperties[property] = [type, rotation]
    @setProperties newProperties

  setProperties: (properties) ->
    newProperties = {}
    for key, value of @properties
      newProperties[key] = properties[key] || value

    # Check if new properties are acutally valid
    @validate newProperties

    for key, value of @properties
      @properties[key] = properties[key] || value

  rotateCW:  -> @rotate  true
  rotateCCW: -> @rotate false
  rotate: (clockwise) ->
    [topType, topRotation] = @properties['top']
    [midType, midRotation] = @properties['middle']
    [lowType, lowRotation] = @properties['low']

    if clockwise
      @setProperties {
        'top':    [topType, (topRotation +  90) % 360],
        'middle': [midType, (midRotation +  90) % 360],
        'low':    [lowType, (lowRotation +  90) % 360]
      }
    else
      # -90 % 360 in JavaScript returns -90, hence we go the other way ’round
      @setProperties {
        'top':    [topType, (topRotation + 270) % 360],
        'middle': [midType, (midRotation + 270) % 360],
        'low':    [lowType, (lowRotation + 270) % 360]
      }

  toString: ->
    [topType, topRotation] = @properties['top']
    [midType, midRotation] = @properties['middle']
    [lowType, lowRotation] = @properties['low']

    return "#{topType}#{topRotation}" +
           "#{midType}#{midRotation}" +
           "#{lowType}#{lowRotation}" +
           "#{@opacity}#{@selected}"


  # All the supported components a block can be composed of
  @Components:
    top:
      ['crossing',
       'crossing-hole',
       'curve',
       'straight']
    middle:
      ['crossing',
       'curve',
       'straight',
       'dive',
       'drop-middle',
       'drop-low',
       'exchange-alt',
       'exchange']
    low:
      ['crossing',
       'curve',
       'straight']

  # All the types of blocks we support
  @Types:
    'blank':
      {}
    'double-straight':
      'top':    ['straight', 90]
      'middle': ['straight', 90]
    'curve-straight':
      'top':    ['curve',     0]
      'middle': ['straight', 90]
    'curve-straight-alt':
      'top':    ['curve',    270]
      'middle': ['straight',  90]
    'curve-exchange':
      'top':    ['curve',      0]
      'middle': ['straight', 270]
    'curve-exchange-alt':
      'top':    ['curve',        270]
      'middle': ['exchange-alt',   0]
    'straight-exchange':
      'top':    ['straight', 90]
      'middle': ['exchange',  0]
    'straight-exchange-alt':
      'top':    ['straight',     90]
      'middle': ['exchange-alt',  0]
    'curve-dive':
      'top':    ['curve',  0]
      'middle': ['dive',  90]
    'curve-dive-alt':
      'top':    ['curve', 90]
      'middle': ['dive',  90]
    'crossing-straight':
      'top':    ['crossing', 0]
      'middle': ['straight', 0]
    'crossing-hole':
      'top':    ['crossing-hole',  0]
      'middle': ['drop-middle',   90]
    'crossing-hole-alt':
      'top':    ['crossing-hole',  0]
      'middle': ['drop-low',      90]
