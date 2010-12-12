class Compressor
  @BytesPerBlock: 7
  constructor: ->
  compress: (map) ->
    bytes   = new Array
    map.blocksEach (block, x, y, z) =>
      return unless block
      for byte in @compressBlock block, x, y, z
        bytes.push byte

    # Base 64 Encoding with URL and Filename Safe Alphabet
    # according to http://tools.ietf.org/html/rfc3548
    string = new Array
    counter = 0
    tmp = 0
    for byte in bytes
      tmp = (tmp << 8) | byte
      counter++

      if counter % 3 is 0 # every third byte
        @pushBytes tmp, string
        tmp = 0

    # If bytes is no multiple of 3, add padding bytes
    if counter % 3
      padding = 0
      while counter++ % 3
        tmp = (tmp << 8)
        padding++

      @pushBytes tmp, string

      while padding--
        string.push '='

    return string.join ''

  pushBytes: (bytes, string) ->
    string.push @encodeBits((bytes & 0xFC0000) >> 18)
    string.push @encodeBits((bytes & 0x03F000) >> 12)
    string.push @encodeBits((bytes & 0x000FC0) >>  6)
    string.push @encodeBits((bytes & 0x00003F))

  decompress: (string, map) ->
    bytes = new Array

    index = 0
    while index < string.length
      if string[index] is '='
        index++
        continue

      tmp = @decodeBits(string[index])     << 18 |
            @decodeBits(string[index + 1]) << 12 |
            @decodeBits(string[index + 2]) <<  6 |
            @decodeBits(string[index + 3])

      bytes.push (tmp & 0xFF0000) >> 16
      bytes.push (tmp & 0x00FF00) >>  8
      bytes.push (tmp & 0x0000FF)

      index += 4

    bytesIndex = 0
    while bytesIndex < (bytes.length - 2)
      [block, x, y, z] = @decompressBlock bytes[bytesIndex..bytesIndex + Compressor.BytesPerBlock]

      map.setBlock block, x, y, z
      bytesIndex += Compressor.BytesPerBlock

  # Make sure this only uses the number of bytes specified in
  # Compressor.BytesPerBlock
  compressBlock: (block, x, y, z) ->
    bytes = new Array
    bytes.push (0xFF & x)
    bytes.push (0xFF & y)
    bytes.push (0xFF & z)
    bytes.push Compressor.CompressionTable[block.properties.top]    || 0x00
    bytes.push Compressor.CompressionTable[block.properties.middle] || 0x00
    bytes.push Compressor.CompressionTable[block.properties.low]    || 0x00

    bytes.push (block.properties.topRotation    / 90) << 4 |
               (block.properties.middleRotation / 90) << 2 |
               (block.properties.topRotation    / 90)

    return bytes

  # TODO: Add a validating constructor to Block class
  decompressBlock: (bytes) ->
    x = bytes[0]
    y = bytes[1]
    z = bytes[2]

    block = new Block 'blank'
    console.log 'testing block types'
    for type, code of Compressor.CompressionTable
      block.properties.top    = type if code is bytes[3]
      block.properties.middle = type if code is bytes[4]
      block.properties.low    = type if code is bytes[5]

    rotations = bytes[6]
    block.properties.topRotation    = 90 * ((rotations & 0x30) >> 4)
    block.properties.middleRotation = 90 * ((rotations & 0x0C) >> 2)
    block.properties.lowRotation    = 90 *  (rotations & 0x03)

    return [block, x, y, z]

  # Value Encoding  Value Encoding  Value Encoding  Value Encoding
  #       0 A            17 R            34 i            51 z
  #       1 B            18 S            35 j            52 0
  #       2 C            19 T            36 k            53 1
  #       3 D            20 U            37 l            54 2
  #       4 E            21 V            38 m            55 3
  #       5 F            22 W            39 n            56 4
  #       6 G            23 X            40 o            57 5
  #       7 H            24 Y            41 p            58 6
  #       8 I            25 Z            42 q            59 7
  #       9 J            26 a            43 r            60 8
  #      10 K            27 b            44 s            61 9
  #      11 L            28 c            45 t            62 - (minus)
  #      12 M            29 d            46 u            63 _ (understrike)
  #      13 N            30 e            47 v
  #      14 O            31 f            48 w         (pad) =
  #      15 P            32 g            49 x
  #      16 Q            33 h            50 y
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
    throw new Error "Invalid argument #{bits} must be in [0..63]"

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

  @CompressionTable:
    # Make sure not to break backwards-compatibility
    # when modifying this table
    'straight':      0x01
    'curve':         0x02
    'crossing':      0x03
    'exchange':      0x04
    'exchange-alt':  0x05
    'dive':          0x06
    'crossing-hole': 0x07
    'drop-middle':   0x08
    'drop-low':      0x09

