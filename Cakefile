sys    = require 'sys'
fs     = require 'fs'
{exec} = require 'child_process'

buildFiles = [
  "Constants",
  "Block",
  "Map",
  "Renderer",
  "Compressor",
  "Game",
  "Palette",
  "Main"
]

task 'build', 'Build application from source files', ->
  sys.puts 'Compiling HAML files'
  exec 'mkdir bin', ->
    fs.readdir 'src/', (err, files) ->
      for file in files
        continue unless file.match /haml$/
        newFile = file.replace /haml/g, 'html'
        exec "haml src/#{file} bin/#{newFile}", (err) ->
          throw err if err

  sys.puts 'Compiling SASS files'
  exec 'mkdir bin/css', ->
    exec 'mkdir src/css', ->
      fs.readdir 'src/css', (err, files) ->
        for file in files
          continue unless file.match /s(c|a)ss$/
          newFile = file.replace /s(c|a)ss/g, 'css'
          exec "sass src/css/#{file} bin/css/#{newFile}", (err) ->
            throw err if err

  sys.puts 'Copying images'
  exec 'mkdir bin/img/', ->
    exec 'cp src/img/* bin/img/', (err) ->
      throw err if err

  sys.puts 'Compiling CoffeeScript files'
  exec 'mkdir bin/js', ->
    appContents = new Array remaining = buildFiles.length
    counter = 0
    for file in buildFiles
      fs.readFile "src/js/#{file}.coffee", 'utf8', (err, fileContents) ->
        throw err if err
        appContents[counter++] = fileContents
        process() unless --remaining
    process = ->
      fs.writeFile 'bin/js/marbleous.coffee', appContents.join('\n\n'), 'utf8', (err) ->
        throw err if err
        exec 'coffee --compile bin/js/marbleous.coffee', (err, stdout, stderr) ->
          throw err if err
          sys.print stdout + stderr
          fs.unlink 'bin/js/marbleous.coffee', (err) ->
            throw err if err
            sys.puts 'Done.'

# TODO: Make this work on Simon's machine
# TODO: Try to resolve marbleo.us.test before opening the browser,
#       to make sure the testing server is set up properly
task 'test', 'Compile the app for testing, try opening a browser', ->
  sys.puts 'Compiling CoffeeScript files for test'
  exec 'mkdir -p test/js'

  appContents = new Array remaining = buildFiles.length
  counter = 0
  for file in buildFiles
    fs.readFile "src/js/#{file}.coffee", 'utf8', (err, fileContents) ->
      throw err if err
      appContents[counter++] = fileContents
      process() unless --remaining
  process = ->
    fs.writeFile 'test/js/marbleous.coffee', appContents.join('\n\n'), 'utf8', (err) ->
      throw err if err
      exec 'coffee --bare --compile test/js/marbleous.coffee', (err, stdout, stderr) ->
        throw err if err
        sys.print stdout + stderr
        fs.unlink 'test/js/marbleous.coffee', (err) ->
          throw err if err
          sys.puts 'Done.'

  sys.puts 'Opening browser...'
  exec 'open http://marbleo.us.test'

task 'minify', 'Minify the resulting application file after build', ->
  sys.puts 'Compiling using ADVANCED_OPTIMIZATIONS'
  exec "closure --compilation_level ADVANCED_OPTIMIZATIONS
                --summary_detail_level 3
                --warning_level VERBOSE
                --js bin/js/marbleous.js
                --js_output_file bin/js/marbleous-min.js
                --warning_level QUIET
                --externs lib/jquery-1.4.4.js
                --externs lib/webkit_console.js", (err, stdout, stderr) ->
    sys.print stdout + stderr
    copy()

  copy = ->
    sys.puts "Overwriting old version with result"
    exec 'mv -vf bin/js/marbleous-min.js bin/js/marbleous.js', (err, stdout, stderr) ->
      throw err if err
      sys.print stdout + stderr
