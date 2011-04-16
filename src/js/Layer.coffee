class Layer
  constructor: (@renderer, @map) ->
    @canvas = document.createElement 'canvas'
    @canvas.width  = Settings.canvasWidth
    @canvas.height = Settings.canvasHeight
    @context = @canvas.getContext '2d'

    @textureStore = @renderer.getTextureStore()

  getTexture: (group, type, rotation) ->
    @textureStore.getTexture group, type, rotation

  getCanvas: ->
    @canvas

  clear: ->
    @context.clearRect 0, 0, Settings.canvasWidth, Settings.canvasHeight
