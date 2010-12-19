module 'Compressor'

# As per http://tools.ietf.org/html/rfc3548#page-6
codeTable = {
   0: "A",  1: "B",  2: "C",  3: "D",  4: "E",  5: "F",  6: "G",  7: "H",
   8: "I",  9: "J", 10: "K", 11: "L", 12: "M", 13: "N", 14: "O", 15: "P",
  16: "Q", 17: "R", 18: "S", 19: "T", 20: "U", 21: "V", 22: "W", 23: "X",
  24: "Y", 25: "Z", 26: "a", 27: "b", 28: "c", 29: "d", 30: "e", 31: "f",
  32: "g", 33: "h", 34: "i", 35: "j", 36: "k", 37: "l", 38: "m", 39: "n",
  40: "o", 41: "p", 42: "q", 43: "r", 44: "s", 45: "t", 46: "u", 47: "v",
  48: "w", 49: "x", 50: "y", 51: "z", 52: "0", 53: "1", 54: "2", 55: "3",
  56: "4", 57: "5", 58: "6", 59: "7", 60: "8", 61: "9", 62: "-", 63: "_"
}

threeByteTestCases = {
  0x646464: "ZGRk",
  0x782971: "eClx",
  0x6d6172: "bWFy",
  0x626c65: "Ymxl",
  0x6f7573: "b3Vz"
}

test 'Compressor creation', ->
  compressor = new Compressor
  ok compressor, 'Can create compressor'

test 'six bits <=> single character encoding/decoding', ->
  compressor = new Compressor
  for bits, character of codeTable
    bits |= 0 # Convert key back to integer
    equal compressor.encodeBits(bits), character, "0x#{bits.toString(16)} is #{character}"
    equal compressor.decodeBits(character), bits, "0x#{bits.toString(16)} is #{character}"

test 'three bytes <=> three character encoding/decoding', ->
  compressor = new Compressor
  for bytes, string of threeByteTestCases
    bytes |= 0
    equal compressor.decodeBytes(string), bytes, "0x#{bytes.toString(16)} is #{string}"
    equal compressor.encodeBytes(bytes), string, "0x#{bytes.toString(16)} is #{string}"

byteArray = [0x45, 0x46, 0x47, 0x48, 0x49, 0x50]

test 'array <=> string encoding/decoding', ->
  compressor = new Compressor
  equal compressor.encodeArray(byteArray), "RUZHSElQ", "Array should resolve to RUZHSElQ"
  deepEqual compressor.decodeArray("RUZHSElQ"), byteArray, "Array should resolve to RUZHSElQ"

test 'block <=> bytes encoding/decoding', ->
  compressor = new Compressor
  blocks = [
    new Block 'curve-exchange-alt', 90
    new Block 'blank', 0
    new Block 'double-straight', 270
    new Block 'crossing-hole', 180
  ]
  for block in blocks
    deepEqual compressor.decodeBlock(compressor.encodeBlock(block)),
              block

test 'map <=> string encoding/decoding', ->
  compressor = new Compressor
  map = new Map 7

  map.setBlock new Block('crossing-hole'), 0, 0, 0
  map.setBlock new Block('blank'),         0, 0, 1
  map.setBlock new Block('blank'),         0, 5, 0
  map.setBlock new Block('blank'),         0, 5, 1
  map.setBlock new Block('blank'),         0, 5, 2
  map.setBlock new Block('blank'),         0, 5, 3

  emptyMap = new Map 7

  string = compressor.compress(map)
  ok string?, "Compression did return String"

  compressor.decompress(string, emptyMap)

  deepEqual emptyMap, map

test 'max string length for 7x7x7 map', ->
  map = new Map 7
  for x in [0...7]
    for y in [0...7]
      for z in [0...7]
        map.setBlock new Block(), x, y, z

  compressor = new Compressor
  string = compressor.compress(map)
  ok string.length <= 2000, "String length must be at most 2000 character long, is #{string.length}"
