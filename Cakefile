fs     = require 'fs'
{exec} = require 'child_process'
util   = require 'util'

binDir = "./node_modules/.bin/"

task 'watch', 'Watch for changes in coffee files to build and test', ->
    # Before entering watch, ensure that any outstanding changes are accounnted for
    invoke 'build'
    invoke 'test'
    util.log "Watching for changes in src, tests, and docs-src"
    lastTest = 0
    watchDir 'src', ->
      invoke 'build'
      invoke 'test'
    watchDir 'tests', ->
      invoke 'test'
    watchDir 'docs-src', ->
      invoke 'build:doc'

task 'test', 'Run the tests', ->
  util.log "Running tests..."
  # The stdout is much bigger than what Cake is willing to handle, so saving it in a file
  exec binDir + "qunit --timeout 10000 -c lib/stomp.js -c tests/config/node-config.js -t tests/unit/* > test.log", (err, stdout, stderr) ->
    if err
      util.log "Tests fail, please check test.log"
      handleError(err)
    else
      util.log "Tests pass!"
      testResultsSummary()

task 'build', 'Build source and tests', ->
  invoke 'build:src'
  invoke 'build:min'
  invoke 'build:doc'

task 'build:src', 'Build the src files into lib', ->
  util.log "Compiling src..."
  exec binDir + "coffee -o lib/ -c src/", (err, stdout, stderr) -> 
    handleError(err) if err

task 'build:min', 'Build the minified files into lib', ->
  util.log "Minify src..."
  exec binDir + "uglifyjs -m --comments all -o lib/stomp.min.js lib/stomp.js", (err, stdout, stderr) ->
    handleError(err) if err

task 'build:doc', 'Build API documentation', ->
  util.log "Building API doc..."
  exec "rm -rf docs/codo; codo -t 'STOMP.js Documentation' -n 'STOMP.js Documentation' -r docs-src/Introduction.md -o ./docs/codo/ src/* - docs-src/* LICENSE.txt", (err, stdout, stderr) ->
    handleError(err) if err
  exec "cp README.md docs/", (err, stdout, stderr) ->
    handleError(err) if err

################################################################################
# Helper functions
################################################################################

watchDir = (dir, callback) ->
  fs.readdir dir, (err, files) ->
      handleError(err) if err
      for file in files then do (file) ->
          fs.watchFile "#{dir}/#{file}", (curr, prev) ->
              if +curr.mtime isnt +prev.mtime
                  callback "#{dir}/#{file}"

testResultsSummary = () ->
  lines = (fs.readFileSync "test.log", 'utf8').split("\n")
  util.log (lines[-7..-2]).join("\n")

handleError = (error, stderr) -> 
  if stderr? and !error
    util.log stderr
  else
    util.log error