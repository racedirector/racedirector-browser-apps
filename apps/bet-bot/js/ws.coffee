window.BetBotWebSocket = class BetBotWebSocket
    constructor: (@server='127.0.0.1:8183') ->
        @onConnect = null
        @onDisconnect = null
        @onUpdate = null
        @ws = null
        @reconnectTimeout = null
        @connected = false
        @connect()

    connect: ->
        @ws = new WebSocket "ws://#{@server}/ws"
        @ws.onopen = => @onopen.apply @, arguments
        @ws.onmessage = => @onmessage.apply @, arguments
        @ws.onclose = => @onclose.apply @, arguments

    onopen: ->
        if @reconnectTimeout?
            clearTimeout @reconnectTimeout
        @connected = true
        if @onConnect
            @onConnect()

    onmessage: (event) ->
        data = JSON.parse event.data
        if data and @onUpdate
            @onUpdate data

    onclose: ->
        if @ws
            @ws.onopen = @ws.onmessage = @ws.onclose = null
        if @connected
            @connected = false
            if @onDisconnect
                @onDisconnect()
        @reconnectTimeout = setTimeout (=> @connect.apply @), 2000

    send: (command, args...) ->
        @ws.send JSON.stringify
            command: command
            args: args
