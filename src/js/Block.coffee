class Block
  constructor: (type, rotation) ->
    type ||= 'blank'

    @properties = {}
    for key, value of Block.Types[type]
      @properties[key] = value

    switch rotation
      when 90
        @rotateCW()
      when 180
        @rotateCW()
        @rotateCW()
      when 270
        @rotateCCW()

  setOpacity: (opacity) ->
    throw new Error "Illegal value for opacity" unless 0 <= opacity <= 1.0
    @opacity = opacity

  setIsSelected: (@isSelected) ->

  rotateCW:  -> @rotate  true
  rotateCCW: -> @rotate false
  rotate: (clockwise) ->
    if clockwise
      @properties.topRotation    = (@properties.topRotation    + 90) % 360
      @properties.middleRotation = (@properties.middleRotation + 90) % 360
    else
      # -90 % 360 in JavaScript returns -90, hence we go the other way ’round
      @properties.topRotation    = (@properties.topRotation    + 270) % 360
      @properties.middleRotation = (@properties.middleRotation + 270) % 360

  toString: ->
    return "#{@properties.top}#{@properties.topRotation}
            #{@properties.middle}#{@properties.middleRotation}
            #{@properties.low}#{@properties.lowRotation}
            #{@opacity}#{@isSelected}"

  # All the types of blocks we support
  @Types:
    'blank':
      {}
    'double-straight':
      top:            'straight'
      topRotation:            90
      middle:         'straight'
      middleRotation:         90
    'curve-straight':
      top:               'curve'
      topRotation:             0
      middle:         'straight'
      middleRotation:         90
    'curve-straight-alt':
      top:               'curve'
      topRotation:           270
      middle:         'straight'
      middleRotation:         90
    'curve-exchange':
      top:               'curve'
      topRotation:             0
      middle:         'straight'
      middleRotation:        270
    'curve-exchange-alt':
      top:               'curve'
      topRotation:           270
      middle:     'exchange-alt'
      middleRotation:          0
    'straight-exchange':
      top:            'straight'
      topRotation:            90
      middle:         'exchange'
      middleRotation:          0
    'straight-exchange-alt':
      top:            'straight'
      topRotation:            90
      middle:     'exchange-alt'
      middleRotation:          0
    'curve-dive':
      top:               'curve'
      topRotation:             0
      middle:             'dive'
      middleRotation:         90
    'curve-dive-alt':
      top:               'curve'
      topRotation:            90
      middle:             'dive'
      middleRotation:         90
    'crossing-straight':
      top:            'crossing'
      topRotation:             0
      middle:         'straight'
      middleRotation:          0
    'crossing-hole':
      top:       'crossing-hole'
      topRotation:             0
      middle:       'drop-middle'
      middleRotation:         90
    'crossing-hole':
      top:       'crossing-hole'
      topRotation:             0
      middle:         'drop-low'
      middleRotation:         90
