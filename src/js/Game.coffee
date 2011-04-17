# This class handles the game logic, it defines the event handlers and
# controls the rendering process.
class Game
  # Creates a new game using the given settings, then calls the onload
  # callback.
  constructor: (onload) ->
    @map = new Map Settings.mapSize

    window.state ?= {}
    state.type = 'normal'

    @marbleRunning = no

    @mainCanvas    = $(Settings.mainCanvasID)
    @draggedCanvas = $(Settings.draggedCanvasID)
    @selector      = $(Settings.selectorID)

    @marble   = new Marble
    @animator = new Animator @map, @marble

    # Set up the renderer
    @renderer = new Renderer @animator, @map, @marble, =>
      # Set up event handlers
      @mainCanvas.bind    'mouseup',   @canvasUp
      @mainCanvas.bind  'mousemove', @canvasMove
      @mainCanvas.bind  'mousedown', @canvasDown

      @mainCanvas.bind 'touchstart', @normalizeCoordinates(@canvasDown)
      @mainCanvas.bind  'touchmove', @normalizeCoordinates(@canvasMove)
      @mainCanvas.bind   'touchend', @normalizeCoordinates(  @canvasUp)

      $body = $('body')

      $body.bind   'mouseup',   @bodyUp
      $body.bind 'mousemove', @bodyMove
      $body.bind 'mousedown', @bodyDown

      $body.bind 'touchstart', @normalizeCoordinates(@bodyDown)
      $body.bind  'touchmove', @normalizeCoordinates(@bodyMove)
      $body.bind   'touchend', @normalizeCoordinates(  @bodyUp)

      rotateEverything = (clockwise) =>
        (event) =>
          @selectBlock null
          @hideSelector()
          
          if clockwise
            @map.rotateCW()
          else
            @map.rotateCCW()

      # Bind event handlers to the rotation arrows
      $('#game .left').bind 'mousedown', rotateEverything(false)
      $('#game .right').bind 'mousedown', rotateEverything(true)

      selectorRotate = (clockwise) =>
        (event) =>
          [x, y, z] = state.info.coordinates
          block      = @map.getBlock x, y, z
          blockOnTop = @map.getBlock x, y, z + 1 if z + 1 < @map.size

          # Do not rotate the lowest layer of the block
          block.rotate      clockwise, yes, yes,  no
          blockOnTop.rotate clockwise,  no,  no, yes if blockOnTop

          event.preventDefault()
          return off

      @selector.children('.left').bind  'mousedown', selectorRotate  no
      @selector.children('.right').bind 'mousedown', selectorRotate yes

      $('.run').bind 'click', @prepareRun

      @palette = new Palette @renderer, @startDragWithBlocks

      animatorLoop = =>
        @animator.animate()
        setTimeout animatorLoop, 20

      setTimeout animatorLoop, 20

      onload()

  # Selects a given block.
  # The selected block will be rendered semi-transparently.
  selectBlock: (block) ->
    @selectedBlock.setSelected no  if @selectedBlock
    @selectedBlock = block 
    @selectedBlock.setSelected yes if @selectedBlock

  # Display the selector overlay at the given screen coordinates.
  # It provides means to rotate the currently selected block.
  displaySelector: (x = 0, y = 0) ->
    @selector.css
      'display': 'block'
      'position': 'absolute'
      'top':  @mainCanvas.offset().top  + y
      'left': @mainCanvas.offset().left + x

  # Hides the selector overlay.
  hideSelector: ->
    @selector.css
      'display': 'none'

  # Default mouseDown event handler for events outside the main canvas.
  #
  # If the user mouse-downs anywhere without being in a drag operation,
  # deselect the current block (if it exists).
  bodyDown: (event) =>
    switch state.type
      when 'normal'
        @selectBlock null
        @hideSelector()

  # Default mouseMove event handler for events outside the main canvas.
  #
  # As we are drawing the currently dragged block on an indepented canvas
  # under the current mouse position, mouse movements during a dragging operation
  # will not be caught by the canvas.
  # Therefore we have to handle the dragging at this position.
  bodyMove: (event) =>
    switch state.type
      when 'dragging'
        @draggingMove event

  # Default mouseUp event handler for events outside the main canvas.
  bodyUp: (event) =>
    switch state.type
      when 'dragging'
        @draggingUp event

    return off

  # Default event handler for mouseUp events inside the main canvas.
  canvasUp: (event) =>
    switch state.type
      # If the user is dragging, end the current dragging operation
      when 'dragging'
        @draggingUp event
      # Select the current block if this is the same block the user previously
      # mouseDowned on.
      when 'down'
        mouseX = event.pageX - @mainCanvas.offset().left
        mouseY = event.pageY - @mainCanvas.offset().top
        if state.info.block is @renderer.resolveScreenCoordinates(mouseX, mouseY).block
          @selectBlock state.info.block
          [screenX, screenY] = @renderer.renderingCoordinatesForBlock state.info.block
          @displaySelector screenX, screenY
          state.type = 'normal'
      # Deselect the currently selected blocks if it exists and the user releases
      # the mouse outside of a block.
      when 'normal'
        @selectBlock null
        @hideSelector()
      else
        console.error "Illegal state", state.type if DEBUG

    # Stop from bubbling
    return off

  # Default event handler for mouseMove events inside the main canvas.
  canvasMove: (event) =>
    mouseX = event.pageX - @mainCanvas.offset().left
    mouseY = event.pageY - @mainCanvas.offset().top
    switch state.type
      when 'down'
        # If the user moves more than `Settings.draggingOffset` pixels
        # from where the put the mouse down, start a drag operation
        if Math.abs(state.downX - mouseX) > Settings.draggingOffset or
           Math.abs(state.downY - mouseY) > Settings.draggingOffset
          @startDrag event
      when 'dragging'
        # This catches events if the dragged blocks are rendered in the main
        # canvas or if the mouse moved faster than we could position the
        # dragged blocks.
        @draggingMove event
      when 'normal'
        if event.type isnt 'touchmove'
          # Set cursor dependent on contents at mouse position.
          side = @renderer.sideAtScreenCoordinates(mouseX, mouseY)
          if side and side isnt 'floor'
            @mainCanvas.css 'cursor', Settings.dragCursor
          else
            @mainCanvas.css 'cursor', Settings.defaultCursor

    if @renderer.sideAtScreenCoordinates(mouseX, mouseY) isnt null
      event.preventDefault()

  # Default event handler for mouseDown events inside the main canvas.
  canvasDown: (event) =>
    switch state.type
      when 'normal'
        mouseX = event.pageX - @mainCanvas.offset().left
        mouseY = event.pageY - @mainCanvas.offset().top
        info = @renderer.resolveScreenCoordinates mouseX, mouseY

        # If the user mouse-downed on a block, save the location and block
        # to detect drag or selection operations.
        if info.block
          state.type  = 'down'
          state.downX = mouseX
          state.downY = mouseY
          state.info  = info
          event.preventDefault()

    return on

  # This method handles the process of dragging operation.
  draggingMove: (event) =>
    # Removing all dragged blocks as they may be drawn elsewhere
    # FIXME: This is only necessary if the position or state of the dragged
    #        blocks actually changed
    didRemoveBlocks = no
    @map.blocksEach (block) =>
      if block.dragged
        @map.removeBlock block.getCoordinates()..., yes
        didRemoveBlocks = yes

    mouseX = event.pageX - @mainCanvas.offset().left
    mouseY = event.pageY - @mainCanvas.offset().top
    info = @renderer.resolveScreenCoordinates mouseX, mouseY

    [x, y, z]   = info.coordinates || [0, 0, 0] #XXX
    targetBlock = @map.getBlock x, y, z
    lowestBlock = state.stack && state.stack[0]

    $('body').css 'cursor', Settings.draggingCursor

    # If the user moved the blocks onto the floor or onto the top of another block,
    # stack them there.
    if info.side is 'floor' or
       info.side is 'top'   and
       @map.heightAt(x, y) + state.stack.length < @map.size + 1 and
       Block.canStack targetBlock, lowestBlock
      @hideDraggedCanvas event

      if lowestBlock
        if info.side is 'top'
          # Set the low type and rotation of the lowest block to whatever the
          # target block has on top
          [type, rotation] = targetBlock.getProperty 'top'

          type = (type is 'crossing-hole') && 'crossing' || type

          lowestBlock.setProperty 'low', type, rotation, yes
        else
          # Set the low type of the to nothing
          lowestBlock.setProperty 'low', null, 0, yes

      offset = if info.side is 'top' then 1 else 0
      @map.setStack state.stack, x, y, z + offset

    # otherwise, display the dragged canvas and move it to the mouse position
    else
      @map.forceUpdate() if didRemoveBlocks
      @showDraggedCanvas event

  # Starts a drag operation using with a given event.
  startDrag: (event) ->
    [x, y, z] = state.info.coordinates
    blocks = @map.removeStack(x, y, z)

    [canvasX, canvasY] = @renderer.renderingCoordinatesForBlock blocks[blocks.length - 1]

    info =
      mouseOffsetX: state.downX - canvasX
      mouseOffsetY: state.downY - canvasY# - Settings.textureSizeHalf

    @startDragWithBlocks blocks, info

  # Starts a drag operation using a given stack of blocks.
  # Info must contain the mouse offsets relative to the block.
  startDragWithBlocks: (blocks, info) =>
    @selectBlock null
    @hideSelector()
    state.stack = blocks
    for block in state.stack
      block.setDragged yes

    @renderer.drawDraggedBlocks state.stack

    state.mouseOffsetX = info.mouseOffsetX
    state.mouseOffsetY = info.mouseOffsetY
    state.type = 'dragging'

  # Hides the dragged blocks.
  hideDraggedCanvas: (event) ->
    @draggedCanvas.css 'display', 'none'

  # Shows the dragged blocks and moves them to the mouse posiiton.
  showDraggedCanvas: (event) ->
    style =
      'display': 'block'
      'position': 'absolute'
      'top':  event.pageY - state.mouseOffsetY
      'left': event.pageX - state.mouseOffsetX
    @draggedCanvas.css style

  # Ends a dragging operation.
  draggingUp: (event) =>
    state.stack = []

    @map.blocksEach (block) =>
      block.setDragged no if block.dragged
    @map.forceUpdate()

    state.type = 'normal'
    $('body').css 'cursor', Settings.defaultCursor

    @hideDraggedCanvas event
    @updateCanvasMargin()

  # Sets the `margin-top` of the main canvas based on the highest block stack.
  updateCanvasMargin: ->
    height = 0
    @map.blocksEach (block) =>
      return if block.dragged

      [x, y, z] = block.getCoordinates()
      height = z if z > height
    @mainCanvas.css
      'margin-top': -50 + (-5 + height) * Settings.textureSizeHalf

  normalizeCoordinates: (handler) ->
    return (event) ->
      if event.originalEvent.touches and event.originalEvent.touches[0]
        event.pageX = event.originalEvent.touches[0].pageX
        event.pageY = event.originalEvent.touches[0].pageY
      return handler(event)

  prepareRun: (event) =>
    $('.inserter').remove()

    @map.blocksEach (block) =>
      [topType, topRotation] = block.getProperty 'top'
      return if topType isnt 'crossing-hole'

      [x, y, z] = block.getCoordinates()

      #return if @map.getBlock x, y, z + 1

      [screenX, screenY] = @renderer.renderingCoordinatesForBlock block

      $inserter = $('<div class="inserter">Drop Marble here!</div>')
      $inserter.css
        top:  @mainCanvas.offset().top  + screenY
        left: @mainCanvas.offset().left + screenX

      $inserter.bind 'click', =>
        x *= Settings.blockSize
        y *= Settings.blockSize
        z *= Settings.blockSize
        x += Settings.blockSize / 2
        y += Settings.blockSize / 2
        z += Settings.blockSize * 3

        @marble.setVelocities  0, 0, 0
        @marble.setCoordinates x, y, z
        @marble.isOnTrack = no
        $('.inserter').remove()

      $('body').append $inserter
