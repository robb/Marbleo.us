class Compressor
  # The number of bytes required to encode a given block.
  @BytesPerBlock: 4
  constructor: ->

  # Compresses a map using the following compression scheme:
  #
  #     Iterate over all positions of the map, regardless of whether a block resides
  #     at said position or not.
  #       if a block is at the given position
  #         if the block was preceded by a gap
  #           encode the gap into the bytestream
  #         encode the block into the bytestream
  #       else if the position is empty
  #         increase the size of the current cap by one
  #
  # Encode the bytestream using Base 64 Encoding with URL and Filename Safe
  # Alphabet
  compress: (map) ->
    bytes   = new Array
    gapSize = 0
    for x in [0...map.size]
      for y in [0...map.size]
        for z in [0...map.size]
          unless block = map.getBlock(x, y, z)
            gapSize++
            continue

          if gapSize > 0
            bytes.push 0xFF # Indicates gap
            bytes.push (gapSize & 0xFF0000) >> 16
            bytes.push (gapSize & 0x00FF00) >>  8
            bytes.push (gapSize & 0x0000FF)
            gapSize = 0

          for currentByte in @encodeBlock block
            bytes.push currentByte

    return @encodeArray bytes

  # Decompresses a String into a given map, reversing the scheme given in
  # `Block.compress`
  decompress: (string, map) ->
    try
      bytes = @decodeArray string
    catch e
      throw e

    bytesIndex    = 0
    blockPosition = 0
    while bytesIndex < (bytes.length - 2)
      if bytes[bytesIndex] is 0xFF # Indicates gap
        gapSize = bytes[bytesIndex + 1] << 16 |
                  bytes[bytesIndex + 2] <<  8 |
                  bytes[bytesIndex + 3]

        blockPosition += gapSize
        bytesIndex    += Compressor.BytesPerBlock

      try
        block = @decodeBlock bytes[bytesIndex..bytesIndex + Compressor.BytesPerBlock]
      catch e
        throw e

      # Resolve the x, y and z coordinates by splitting the current block
      # position into powers of `map.size`, so that
      #
      # `x * map.size ^ 2 + y * map.size ^ 1 + z * map.size ^ 0 = blockPosition`
      [x, remainder] = @quotientAndRemainder blockPosition, map.size * map.size
      [y, remainder] = @quotientAndRemainder remainder,     map.size
      z = remainder
      map.setBlock block, x, y, z

      bytesIndex += Compressor.BytesPerBlock
      blockPosition++

  # Returns a size-two-array composed of the quotion and remainder of a
  # given dividend and divisor.
  quotientAndRemainder: (dividend, divisor) ->
    quotient  = Math.floor(dividend / divisor)
    remainder =            dividend % divisor

    return [quotient, remainder]

  # Encodes a given byte array using Base 64 Encoding with URL and Filename
  # Safe Alphabet according to http://tools.ietf.org/html/rfc3548
  encodeArray: (bytes) ->
    string = new Array
    counter = 0
    tmp = 0
    for currentByte in bytes
      tmp = (tmp << 8) | currentByte
      counter++

      if counter % 3 is 0 # every third byte
        string.push @encodeBytes(tmp)
        tmp = 0

    # If the number of encoded bytes is no multiple of 3, add padding bytes
    if counter % 3
      padding = 3 - counter % 3

      tmp = tmp << (padding * 8)
      string.push @encodeBytes(tmp)

      string.push '='  if padding is 1
      string.push '==' if padding is 2

    return string.join ''

  # Decodes a given String in Base 64 Encoding with URL and Filename Safe
  # Alphabet to a byte array.
  decodeArray: (string) ->
    bytes = new Array

    index = 0
    while index < string.length
      if string[index] is '='
        index++
        continue

      try
        tmp = @decodeBytes string[index...index + 4]
      catch e
        throw e

      bytes.push (tmp & 0xFF0000) >> 16
      bytes.push (tmp & 0x00FF00) >>  8
      bytes.push (tmp & 0x0000FF)

      index += 4

    return bytes

  # Encodes a block as a number of bytes.
  # The first byte is composed using the following scheme:
  #
  #      0   0   r1  r1  r2  r2  r3  r3
  #
  # The first two bits are always set to 0 to make sure that this byte can
  # be discerned from the gap indicator (`0xFF`)
  # The subsequent bit pairs are used to encode the rotation of the layers,
  # from `top`, `middle`, `low` in the order of significance.
  #
  # The three follwing bytes encode the `top`, `middle` and `low` layer
  # properties in this order by referencing the values stored in
  # `Block.CompressionTable`
  #
  # Note when changing this method:
  # Make sure this only uses the number of bytes specified in
  # `Compressor.BytesPerBlock`
  encodeBlock: (block) ->
    bytes = new Array

    [topType, topRotation] = block.getProperty 'top'
    [midType, midRotation] = block.getProperty 'middle'
    [lowType, lowRotation] = block.getProperty 'low'

    bytes.push (topRotation / 90) << 4 |
               (midRotation / 90) << 2 |
               (lowRotation / 90)

    bytes.push Compressor.CompressionTable[topType] || 0x00
    bytes.push Compressor.CompressionTable[midType] || 0x00
    bytes.push Compressor.CompressionTable[lowType] || 0x00

    return bytes

  # Decodes a block from a sequence of bytes.
  decodeBlock: (bytes) ->
    rotations   = bytes[0]
    topRotation = 90 * ((rotations & 0x30) >> 4)
    midRotation = 90 * ((rotations & 0x0C) >> 2)
    lowRotation = 90 *  (rotations & 0x03)

    for type, code of Compressor.CompressionTable
      topType = type if code is bytes[1]
      midType = type if code is bytes[2]
      lowType = type if code is bytes[3]

    properties =
      'top':    [topType || null, topRotation],
      'middle': [midType || null, midRotation],
      'low':    [lowType || null, lowRotation]
    return new Block properties

  # Takes a array of bytes of length three and encodes it using Base 64
  # Encoding with URL and Filename Safe Alphabet to a four-character String.
  encodeBytes: (bytes) ->
    try
      result = @encodeBits((bytes & 0xFC0000) >> 18) +
               @encodeBits((bytes & 0x03F000) >> 12) +
               @encodeBits((bytes & 0x000FC0) >>  6) +
               @encodeBits(bytes & 0x00003F)
    catch e
      throw e

  # Takes a string of four characters and decodes it using Base 64 Encoding with
  # URL and Filename Safe Alphabet to a three-byte array.
  decodeBytes: (string) ->
    if string.length isnt 4
      throw new Error "Illegal chunk size, was #{string.length}"

    try
      result = (@decodeBits(string[0]) << 18) |
               (@decodeBits(string[1]) << 12) |
               (@decodeBits(string[2]) <<  6) |
                @decodeBits(string[3])
      return result
    catch e
      throw e

  # Encodes the six least significant bits of the given integer using Base 64
  # Encoding with URL and Filename Safe Alphabet.
  #
  # Throws an error if the given integer is bigger than `0x3F`.
  #
  # Reference table as per http://tools.ietf.org/html/rfc3548
  #
  #     Value Encoding  Value Encoding  Value Encoding  Value Encoding
  #         0 A            17 R            34 i            51 z
  #         1 B            18 S            35 j            52 0
  #         2 C            19 T            36 k            53 1
  #         3 D            20 U            37 l            54 2
  #         4 E            21 V            38 m            55 3
  #         5 F            22 W            39 n            56 4
  #         6 G            23 X            40 o            57 5
  #         7 H            24 Y            41 p            58 6
  #         8 I            25 Z            42 q            59 7
  #         9 J            26 a            43 r            60 8
  #        10 K            27 b            44 s            61 9
  #        11 L            28 c            45 t            62 - (minus)
  #        12 M            29 d            46 u            63 _ (understrike)
  #        13 N            30 e            47 v
  #        14 O            31 f            48 w         (pad) =
  #        15 P            32 g            49 x
  #        16 Q            33 h            50 y
  #
  encodeBits: (bits) ->
    if  0 <= bits <= 25 # A-Z
      return String.fromCharCode(65 + bits)
    if 26 <= bits <= 51 # a-z
      return String.fromCharCode(97 + bits - 26)
    if 52 <= bits <= 61 # 0-7
      return String.fromCharCode(48 + bits - 52)
    if bits is 62
      return '-'
    if bits is 63
      return '_'
    throw new Error "Invalid argument #{bits} must be smaller than 0x3F (63)"

  # Decodes a character to a sequence to the six least significant bits of the
  # return integer.
  #
  # See `encodeBits` for a overview of the enconding process.
  #
  decodeBits: (character) ->
    charCode = character.charCodeAt 0
    if 65 <= charCode <=  90
      return charCode - 65
    if 97 <= charCode <= 122
      return charCode - 97 + 26
    if 48 <= charCode <= 57
      return charCode - 48 + 52
    if charCode is 45 # minus
      return 62
    if charCode is 95 # understrike
      return 63
    throw new Error "Invalid argument, char must be of [A-Za-z0-9-_], was #{character}"

  # Make sure not to break backwards-compatibility
  # when modifying this table
  @CompressionTable:
    'straight':      0x01
    'curve':         0x02
    'crossing':      0x03
    'exchange':      0x04
    'exchange-alt':  0x05
    'dive':          0x06
    'crossing-hole': 0x07
    'drop-middle':   0x08
    'drop-low':      0x09
