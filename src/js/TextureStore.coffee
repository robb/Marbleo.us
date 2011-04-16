class TextureStore
  constructor: (onload) ->
    @textures = {}

    # Loads the textures from the texture file.
    #
    # The `TextureStore.TextureFileDescription` hash describes the layout of
    # the texture file. The texture file is split into a number of smaller
    # canvases that can be accessed from the @textures object.
    setupTextures = (textureFile) =>
      textureOffset = 0
      for textureGroup, textureDescription of TextureStore.TextureFileDescription
        for texture, rotationsCount of textureDescription
          console.log "loading #{textureGroup}.#{texture}" if DEBUG

          @textures[textureGroup] ?= {}
          @textures[textureGroup][texture] = new Array rotationsCount
          # Iterate over the avaible rotations
          for rotation in [0...rotationsCount]
            canvas = document.createElement 'canvas'
            canvas.width  = Settings.textureSize
            canvas.height = Settings.textureSize
            context = canvas.getContext '2d'
            try
              textureSize = Settings.textureSize
              context.drawImage textureFile,
                                rotation * textureSize, textureOffset * textureSize, textureSize, textureSize
                                                     0,                           0, textureSize, textureSize
            catch error
              if DEBUG
                console.log "Encountered error #{error} while loading texture: #{texture}"
                console.log "Texture file may be too small" if error.name is "INDEX_SIZE_ERR"
              break

            @textures[textureGroup][texture][rotation] = canvas
          textureOffset++

    onloadCallback = =>
      setupTextures textureFile
      onload()

    textureFile = new Image
    textureFile.onload = onloadCallback
    textureFile.src = Settings.textureFile

  getTexture: (group, type, rotation) ->
    unless rotation
      return @textures[group][type][0] if TextureStore.TextureFileDescription[group][type]?

    rotationCount = TextureStore.TextureFileDescription[group][type]
    return null unless rotationCount?
    return @textures[group][type][rotation / 90 % rotationCount]

  # This hash descripes the make-up of the texture files.
  #
  # The file is split into multiple groups that consist of block types at
  # their different rotations, each occupying one row in the file.
  @TextureFileDescription:
    'basic':
      # This hitbox is used to detect which side of the block
      # is at a given pixel by looking up the color.
      #
      #       RGBA       side
      #     #0000FFFF => Top
      #     #00FF00FF => East
      #     #FF0000FF => South
      #     #000000FF => Floor
      #
      'hitbox':          1
      'floor-hitbox':    1
      'solid':           1
      'floor':           1
      'backside':        1
      'outline':         1
      'hole-middle':     2
      'hole-low':        2
      'hole-bottom':     2
    # TODO: Add cutouts for straights/crossings
    'cutouts-top':
      'crossing':        1
      'curve':           4
      'straight':        2
    'cutouts-bottom':
      'crossing':        1
      'curve':           4
      'straight':        2
    'top':
      'crossing':        1
      'crossing-hole':   1
      'curve':           4
      'straight':        2
    'middle':
      'crossing':        1
      'curve':           4
      'straight':        2
      'dive':            4
      'drop-middle':     4
      'drop-low':        4
      'exchange-alt':    4
      'exchange':        4
    'low':
      'crossing':        1
      'curve':           4
      'straight':        2