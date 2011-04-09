# A class with the ability to fire listeners based on arbitrary events.
#
# Based of the node.js class of the same name which can be found at
# https://github.com/joyent/node/blob/bfa9db9dd6a13af475f256bb1d95118ac38f8590/lib/events.js

# Helper method
isArray = Array.isArray or (o) ->
            Object.prototype.toString.call(o) is '[object Array]'

defaultMaxListeners = 10
class EventEmitter
  setMaxListeners: (n) ->
    @events = {} unless @events
    @events.maxListeners = n

  getMaxListeners: ->
    @events = {} unless @events
    @events.maxListeners

  emit: (type, parameters...) ->
    if type is 'error'
      if !@events or !@events.error or
         isArray(@events.error) and !@events.error.length
        if parameters[0] instanceof Error
          throw new parameters[0]
        else
          throw new Error "Uncaught, unspecified 'error' event."
      return false

    handler = @events?[type]
    return false unless handler

    if typeof handler is 'function'
      switch arguments.length
        when 1
          handler.call @
        when 2
          handler.call @, parameters[0]
        when 3
          handler.call @, parameters[0], parameters[1]
        else
          handler.apply @, parameters

      true

    else if isArray(handler)
      listener.apply @, parameters for listener in handler.slice()

      true

    else
      false

  addListener: (type, listener) ->
    unless typeof listener is 'function'
      throw "addListener only takes instances of Function"

    @events = {} unless @events

    # To avoid recursion in the case that `type is "newListeners"`, before
    # adding it to the listeners, first emit "newListeners".
    @emit 'newListener', type, listener

    unless @events[type]
      @events[type] = listener
    else if isArray @events[type]
      unless @events[type].warned
        if @events.maxListeners?
          m = @events.maxListeners
        else
          m = defaultMaxListeners
      
      if m and m > 0 and @events[type].length > m
        @events[type].warned = yes
        if DEBUG
          console.error "Possible EventEmitter memory leak detected."
          console.trace
    else
      @events[type] = [@events[type], listener]

    @

  once: (type, listener) ->
    unless typeof listener is 'function'
      throw "once only takes instances of Function"

    g = =>
      @removeListener(type, g)
      listener.apply @, arguments

    g.listener = listener
    @addListener type, g

    @

  removeListener: (type, listener) ->
    unless typeof listener is 'function'
      throw "removeListener only takes instances of Function"

    return @ unless @events?[type]

    list = @events[type]
    
    if isArray list
      position = -1
      for i in [0..list.length]
        if list[i] is listener or list[i]?.listener is listener
          position = i
          break

      return @ if position < 0
      list.splice(position, 1)
      if list.length is 0
        delete @events[type]

    else if list is listener or list?.listener is listener
      delete @events[type]

    @

  removeAllListeners: (type) ->
    if type and @events?[type]
      @events[type] = null

    @

  listeners: (type) ->
    @events = {} unless @events
    @events[type] = [] unless @events[type]
    @events[type] = [@events[type]] unless isArray @events[type]

    @events[type]
