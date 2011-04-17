# This class manages the marble.
class Marble
  # Creates a new marble
  constructor: (@radius = 7) ->
    [@x, @y, @z]             = [-5000, -5000, 0] # XXX: Hide marble outside of map
    [@x_V, @y_V, @z_V]       = [0, 0, 0]

  setCoordinates: (x, y, z) ->
    throw new Error "Missing parameter" unless (x? and y? and z?)

    [@x, @y, @z] = [x, y, z]

  getCoordinates: -> [@x, @y, @z]

  setVelocities: (x_V, y_V, z_V) ->
    throw new Error "Missing parameter" unless x_V? and y_V? and z_V?

    [@x_V, @y_V, @z_V] = [x_V, y_V, z_V]

  getVelocities: -> [@x_V, @y_V, @z_V]

  setTrackSpeed: (trackSpeed) ->
    throw new Error "Missing parameter" unless trackSpeed?
    throw new Error "Must not be NaN"   if isNaN(trackSpeed)

    @trackSpeed = trackSpeed

  getTrackSpeed: -> @trackSpeed

  # Sets the needs redraw state of the block.
  setNeedsRedraw: (@needsRedraw) ->
