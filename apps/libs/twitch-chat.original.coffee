# also need in angular-twitch-chat-channel
# https://api.twitch.tv/kraken/oauth2/authorize?client_id=4lpom5pnvv6hvsqs034mia4zv0gwcs&redirect_uri=http://localhost&response_type=token

window.TwitchChat = class TwitchChat
    constructor: (@channel_id, @divId, @history=null, @host='127.0.0.1:8184') ->
        @conn = null
        @reconnectTimeout = null
        @emoticons = default: []
        @css = $('<style type="text/css">').appendTo 'head'
        @USER_COLORS = ['#ff0000', '#0000ff', '#008000', '#b22222', '#ff7f50', '#9acd32', '#ff4500', '#2e8b57', '#daa520', '#d2691e', '#5f9ea0', '#1e90ff', '#ff69b4', '#8a2be2', '#00ff7f']
        @clientID = '4lpom5pnvv6hvsqs034mia4zv0gwcs'
        @token = '3hmuyd8o3ztryxgg4nbja9jgz8kmwl'
        if @channel_id?.toString().startsWith '@'
            @channel = @channel_id[1...]
            @channel_id = null
        @badgesLoading = []
        @badgesLoaded = []
        @cheermotes = null
        @onConnected = null
        @onDisconnected = null

    connect: (callback) ->
        @conn = new WebSocket "ws://#{@host}/chat/websocket"

        @conn.onopen = =>
            console.log 'chat connected'
            callback?()
            @onConnected?()
            @conn.send JSON.stringify
                channel: @channel.toLowerCase()
                history: @history
            @checkVersionTimeout = setTimeout =>
                @onmessage()
            , 1000

        @conn.onmessage = (event) =>
            if @checkVersionTimeout?
                clearTimeout @checkVersionTimeout
                delete @checkVersionTimeout
            data = event.data
            if typeof data is 'string'
                data = JSON.parse data
            if @onmessage
                @onmessage data.username, data.message, data.data

        @conn.onclose = =>
            console.log 'chat disconnected'
            @onDisconnected?()
            @reconnectTimeout = setTimeout (=> @connect()), 2000

    sendMessage: (message, oauth) ->
        @conn.send JSON.stringify
            oauth: oauth
            channel: @channel.toLowerCase()
            message: message

    getChannelByID: (callback) ->
        if @channel
            callback?()
            return
        $.ajax 'https://api.twitch.tv/helix/users',
            headers:
                # accept: 'application/vnd.twitchtv.v5+json'
                authorization: "Bearer #{@token}"
                'client-id': @clientID
            data:
                id: @channel_id
        .done (data) =>
            if data.error?
                console.log data.status, data.error, data.message
                setTimeout =>
                    @getChannelByID callback
                , 1000
                return
            @channel = data.data[0].login
            callback?()
        .fail =>
            setTimeout =>
                @getChannelByID callback
            , 1000

    getChannelID: (callback) ->
        if @channel_id
            callback?()
            return
        $.ajax 'https://api.twitch.tv/helix/users',
            headers:
                # accept: 'application/vnd.twitchtv.v5+json'
                authorization: "Bearer #{@token}"
                'client-id': @clientID
            data:
                login: @channel
        .done (data) =>
            if data.error?
                console.log data.status, data.error, data.message
                setTimeout =>
                    @getChannelID callback
                , 1000
                return
            @channel_id = data.data[0].id
            callback?()
        .fail =>
            setTimeout =>
                @getChannelID callback
            , 1000

    loadBadges: (callback, roomId='global') ->
        if roomId in @badgesLoaded or roomId in @badgesLoading
            callback?()
            return
        if roomId not in @badgesLoading
            @badgesLoading.push roomId
        $.ajax "https://badges.twitch.tv/v1/badges/#{roomId}/display"
        .done (data) =>
            if data.error?
                console.log data.status, data.error, data.message
                setTimeout =>
                    @badgesLoading.splice @badgesLoading.indexOf(roomId), 1
                    @loadBadges callback, roomId
                , 1000
                return
            for type, v of data.badge_sets
                # console.log v.versions
                for version, v2 of v.versions
                    @css.append "#{@divId} .#{type}#{version} { background-image: url(#{v2.image_url_2x}); }"
                    # @css.append "#{@divId} .#{type}#{version} { background-image: -webkit-image-set(url(#{v2.image_url_1x}) 1x, url(#{v2.image_url_2x}) 2x); }"
            @badgesLoaded.push roomId
            @badgesLoading.splice @badgesLoading.indexOf(roomId), 1
            callback?()
        .fail =>
            callback?()
            setTimeout =>
                @badgesLoading.splice @badgesLoading.indexOf(roomId), 1
                @loadBadges null, roomId
            , 1000

    loadCheerEmotes: (callback) ->
        if @cheermotes then return
        $.ajax 'https://api.twitch.tv/helix/bits/cheermotes',
            headers:
                # accept: 'application/vnd.twitchtv.v5+json'
                authorization: "Bearer #{@token}"
                'client-id': @clientID
            data:
                broadcaster_id: @channel_id
        .done (data) =>
            if data.error?
                console.log data.status, data.error, data.message
                setTimeout =>
                    @loadCheerEmotes callback
                , 1000
                return
            @cheermotes = list: new Map
            prefixes = for e in data.data
                @cheermotes.list.set e.prefix.toLowerCase(), e
                e.prefix.toLowerCase()
            @cheermotes.regex = new RegExp "\\b(?<prefix>#{prefixes.join '|'})(?<bits>\\d+)\\b", 'gi'
            callback?()
        .fail =>
            setTimeout =>
                @loadCheerEmotes callback
            , 1000

    loadIRatings: (callback) ->
        $.getJSON 'https://ir-apps.kutu.ru/twitch-chat/js/wc_drivers.json'
        .done (data) =>
            wcDrivers = data
            @twitchToIRacingPair = {}
            for i in wcDrivers
                @twitchToIRacingPair[i.user_id] = i
            callback?()
        .fail =>
            setTimeout =>
                @loadIRatings callback
            , 1000

    clearChat: (username, strikeOut) ->
        if username?
            a = $("#{@divId} .chat-line[data-username=#{username}]").slice -5
        else
            a = $("#{@divId} .chat-line:not(.blank)")
        if strikeOut
            a.css 'text-decoration': 'line-through'
        else
            a.remove()

    escape: (message) ->
        message.replace(/</g, '&lt;').replace(/>/g, '&gt;')

    emoticonize: (message, data, linkonize=false, scale='1.0') ->
        if not message then return message
        emotes = []
        if data.emotes?
            for e in data.emotes.split '/'
                [id, places] = e.split ':'
                id = id
                for p in places.split ','
                    [start, end] = p.split '-'
                    emotes.push
                        id: id
                        start: parseInt start
                        end: parseInt end
            emotes.sort (a, b) -> if a.start > b.start then 1 else if a.start < b.start then -1 else 0
            msg = []
            prevEmote = null
            for e in emotes
                msg.push message.substring((prevEmote?.end + 1) or 0, e.start), e
                prevEmote = e
            msg.push message.substring(prevEmote.end + 1)
            msg = msg.map (m, i) =>
                if i % 2
                    if m.id.startsWith 'emotesv2_'
                        src = "https://static-cdn.jtvnw.net/emoticons/v2/#{m.id}/default/dark/#{scale}"
                    else
                        src = "https://static-cdn.jtvnw.net/emoticons/v1/#{m.id}/#{scale}"
                    """<img class="emoticon"
                        src="#{src}"
                        alt="#{message.substring m.start, m.end + 1}"
                        title="#{message.substring m.start, m.end + 1}">"""
                else
                    if linkonize then @linkonize @escape m else @escape m
            message = msg.join ''
        else
            message = @escape message
            if linkonize
                message = @linkonize message
        message

    generateEmoticonCss: (e, t) ->
        ".emo-#{t} {\
            background-image: url(#{e.url});\
            width: #{e.width}px;\
            height: #{e.height}px;\
            margin: #{12 - e.height >> 1}px 0;\
        }"

    nameToColor: (name) ->
        acc = 0
        for i in [0...name.length]
            acc += name.charCodeAt(i)
        @USER_COLORS[acc % @USER_COLORS.length]

    calculateColor: (color, background=false) ->
        # background - true for bright, false for dark
        if typeof color is 'number'
            color = "000000#{color.toString 16}"[-6...]
        else
            color = color.toLowerCase().replace /[^0-9a-f]/g, ''
        if color.length == 3
            color = color[0] + color[0] + color[1] + color[1] + color[2] + color[2]
        if color.length != 6
            return "##{color}"

        hash = @calculateColorHash ?= {}
        if color of hash
            if hash[color][background]
                return hash[color][background]
        else
            hash[color] = {}

        out = color
        loop
            yiq = @calculateColorBackground out
            if yiq == background then break
            out = @calculateColorReplacement out, yiq

        hash[color][background] = "##{out}"

    calculateColorBackground: (color) ->
        # Converts HEX to YIQ to judge what color background the color would look best on
        r = parseInt color.substr(0, 2), 16
        g = parseInt color.substr(2, 2), 16
        b = parseInt color.substr(4, 2), 16
        yiq = ((r * 299) + (g * 587) + (b * 114)) / 1000
        yiq < 128

    calculateColorReplacement: (color, background) ->
        # Modified from http://www.sitepoint.com/javascript-generate-lighter-darker-color/
        brightness = if background then 0.2 else -0.5

        for i in [0...3]
            c = Math.max 10, parseInt color.substr(i * 2, 2), 16
            out |= Math.round(Math.min(Math.max(0, c + (c * brightness)), 255)) << ((2 - i) * 8)
        out = "000000#{out.toString 16}"[-6...]

        if color == out
            out = if background then 'ffffff' else '000000'
        out

    linkonize: (message) ->
        if not message then return message
        arr = message.split /((?:https?:[-a-z0-9@:%_+.~!#$*()?&\/=]*)|(?:https?:\/\/)?(?:[-a-z0-9@:%_\+~#=]{1,256}\.)+[a-z]{2,6}(?::\d+)?(?:[\/?][-a-z0-9@:%_+.~!#$*()?&\/=]*)?)/ig
        if arr.length > 1
            for i in [1...arr.length] by 2
                link = arr[i]
                if link.search(/^https?/) == -1
                    link = 'http://' + link
                arr[i] = "<a href='#{link}' target='_blank' rel='noreferrer'>#{arr[i]}</a>"
        arr.join ''

    filterBetBot: (message, isBetBot) ->
        if not message then return false
        if message.search(/^\s*!bet /i) == 0
            return true
        if isBetBot
            if message.search('TOP5: P1') == 0 then return true
            if message.search(/No one has more than [\d,]+/) == 0 then return true
            if message.search(/\s*Use "!bet win 100" to make a bet./) == 0 then return true
            if message.search(/, you have [\d,]+ .+/) != -1 then return true
            if message.search(/, you can bet at least half of your .+/) != -1 then return true
            if message.search(/, you can bet only all of your .+/) != -1 then return true
        false

    bitonize: (message, bits, type, theme, scale='1') ->
        # console.log @cheermotes, message, bits
        if not @cheermotes then return
        if not message then return message
        message = message.split @cheermotes.regex
        # console.log message
        type = if type then 'animated' else 'static'
        theme = if theme then 'dark' else 'light'
        bits = parseInt bits
        # scale 1, 1.5, 2, 3, 4
        # obsVersion = if obsstudio? then (parseInt(i) for i in obsstudio.pluginVersion.split '.')
        # if obsVersion
        #     isOldOBS = not (obsVersion[0] >= 1 and obsVersion[1] >= 31)

        for v, i in message by 3
            if message.length < i + 2 then break
            prefix = message[i + 1]
            cheerBits = parseInt message[i + 2]
            foundTier = null
            # console.log @cheermotes.actions, prefix
            e = @cheermotes.list.get prefix.toLowerCase()
            for t in e.tiers
                if cheerBits >= t.min_bits then foundTier = t else break
            message[i + 1] = ''
            src = foundTier.images[theme][type][scale]
            # if isOldOBS
            #     src = src.replace 'https://d3aqoihi2n8ty8.cloudfront.net/', "http://#{@host}/proxy/cheers/"
            message[i + 2] = """
                <span class="bits" style="color: #{foundTier.color};">
                    <img src="#{src}"
                         alt="#{prefix}#{cheerBits}"
                         title="#{prefix}#{cheerBits}">
                    #{cheerBits}
                </span>"""

        # bg style
        foundTier = null
        for e from @cheermotes.list.values()
            for t in e.tiers
                if bits >= t.min_bits then foundTier = t else break
            if foundTier then break

        [message.join(''), foundTier.color]

    getWCByUserID: (userId) ->
        if not @twitchToIRacingPair? or userId not of @twitchToIRacingPair then return null
        @twitchToIRacingPair[userId]

    checkEmotesSpam: (message, data, max=5) ->
        if not data.emotes? then return false
        count = 0
        for e in data.emotes.split '/'
            [id, places] = e.split ':'
            for p in places.split ','
                [start, end] = p.split '-'
                start = parseInt start
                end = parseInt end
                message = message.substring(0, start) + ' '.repeat(end - start+1) + message.substring(end + 1)
                count++
        count >= max and message.trim().length == 0

    highlightWords: (message, words) ->
        if not words or not message then return message
        message.replace words, """<span class="highlight-word">$1$2</span>"""
