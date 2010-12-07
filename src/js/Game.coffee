class Game
  @defaultSettings:
    mapSize:        7
    canvasID:       '#main-canvas'
    defaultCursor:  'auto'
    dragCursor:     $.browser.webkit && '-webkit-grab' || $.browser.mozilla && '-moz-grab' || 'auto'
    draggingCursor: $.browser.webkit && '-webkit-grabbing' || $.browser.mozilla && '-moz-grabbing' || 'auto'

  constructor: (settings, onload) ->
    @settings = {}
    for key, value of Game.defaultSettings
      @settings[key] = settings[key] || Game.defaultSettings[key]

    @map = new Map @settings.mapSize

    @renderer = new Renderer @map, @settings.canvasID, =>
      $canvas = $(@settings.canvasID)

      $canvas.bind   'mouseup',   @canvasUp
      $canvas.bind 'mousemove', @canvasMove
      $canvas.bind 'mousedown', @canvasDown

      # Populate map
      if DEBUG
        @map.setBlock new Block('curve-straight', 90),  0, 0, 0
        @map.setBlock new Block('double-straight', 90), 1, 0, 0

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
  canvasUp: (event) =>
  canvasMove: (event) =>
    x = event.offsetX || event.layerX - $(event.target).position().left
    y = event.offsetY || event.layerY - $(event.target).position().top
    if side = @renderer.sideAtScreenCoordinates x, y
      $('body').css 'cursor', @settings.dragCursor
    else
      $('body').css 'cursor', @settings.defaultCursor

  canvasDown: (event) =>
    x = event.offsetX || event.layerX - $(event.target).position().left
    y = event.offsetY || event.layerY - $(event.target).position().top
    if info = @renderer.resolveScreenCoordinates x, y
      @selectBlock info.block
    else
      @selectBlock null