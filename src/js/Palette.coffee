class Palette

  @defaultSettings:
    paletteID:         '#palette'
    startDragCallback: (block) ->
    defaultCursor:     null
    dragCursor:        null
    draggingCursor:    null

  constructor: (@renderer, settings = {}) ->
    @settings = {}
    for key, value of Palette.defaultSettings
      @settings[key] = settings[key] || Palette.defaultSettings[key]
    $palette = $(@settings.paletteID)

    for type, description of Block.Types
      block = Block.ofType type
      block.setOpacity 0.4

      canvas = document.createElement 'canvas'
      canvas.width  = @renderer.settings.blockSize
      canvas.height = @renderer.settings.blockSize
      context = canvas.getContext '2d'

      @renderer.drawBlock context, block

      $image = $('<img>')
      $image.data 'type', type
      $image.attr  'src', canvas.toDataURL()

      $palette.append $image

      callback = @settings.startDragCallback
      $image.bind 'mousedown', (event) ->
        info =
          mouseOffsetX: event.pageX - $(this).offset().left
          mouseOffsetY: event.pageY - $(this).offset().top

        block = Block.ofType($(this).data('type'))

        callback [block], info

      renderer = @renderer
      $image.bind 'mousemove', (event) ->
        if state.type is 'normal'
          x = event.pageX - $(this).offset().left
          y = event.pageY - $(this).offset().top
          pixel = renderer.getTexture('basic','hitbox').getContext('2d').getImageData x, y, 1, 1
          if pixel.data[3] > 0
            $('body').css 'cursor', ($.browser.webkit && '-webkit-grab' || $.browser.mozilla && '-moz-grab' || 'auto')
          else
            $('body').css 'cursor', 'auto'

          return off
