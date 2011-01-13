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
      @mainCanvas.bind    'mouseup',   @canvasUp
      @mainCanvas.bind  'mousemove', @canvasMove
      @mainCanvas.bind  'mousedown', @canvasDown

      @mainCanvas.bind 'touchstart', @normalizeCoordinates(@canvasTouchStart)
      @mainCanvas.bind  'touchmove', @normalizeCoordinates( @canvasTouchMove)
      @mainCanvas.bind   'touchend', @normalizeCoordinates(  @canvasTouchEnd)

      $body = $('body')

      $body.bind   'mouseup',   @bodyUp
      $body.bind 'mousemove', @bodyMove
      $body.bind 'mousedown', @bodyDown

      $(document).bind 'keydown', @keyDown

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

  canvasTouchStart: (event) =>
    unless event.originalEvent.touches.length is 1
      return

    switch @state.type
      when 'normal'
        info = @renderer.resolveScreenCoordinates event.pageX, event.pageY
        if info.block
          @state.type  = 'down'
          @state.downX = event.pageX
          @state.downY = event.pageY
          @state.info  = info
          event.originalEvent.preventDefault()
        else
          @state.type = 'normal'

  canvasTouchMove: (event) =>
    if @state.type is 'normal'
      return

    if event.originalEvent.touches.length is 1
      event.originalEvent.preventDefault()
    else
      return

    event.originalEvent.preventDefault()
    switch @state.type
      when 'down'
        # If the user moves more than @settings.draggingOffset pixels
        # from where the put the mouse down, start a drag operation
        if Math.abs(@state.downX - event.pageX) > @settings.draggingOffset or
           Math.abs(@state.downY - event.pageY) > @settings.draggingOffset
          @startDrag event
      when 'dragging'
        @draggingMove event

  canvasTouchEnd: (event) =>
    switch @state.type
      when 'dragging'
        @draggingUp event
      when 'down'
        @selectBlock @state.info.block
        @state.type = 'normal'
      when 'normal'
        @selectBlock null
      else
        console.log "Illegal state", @state.type if DEBUG

  canvasUp: (event) =>
    switch @state.type
      when 'dragging'
        @draggingUp event
      when 'down'
        mouseX = event.pageX - @mainCanvas.offset().left
        mouseY = event.pageY - @mainCanvas.offset().top
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
    mouseX = event.pageX - @mainCanvas.offset().left
    mouseY = event.pageY - @mainCanvas.offset().top
    switch @state.type
      when 'down'
        # If the user moves more than @settings.draggingOffset pixels
        # from where the put the mouse down, start a drag operation
        if Math.abs(@state.downX - mouseX) > @settings.draggingOffset or
           Math.abs(@state.downY - mouseY) > @settings.draggingOffset
          @startDrag event
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
        mouseX = event.pageX - @mainCanvas.offset().left
        mouseY = event.pageY - @mainCanvas.offset().top
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
    # Removing all dragged blocks as they may be drawn elsewhere
    # FIXME: This is only necessary if the position or state of the dragged
    #        blocks actually changed
    @map.blocksEach (block, x, y, z) =>
      changed = no
      if block && block.dragged
        changed = yes if @map.removeBlock x, y, z
      @map.setNeedsRedraw yes if changed

    mouseX = event.pageX - @mainCanvas.offset().left
    mouseY = event.pageY - @mainCanvas.offset().top
    info = @renderer.resolveScreenCoordinates mouseX, mouseY

    [x, y, z]   = info.coordinates || [0, 0, 0] #XXX
    targetBlock = @map.getBlock x, y, z
    lowestBlock = @state.stack[0]

    if info.side is 'floor' or
       info.side is 'top'   and
       @map.heightAt(x, y) + @state.stack.length < @map.size + 1 and
       Block.canStack targetBlock, lowestBlock
      @hideDraggedCanvas event

      offset = if info.side is 'top' then 1 else 0
      # for block in @state.stack
      #   @map.setBlock block, x, y, targetZ++ + z
      @map.setStack @state.stack, x, y, z + offset

      if info.side is 'top'
        # Set the low type and rotation to whatever the target block has on top
        [type, rotation] = targetBlock.getProperty 'top'

        type = (type is 'crossing-hole') && 'crossing' || type

        lowestBlock.setProperty 'low', type, rotation
      else
        # Set the low type of the to nothing
        lowestBlock.setProperty 'low', null, 0

      @map.setNeedsRedraw yes

    # otherwise, display the dragged canvas and move it to the mouse position
    else
      @showDraggedCanvas event

  startDrag: (event) ->
    $('body').css 'cursor', @settings.draggingCursor

    @selectBlock null
    [x, y, z] = @state.info.coordinates
    @state.stack = @map.removeStack x, y, z
    for block in @state.stack
      block.setDragged yes

    @renderer.drawDraggedBlocks @state.stack

    [canvasX, canvasY] = @renderer.renderingCoordinatesForBlock x, y, z + @state.stack.length
    # Using bitwise-or 0 to convert Strings to ints
    marginTop   = @mainCanvas.css(  'margin-top').replace('px','') | 0 
    marginLeft  = @mainCanvas.css( 'margin-left').replace('px','') | 0
    paddingTop  = @mainCanvas.css( 'padding-top').replace('px','') | 0
    paddingLeft = @mainCanvas.css('padding-left').replace('px','') | 0
    @state.mouseOffsetY = @state.downY - canvasY + paddingTop  + marginTop - @renderer.settings.blockSizeHalf
    @state.mouseOffsetX = @state.downX - canvasX + paddingLeft + marginLeft

    @state.type = 'dragging'
    @renderer.drawMap yes # Redraw the map to update the hitmap

  hideDraggedCanvas: (event) ->
    @draggedCanvas.css 'display', 'none'

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

    # TODO: Take action based on position
    @state.type = 'normal'
    $('body').css 'cursor', @settings.defaultCursor

    @hideDraggedCanvas event

    # Render the map again to make sure the hitmap is up to date
    @renderer.drawMap yes

  normalizeCoordinates: (handler) ->
    return (event) ->
      if event.originalEvent and event.originalEvent.touches and event.originalEvent.touches.length is 1
        event.pageX = event.originalEvent.touches[0].pageX
        event.pageY = event.originalEvent.touches[0].pageY
      return handler(event)

  keyDown: (event) =>
    switch event.keyCode
      when 65 # a
        @map.rotateCW()
      when 68 # d
        @map.rotateCCW()
      when 80 # p
        compressor = new Compressor
        string = compressor.compress @map
        window.location.replace('#' + string);
