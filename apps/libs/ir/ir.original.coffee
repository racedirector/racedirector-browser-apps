window.IRacing = class IRacing
    constructor: (@requestParams=[], @requestParamsOnce=[], @fps=1, @server='127.0.0.1:8182', @readIbt=false, @record=null, @zipLibPath=null) ->
        @data = {}
        @onConnect = null
        @onDisconnect = null
        @onUpdate = null
        @onBroadcast = null

        @ws = null
        @onWSConnect = null
        @onWSDisconnect = null
        @reconnectTimeout = null

        @connected = false
        @firstTimeConnect = true

        if @record?
            @loadRecord()
        @connect()

    connect: ->
        @ws = new WebSocket "ws://#{@server}/ws"
        @ws.onopen = (args...) => @onopen args...
        @ws.onmessage = (args...) => @onmessage args...
        @ws.onclose = (args...) => @onclose args...

    close: ->
        @ws.onclose = null
        @ws.close()

    onopen: ->
        @onWSConnect?()

        if @reconnectTimeout?
            clearTimeout @reconnectTimeout

        if not @record?
            for k of @data
                delete @data[k]

            @ws.send JSON.stringify
                fps: @fps
                readIbt: @readIbt
                requestParams: @requestParams
                requestParamsOnce: @requestParamsOnce

    onmessage: (event) ->
        # data = JSON.parse event.data.replace /\bNaN\b/g, 'null'
        data = JSON.parse event.data

        if not @record?
            # on disconnect
            if data.disconnected
                @connected = false
                @onDisconnect?()

            # clear data on connect
            if data.connected
                for k of @data
                    delete @data[k]

            # on connect or first time connect
            if data.connected or (@firstTimeConnect and not @connected)
                @firstTimeConnect = false
                @connected = true
                @onConnect?()

            # update data
            if data.data
                keys = []
                for k, v of data.data
                    keys.push(k)
                    @data[k] = v
                @onUpdate? keys

        # broadcast message
        if data.broadcast
            @onBroadcast? data.broadcast

    onclose: ->
        @onWSDisconnect?()
        if @ws
            @ws.onopen = @ws.onmessage = @ws.onclose = null
        if @connected
            @connected = false
            if not @record?
                @onDisconnect?()
        @reconnectTimeout = setTimeout (=> @connect.apply @), 2000

    sendCommand: (command, args...) ->
        @ws.send JSON.stringify
            command: command
            args: args

    broadcast: (data) ->
        @ws.send JSON.stringify broadcast: data

    loadRecord: ->
        isZip = @zipLibPath and @record.search(/\.zip$/i) != -1
        r = new XMLHttpRequest
        r.onreadystatechange = =>
            if r.readyState == 4 and r.status == 200
                if isZip
                    head = document.head
                    zipSrc = document.createElement 'script'
                    zipSrc.src = @zipLibPath + 'zip.js'
                    head.appendChild zipSrc
                    zipSrc.addEventListener 'load', =>
                        zip.useWebWorkers = false
                        inflateSrc = document.createElement 'script'
                        inflateSrc.src = @zipLibPath + 'inflate.js'
                        head.appendChild inflateSrc
                        inflateSrc.addEventListener 'load', =>
                            zip.createReader new zip.BlobReader(r.response), (zipReader) =>
                                zipReader.getEntries (entry) =>
                                    entry[0].getData new zip.TextWriter, (text) =>
                                        do zipReader.close
                                        head.removeChild inflateSrc
                                        head.removeChild zipSrc
                                        @onRecord JSON.parse text
                else
                    @onRecord r.response
        r.open 'GET', @record, true
        r.responseType = if isZip then 'blob' else 'json'
        r.send()

    onRecord: (frames) ->
        @connected = true
        if 'connected' not of frames[0]
            frames.unshift connected: true
        @record =
            frames: frames
            requestedParamsOnce: []
        @onConnect?()

    playRecord: (startFrame=0, stopFrame=null, speed=1) ->
        @record.currentFrame = 0
        @onConnect? false

        i = startFrame
        while i-- >= 0
            @record.currentFrame++
            @playRecordFrame false

        if @record.playInterval?
            clearInterval @record.playInterval
        if not speed or (stopFrame? and startFrame >= stopFrame)
            if @record.currentFrame < @record.frames.length - 1
                setTimeout =>
                    @record.currentFrame++
                    @playRecordFrame()
                , 1
        else
            @record.playInterval = setInterval =>
                if @record.currentFrame < @record.frames.length - 1 and not (stopFrame? and @record.currentFrame >= stopFrame)
                    @record.currentFrame++
                    @playRecordFrame()
                else
                    clearInterval @record.playInterval
            , 1000 / speed

    resetRecord: ->
        if @record.playInterval?
            clearInterval @record.playInterval
        setTimeout =>
            @record.requestedParamsOnce = []
            for k of @data
                delete @data[k]
            @onDisconnect?()
            setTimeout =>
                @onConnect?()
            , 500
        , 100

    playRecordFrame: (update=true) ->
        data = @record.frames[@record.currentFrame]
        if data?.data
            keys = []
            for k, v of data.data
                if '__all_telemetry__' in @requestParams or k in @requestParams or \
                        (k in @requestParamsOnce and k not in @record.requestedParamsOnce)
                    keys.push k
                    @data[k] = v
                    if k in @requestParamsOnce and k not in @record.requestedParamsOnce
                        @record.requestedParamsOnce.push k
            @onUpdate? keys, update
