class Game
  @defaultSettings:
    mapSize:        7
    canvasID:       '#main-canvas'
    defaultCursor:  'auto'
    dragCursor:     $.browser.webkit && '-webkit-grab' || $.browser.mozilla && '-moz-grab' || 'auto'
    draggingCursor: $.browser.webkit && '-webkit-grabbing' || $.browser.mozilla && '-moz-grabbing' || 'auto'
    # The user must move atleast this amount of pixels to trigger a drag
    # TODO: Consider increaing this value for touch-based devices
    draggingOffset: 10

  constructor: (settings, onload) ->
    @settings = {}
    for key, value of Game.defaultSettings
      @settings[key] = settings[key] || Game.defaultSettings[key]

    @map = new Map @settings.mapSize

    @state = {}
    @state.type = 'normal'

    @renderer = new Renderer @map, @settings.canvasID, =>
      $canvas = $(@settings.canvasID)

      $canvas.bind   'mouseup',   @canvasUp
      $canvas.bind 'mousemove', @canvasMove
      $canvas.bind 'mousedown', @canvasDown

      $body = $('body')

      $body.bind   'mouseup',   @bodyUp
      $body.bind 'mousemove', @bodyMove
      $body.bind 'mousedown', @bodyDown

      # Populate map
      if DEBUG
        @map.setBlock new Block('curve-straight', 90),  0, 0, 0
        @map.setBlock new Block('blank'),               0, 1, 0
        @map.setBlock new Block('blank'),               0, 1, 1
        @map.setBlock new Block('double-straight', 90), 1, 0, 0
        @map.setBlock new Block('double-straight', 90), 2, 0, 0

      renderingLoop = =>
        @renderer.drawMap()
      setInterval renderingLoop, 20

      return onload()

  selectBlock: (block) ->
    @selectedBlock.setSelected no  if @selectedBlock
    @selectedBlock = block 
    @selectedBlock.setSelected yes if @selectedBlock
    @map.setNeedsRedraw yes

  # Event Handler
  bodyDown: (event) =>
    switch @state.type
      when 'normal'
        @selectBlock null

    return off

  bodyMove: (event) =>
    switch @state.type
      when 'dragging'
        @draggingMove event
      else
        $('body').css 'cursor', @settings.defaultCursor

    return off

  bodyUp: (event) =>
    switch @state.type
      when 'dragging'
        @draggingUp event

    return off

  canvasUp: (event) =>
    switch @state.type
      when 'dragging'
        @draggingUp event
      when 'down'
        x = event.offsetX || event.layerX - $(event.target).position().left
        y = event.offsetY || event.layerY - $(event.target).position().top
        if @state.info.block is @renderer.resolveScreenCoordinates(x, y).block
          @selectBlock @state.info.block
          @state.type = 'normal'
      when 'normal'
        @selectBlock null
      else
        console.error "Illegal state", @state.type if DEBUG

    # Stop from bubbling
    return off

  canvasMove: (event) =>
    x = event.offsetX || event.layerX - $(event.target).position().left
    y = event.offsetY || event.layerY - $(event.target).position().top
    switch @state.type
      when 'down'
        # If the user moves more than @settings.draggingOffset pixels
        # from where the put the mouse down, start a drag operation
        if Math.abs(@state.downX - x) > @settings.draggingOffset or
           Math.abs(@state.downY - y) > @settings.draggingOffset
          @draggingMove event
      when 'dragging'
        @draggingMove event
      when 'normal'
        if side = @renderer.sideAtScreenCoordinates(x, y)
          $('body').css 'cursor', @settings.dragCursor
        else
          $('body').css 'cursor', @settings.defaultCursor

    # Stop from bubbling
    return off

  canvasDown: (event) =>
    switch @state.type
      when 'normal'
        x = event.offsetX || event.layerX - $(event.target).position().left
        y = event.offsetY || event.layerY - $(event.target).position().top
        info = @renderer.resolveScreenCoordinates(x, y)
        if info.block
          @state.type  = 'down'
          @state.downX = x
          @state.downY = y
          @state.info  = info
        else
          @state.type = 'normal'

    # Stop from bubbling
    return off

  draggingMove: (event) =>
    unless @state.type is 'dragging'
      # Start dragging operation
      $('body').css 'cursor', @settings.draggingCursor

      @selectBlock null

      @state.stack = new Array
      [bX, bY, bZ] = @state.info.coordinates
      for i in [bZ..@map.size]
        break unless block = @map.popBlock(bX, bY, i)
        block.setDragged yes
        @state.stack.push block

      @state.type = 'dragging'
      # Redraw the map to update the hitmap
      @renderer.drawMap yes

    # Removing all dragged blocks as they may be drawn elsewhere
    # FIXME: This is only necessary if the position or state of the dragged
    #        blocks actually changed
    @map.blocksEach (block, x, y, z) =>
      if block && block.dragged
        @map.setBlock null, x, y, z

    x = event.offsetX || event.layerX - $(event.target).position().left
    y = event.offsetY || event.layerY - $(event.target).position().top
    info = @renderer.resolveScreenCoordinates(x, y)

    # If the user drags the stack onto another block, draw it there
    if info.side is 'top'
      [nX, nY, nZ] = info.coordinates
      targetBlock = @map.getBlock nX, nY, nZ
      i = 0
      for block in @state.stack
        @map.setBlock block, nX, nY, ++i + nZ
      # Set the low type and rotation to whatever the target block has on top
      lowestBlock = @state.stack[0]
      unless targetBlock.properties.top is 'crossing-hole'
        lowestBlock.properties.low = targetBlock.properties.top
      else
        lowestBlock.properties.low = 'crossing'
      lowestBlock.properties.lowRotation = targetBlock.properties.topRotation

    # If the user drags the stack onto the floor, draw it there
    else if info.side is 'floor'
      [nX, nY, nZ] = info.coordinates
      targetBlock = @map.getBlock nX, nY, nZ
      i = 0
      for block in @state.stack
        @map.setBlock block, nX, nY, i++

      # Set the low type of the to nothing
      lowestBlock = @state.stack[0]
      lowestBlock.properties.low = null
      lowestBlock.properties.lowRotation = null

    @map.setNeedsRedraw yes

  draggingUp: (event) =>
    @state.stack = null
    @map.blocksEach (block, x, y, z) =>
      if block && block.dragged
        block.setDragged no
    @map.setNeedsRedraw yes

    # TODO: Take action based on position
    @state.type = 'normal'
    $('body').css 'cursor', @settings.defaultCursor

    # Render the map again to make sure the hitmap is up to date
    @renderer.drawMap()
