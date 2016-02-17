EventEmitter = require '../../core/events'
AVBuffer = require '../../core/buffer'

class WSWorkerSource extends EventEmitter
  constructor: (@url, @file) ->
    @buffer = new Array
    @buffering = true
    @wsWorker = new Worker '/public/js/websocketWorker.js'
    @wsWorker.onmessage = (e) =>
      switch e.data.cmd
        when "data"
          buf = new AVBuffer(e.data.data)
          @bytesLoaded += e.data.data.byteLength
          if @length
            @emit 'progress', @bytesLoaded / @length * 100
          if not @buffering
            @emit 'data', buf
          else 
            @buffer.push buf
            if @buffer.length > 4
              @buffering = false
              while @buffer.length > 0
                buf = @buffer.shift()
                @emit 'data', buf
          
        when "fileSize"
            @length = e.data.value

        when "error"
            @emit "error", e.data.error

        when "end"
            @emit "end"

    @wsWorker.onerror = (e) =>
      @emit "error", e
    
    @wsWorker.postMessage { cmd: "init", config: { host: @url, path: @file } }

  start: ->
    if (@paused)
        @wsWorker.postMessage { cmd: "resume" }
        @paused = false
    else
        @wsWorker.postMessage { cmd: "play" }

  pause: ->
    @wsWorker.postMessage { cmd: "pause" }
    @pause = true

  reset: ->
    @wsWorker.postMessage { cmd: "reset" }


module.exports = WebSocketSource