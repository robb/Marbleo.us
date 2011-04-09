module 'EventEmitter'

test 'Emitter creation', ->
  e = new EventEmitter
  ok e?

test 'Emitting once', ->
  onceCalled  = 0
  neverCalled = 0
  
  e = new EventEmitter
  e.once 'test', ->
    onceCalled++

  e.emit 'test'
  e.emit 'test'

  equal 1, onceCalled

test 'Number of arguments', ->
  e = new EventEmitter

  testCalled    = 0
  testArguments = 0

  e.addListener 'test', ->
    testArguments = arguments.length
    testCalled++

  for count in [0...5]
    e.emit 'test', [0...count]...
    equal count, testArguments

  equal 5, testCalled

test 'Remove listeners', ->
  e = new EventEmitter

  testCalled  = 0
  otherCalled = 0

  test  = -> testCalled++
  other = -> otherCalled++

  e.addListener 'event', test
  e.addListener 'event', other

  e.emit 'event'
  e.emit 'event'

  equal 2, testCalled
  equal 2, otherCalled

  e.removeListener 'event', test

  e.emit 'event'
  equal 2, testCalled
  equal 3, otherCalled

  e.removeAllListeners 'event'

  e.emit 'event'
  e.emit 'event'

  equal 3, otherCalled
