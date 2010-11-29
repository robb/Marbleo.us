fs     = require 'fs'
{exec} = require 'child_process'

task 'build', 'Build application from source files', ->
  puts 'Compiling HAML files'
  exec 'mkdir bin'
  fs.readdir 'src/', (err, files) ->
    for file in files
      continue unless file.match /haml$/
      newFile = file.replace /haml/g, 'html'
      exec "haml src/#{file} bin/#{newFile}", (err) ->
        throw err if err

  puts 'Compiling SASS files'
  exec 'mkdir bin/css'
  fs.readdir 'src/css', (err, files) ->
    for file in files
      continue unless file.match /s(c|a)ss$/
      newFile = file.replace /s(c|a)ss/g, 'css'
      exec "sass src/css/#{file} bin/css/#{newFile}", (err) ->
        throw err if err

  puts 'Copying images'
  exec 'mkdir bin/img/'
  exec 'cp src/img/* bin/img/', (err) ->
    throw err if err

  appContents = null;
  puts 'Compiling CoffeeScript files'
  exec 'mkdir bin/js'
  fs.readdir 'src/js', (err, files) ->
    appContents = new Array remaining = files.length
    files.sort()
    for file in files
      if not file.match /coffee$/
        remaining--
        continue
      else
        fs.readFile "src/js/#{file}", 'utf8', (err, fileContents) ->
          throw err if err
          appContents[remaining] = fileContents
          process() unless --remaining
  process = ->
    fs.writeFile 'bin/js/marbleous.coffee', appContents.join('\n\n'), 'utf8', (err) ->
      throw err if err
      exec 'coffee --compile bin/js/marbleous.coffee', (err, stdout, stderr) ->
        throw err if err
        print stdout + stderr
        fs.unlink 'bin/js/marbleous.coffee', (err) ->
          throw err if err
          puts 'Done.'


task 'minify', 'Minify the resulting application file after build', ->
  puts 'Compiling using ADVANCED_OPTIMIZATIONS'
  exec "closure --compilation_level ADVANCED_OPTIMIZATIONS
                --summary_detail_level 3
                --warning_level VERBOSE
                --js bin/js/marbleous.js
                --js_output_file bin/js/marbleous-min.js
                --warning_level QUIET
                --externs lib/jquery-1.4.4.js
                --externs lib/webkit_console.js", (err, stdout, stderr) ->
    print stdout + stderr
    copy()

  copy = ->
    puts "Overwriting old version with result"
    exec 'mv -vf bin/js/marbleous-min.js bin/js/marbleous.js', (err, stdout, stderr) ->
      throw err if err
      print stdout + stderr
