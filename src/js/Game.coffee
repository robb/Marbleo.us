class Game
  @defaultSettings:
    mapSize:         7
    mainCanvasID:    '#main-canvas'
    draggedCanvasID: '#dragged-canvas'
    defaultCursor:   'auto'
    dragCursor:      $.browser.webkit && '-webkit-grab' || $.browser.mozilla && '-moz-grab' || 'auto'
    draggingCursor:  $.browser.webkit && '-webkit-grabbing' || $.browser.mozilla && '-moz-grabbing' || 'auto'
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

    @mainCanvas    = $(@settings.mainCanvasID)
    @draggedCanvas = $(@settings.draggedCanvasID)

    @renderer = new Renderer @map, =>
      @mainCanvas.bind   'mouseup',   @canvasUp
      @mainCanvas.bind 'mousemove', @canvasMove
      @mainCanvas.bind 'mousedown', @canvasDown

      $body = $('body')

      $body.bind   'mouseup',   @bodyUp
      $body.bind 'mousemove', @bodyMove
      $body.bind 'mousedown', @bodyDown

      $(document).bind 'keydown', @keyDown

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
        mouseX = event.pageX - $('#main-canvas').offset().left
        mouseY = event.pageY - $('#main-canvas').offset().top
        if @state.info.block is @renderer.resolveScreenCoordinates(mouseX, mouseY).block
          @selectBlock @state.info.block
          @state.type = 'normal'
      when 'normal'
        @selectBlock null
      else
        console.error "Illegal state", @state.type if DEBUG

    # Stop from bubbling
    return off

  canvasMove: (event) =>
    mouseX = event.pageX - $('#main-canvas').offset().left
    mouseY = event.pageY - $('#main-canvas').offset().top
    switch @state.type
      when 'down'
        # If the user moves more than @settings.draggingOffset pixels
        # from where the put the mouse down, start a drag operation
        if Math.abs(@state.downX - mouseX) > @settings.draggingOffset or
           Math.abs(@state.downY - mouseY) > @settings.draggingOffset
          @draggingMove event
      when 'dragging'
        @draggingMove event
      when 'normal'
        if (side = @renderer.sideAtScreenCoordinates(mouseX, mouseY)) and side isnt 'floor'
          $('body').css 'cursor', @settings.dragCursor
        else
          $('body').css 'cursor', @settings.defaultCursor

    # Stop from bubbling
    return off

  canvasDown: (event) =>
    switch @state.type
      when 'normal'
        mouseX = event.pageX - $('#main-canvas').offset().left
        mouseY = event.pageY - $('#main-canvas').offset().top
        info = @renderer.resolveScreenCoordinates mouseX, mouseY
        if info.block
          @state.type  = 'down'
          @state.downX = mouseX
          @state.downY = mouseY
          @state.info  = info
        else
          @state.type = 'normal'

    # Stop from bubbling
    return off

  draggingMove: (event) =>
    unless @state.type is 'dragging'
      @startDrag event

    # Removing all dragged blocks as they may be drawn elsewhere
    # FIXME: This is only necessary if the position or state of the dragged
    #        blocks actually changed
    @map.blocksEach (block, x, y, z) =>
      changed = no
      if block && block.dragged
        @map.setBlock null, x, y, z
        changed = yes
      @map.setNeedsRedraw yes if changed

    mouseX = event.pageX - $('#main-canvas').offset().left
    mouseY = event.pageY - $('#main-canvas').offset().top
    info = @renderer.resolveScreenCoordinates mouseX, mouseY

    # If the user drags the stack onto another block, draw it there
    if info.side is 'top' or info.side is 'floor'
      @hideDraggedCanvas event

      [nX, nY, nZ] = info.coordinates
      targetBlock = @map.getBlock nX, nY, nZ
      targetZ = if info.side is 'top' then 1 else 0
      for block in @state.stack
        @map.setBlock block, nX, nY, targetZ++ + nZ

      lowestBlock = @state.stack[0]
      if info.side is 'top'
        # Set the low type and rotation to whatever the target block has on top
        lowestBlock.properties.low = if targetBlock.properties.top is 'crossing-hole'
                                       'crossing'
                                     else
                                       targetBlock.properties.top
        lowestBlock.properties.lowRotation = targetBlock.properties.topRotation
      else
        # Set the low type of the to nothing
        lowestBlock.properties.low = null
        lowestBlock.properties.lowRotation = null

      @map.setNeedsRedraw yes

    # otherwise, display the dragged canvas and move it to the mouse position
    else
      @showDraggedCanvas event

  startDrag: (event) ->
    $('body').css 'cursor', @settings.draggingCursor

    @selectBlock null

    @state.stack = new Array
    [bX, bY, bZ] = @state.info.coordinates
    for i in [bZ..@map.size]
      break unless block = @map.popBlock(bX, bY, i)
      block.setDragged yes
      @state.stack.push block

    @renderer.drawDraggedBlocks @state.stack

    [canvasX, canvasY] = @renderer.renderingCoordinatesForBlock bX, bY, i
    @state.mouseOffsetY = @state.downY - canvasY - @renderer.settings.blockSizeHalf
    @state.mouseOffsetX = @state.downX - canvasX

    @state.type = 'dragging'
    @renderer.drawMap yes # Redraw the map to update the hitmap

  hideDraggedCanvas: (event) ->
    @draggedCanvas.css  'display', 'none'

  showDraggedCanvas: (event) ->
    style =
      'display': 'block'
      'position': 'absolute'
      'top':  event.pageY - @state.mouseOffsetY
      'left': event.pageX - @state.mouseOffsetX
    @draggedCanvas.css style

  draggingUp: (event) =>
    @state.stack = null
    @map.blocksEach (block, x, y, z) =>
      if block && block.dragged
        block.setDragged no
    @map.setNeedsRedraw yes

    # TODO: Take action based on position
    @state.type = 'normal'
    $('body').css 'cursor', @settings.defaultCursor

    @hideDraggedCanvas event

    # Render the map again to make sure the hitmap is up to date
    @renderer.drawMap()

  keyDown: (event) =>
    switch event.keyCode
      when 65 # a
        @map.rotateCW()
      when 68 # d
        @map.rotateCCW()
