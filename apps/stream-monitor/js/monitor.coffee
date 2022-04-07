#     .______      ___      .______          ___      .___  ___.      _______.
#     |   _  \    /   \     |   _  \        /   \     |   \/   |     /       |
#     |  |_)  |  /  ^  \    |  |_)  |      /  ^  \    |  \  /  |    |   (----`
#     |   ___/  /  /_\  \   |      /      /  /_\  \   |  |\/|  |     \   \
#     |  |     /  _____  \  |  |\  \----./  _____  \  |  |  |  | .----)   |
#     | _|    /__/     \__\ | _| `._____/__/     \__\ |__|  |__| |_______/
#

params =
    host: 'localhost:8184'
    showViewersCounter: true
    showFollowersCounter: true
    showEmoticons: true
    showBadges: true
    showBits: true
    bitsType: true
    bitsTheme: false
    filterBetBot: 'BatManCave'
    filterBots: 'MooBot,NightBot'
    smoothScrolling: true
    strikeOutMessages: true
    showIRatings: false

for v in (window.location.search.substring 1).split '&'
    [key, val] = v.split '='
    val = decodeURIComponent val
    if /^\d{1,10}$/.test val
        val = parseInt val
    params[key] = val

if not params.twitchOAuthToken?
    return

if params.filterBetBot?
    params.filterBetBot = params.filterBetBot.toLowerCase()
if params.filterBots?
    if not params.filterBots.length
        params.filterBots = null
    else
        params.filterBots = for bot in params.filterBots.split ','
            bot.trim().toLowerCase()

if params.highlightMessages?
    params.highlightMessages = for word in params.highlightMessages.split ','
        new RegExp "\\b#{word}\\b", 'i'

if not params.showViewersCounter and not params.showFollowersCounter
    $('.counters').remove()
else if not params.showViewersCounter
    $('.counters #viewers').parent().remove()
else if not params.showFollowersCounter
    $('.counters #followers').parent().remove()

if params.twitchAlertsToken and not params.streamLabsToken
    params.streamLabsToken = params.twitchAlertsToken

#     .___________.____    __    ____  __  .___________.  ______  __    __
#     |           |\   \  /  \  /   / |  | |           | /      ||  |  |  |
#     `---|  |----` \   \/    \/   /  |  | `---|  |----`|  ,----'|  |__|  |
#         |  |       \            /   |  |     |  |     |  |     |   __   |
#         |  |        \    /\    /    |  |     |  |     |  `----.|  |  |  |
#         |__|         \__/  \__/     |__|     |__|      \______||__|  |__|
#

class TwitchApi
    constructor: ->
        @baseUri = 'https://api.twitch.tv/kraken'
        # @collectFollowersPagesLeft = null
        # @followers = []
        @lastAdRunTime = null
        @connect()

    connect: ->
        $.ajax @baseUri,
            headers:
                accept: 'application/vnd.twitchtv.v5+json'
                authorization: "OAuth #{params.twitchOAuthToken}"
        .done (data) =>
            if data.error
                console.log data
                return
            @token = data.token
            # test
            # @token.user_name = 'witwix'
            # @token.user_name = 'welovegames'
            # @token.user_name = 'cdnthe3rd'
            # @token.user_name = 'lirik'
            # @token.user_name = 'sevadus'
            # @token.user_name = 'jplays'
            # @token.user_name = 'showdown1983'
            # @token.user_name = 'manvsgame'
            if not @token.valid
                alert 'Twitch token not valid, revalidate it on settings page'
                return
            @afterConnect()
        .fail (jqXHR, textStatus) =>
            console.log arguments
            setTimeout =>
                @connect()
            , 1000

    afterConnect: ->
        @getStatus()
        @gameSuggest()
        if params.showViewersCounter
            @updateViewers()
        new TwitchFollower @token.user_id, @token.client_id, 5, (user, total) ->
            if user? then chat.addSpecialMessage "New Follower: #{user.display_name}", 'follower'
            if params.showFollowersCounter
                $('#followers').text total
        @addIFrameChat()
        chat.channel = @token.user_name
        chat.channel_id = @token.user_id
        chat.init()

    getStatus: ->
        $.ajax "#{@baseUri}/channels/#{@token.user_id}",
            headers:
                accept: 'application/vnd.twitchtv.v5+json'
                'client-id': @token.client_id
        .done (data) =>
            if data.error?
                setTimeout =>
                    @getStatus()
                , 1000
                return
            $('#twitch-status').val data.status
            $('#twitch-game')[0].selectize.createItem data.game
            $('#update-status-btn').click =>
                @updateStatus $('#twitch-status').val(), $('#twitch-game').val()
            $('#tweet-status-btn').click =>
                window.open "https://twitter.com/intent/tweet?url=http://twitch.tv/\
                    #{@token.user_name}\
                    &text=#{encodeURIComponent $('#twitch-status').val()}",
                    '_blank', "left=#{window.screen.width - 500 >> 1},top=100,width=500,height=256"
            $('#update-status-btn, #tweet-status-btn').removeAttr 'disabled'

            # ads
            # test
            # data.partner = true
            if data.partner
                $('#ad-btn').removeClass 'hidden'
                $('#ad-btn > ul > li > a').click => @adBtnClick.apply @, arguments

            # stay unfocused
            $('.btn').mouseup -> $(this).blur()
            $('.btn').mouseleave -> $(this).blur()
        .fail =>
            console.log arguments
            setTimeout =>
                @getStatus()
            , 1000

    updateStatus: (status, game) ->
        $.ajax "#{@baseUri}/channels/#{@token.user_id}",
            method: 'PUT'
            data:
                channel:
                    status: status
                    game: game
            headers:
                accept: 'application/vnd.twitchtv.v5+json'
                authorization: "OAuth #{params.twitchOAuthToken}"
        .done (data) ->
            if data.error?
                console.log data
                chat.log data.message
            else
                chat.log 'Stream title has been updated'
        .fail =>
            console.log arguments
            setTimeout =>
                @updateStatus status, game
            , 1000

    gameSuggest: ->
        $('#twitch-game').selectize
            valueField: 'name'
            labelField: 'name'
            searchField: ['name']
            sortField:
                field: 'popularity'
                direction: 'desc'
            highlight: false
            create: (input, callback) ->
                callback
                    name: input
                    box: {}
            createOnBlur: true
            selectOnTab: true
            persist: false
            # hideSelected: true
            allowEmptyOption: true
            render:
                option_create: (data, escape) ->
                    "<div><strong>#{escape data.input}</strong>&hellip;</div>"
                option: (item, escape) ->
                    "<div>\
                        #{if item.box.small then "<img src='#{item.box.small}' class='game-thumbnail'></img>" else ''}
                        <span class='game-title'>#{escape item.name}</span>\
                    </div>"
            score: (search) ->
                score = @getScoreFunction search
                (item) ->
                    score(item) * (1 + item.popularity)
            load: (query, callback) =>
                if not query.length then return callback()
                $.ajax "#{@baseUri}/search/games",
                    data:
                        query: query
                    headers:
                        accept: 'application/vnd.twitchtv.v5+json'
                        'client-id': @token.client_id
                .done (data) ->
                    if data.error?
                        callback()
                        return
                    callback data.games
                .fail ->
                    callback()
            firstTime: true
            onFocus: ->
                if @settings.firstTime
                    for i of @options
                        if not @options[i].box.small?
                            @$control_input.val i
                            @clearOptions()
                            @onSearchChange i
                            @settings.firstTime = false
                            break
    updateViewers: ->
        $.ajax "#{@baseUri}/streams/#{@token.user_id}",
            headers:
                accept: 'application/vnd.twitchtv.v5+json'
                'client-id': @token.client_id
        .done (data) ->
            if not data.error? and data.stream?.viewers
                $('#viewers').text data.stream.viewers
        setTimeout =>
            @updateViewers()
        , 10000

    addIFrameChat: ->
        $('#fold-but, #chat-embed').show()
        $('#chat-embed').attr src: "http://www.twitch.tv/#{@token.user_name}/chat"
        folded = true
        upSymbols = '&utrif;&utrif;&utrif;'
        downSymbols = '&dtrif;&dtrif;&dtrif;'
        $('#fold-but').html upSymbols
        $('#fold-but').click ->
            folded = not folded
            needToScroll = chat.needToScroll()
            $('#fold-but').html if folded then upSymbols else downSymbols
            $('#chat-embed').toggleClass 'open', not folded
            if needToScroll
                chat.scrollChat()

    adBtnClick: (event) ->
        $('#ad-btn > button').attr disabled: 'disabled'
        index = $('#ad-btn > ul > li').index event.target.parentElement
        $.post "#{@baseUri}/channels/#{@token.user_id}/commercial",
            data:
                length: [30, 60, 90, 120, 150, 180][index]
            headers:
                accept: 'application/vnd.twitchtv.v5+json'
                authorization: "OAuth #{params.twitchOAuthToken}"
        .done (data) ->
            if data.error?
                chat.log data.message
                $('#ad-btn > button').removeAttr 'disabled'
                return
            chat.log 'Commercial has been ran'
            setTimeout ->
                $('#ad-btn > button').removeAttr 'disabled'
            , 8 * 60 * 1000
        .fail ->
            chat.log 'Something gone wrong with run commercial'
            $('#ad-btn > button').removeAttr 'disabled'

#       ______  __    __       ___   .___________.
#      /      ||  |  |  |     /   \  |           |
#     |  ,----'|  |__|  |    /  ^  \ `---|  |----`
#     |  |     |   __   |   /  /_\  \    |  |
#     |  `----.|  |  |  |  /  _____  \   |  |
#      \______||__|  |__| /__/     \__\  |__|
#

chat = new TwitchChat null, '#chat-box', 50, params.host
chat.init = ->
    # add blank lines, then connect
    timer = setInterval =>
        for i in [0...10]
            $('<div class="chat-line blank">&nbsp;</div>').appendTo @divId
        if $(@divId)[0].scrollHeight <= window.screen.height #$(@divId).height()
            return
        clearInterval timer

        # scroll on window resize
        $(window).resize =>
            $(@divId).stop true, true
            if @needToScroll()
                $(@divId)[0].scrollTop = $(@divId)[0].scrollHeight

        $(@divId)[0].scrollTop = $(@divId)[0].scrollHeight
        @scrollEnd = $(@divId)[0].scrollHeight - 30

        queue = [
            [params.showBadges, @loadBadges]
            [params.showBits, @loadCheerEmotes]
            [params.showIRatings, @loadIRatings]
            [true, @connect]
        ].filter (q) -> q[0]
        queueNext = =>
            if queue.length
                queue.shift()[1].call @, queueNext
            else
                # test
                # @addSpecialMessage 'new donation: $5.99 http://ir-apps.kutu.ru/#!/ Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.', 'donation'
                # @addSpecialMessage 'notify', 'notify'
                # @addSpecialMessage 'new follower: qwe', 'follower'
                # @addSpecialMessage 'log message', 'log'
                # @addSpecialMessage 'hello username', 'highlight'
                # @addSpecialMessage 'Chat has been cleared', 'ban'
                # testLines = [
                #     {"username":null,"message":"Since its my 7th month subiversary can i get 7 lirikN s from chat","data":{"usernotice":true,"badges":"subscriber/6,premium/1","display-name":null,"msg-param-sub-plan":"Prime","login":"creeperslayer803","turbo":0,"mod":0,"user-id":"49262100","id":"a0d8e6e1-c1c3-45a0-9862-f5c7c456288b","msg-param-months":"7","room-id":"23161357","msg-id":"resub","system-msg":"creeperslayer803 just subscribed with Twitch Prime. creeperslayer803 subscribed for 7 months in a row!","color":null,"emotes":"96286:47-52","msg-param-sub-plan-name":"Channel Subscription (LIRIK)","tmi-sent-ts":"1493490407549","user-type":null,"subscriber":1}}
                #     {"username":"twitchnotify","message":"taytoes93 just subscribed with Twitch Prime!","data":{}}
                #     {"username":null,"message":"LUV ME DADDY PogChamp","data":{"usernotice":true,"badges":"subscriber/0","display-name":"f00d_p0rn420","msg-param-sub-plan":"1000","login":"f00d_p0rn420","turbo":0,"mod":0,"user-id":"126830175","id":"f53563b6-8133-4d89-a47a-1a1915de78f3","msg-param-months":1,"room-id":"23161357","msg-id":"sub","system-msg":"f00d_p0rn420 just subscribed with a $4.99 sub!","color":"#FF69B4","emotes":"88:13-20","msg-param-sub-plan-name":"Channel Subscription (LIRIK)","tmi-sent-ts":"1493485519519","user-type":null,"subscriber":1}}
                #     {"username":"babycakeswaffle","message":"Tiago lirikCHAMP lirikHug geersH waffleLove lirikH :P /","data":{"room-id":"23161357","turbo":0,"id":"58eaab37-aa63-4e60-ab27-d36f5302068e","mod":1,"badges":"moderator/1,subscriber/24","user-type":"mod","user-id":"40316546","subscriber":1,"color":"#7E2F9D","emotes":"50741:6-15/29049:17-24/65079:26-31/49868:33-42/15020:44-49/12:51-52","display-name":"Babycakeswaffle"}}
                #     {"username":"mucx","message":"cheer100 here yo go baby grill","data":{"room-id":"23161357","user-id":"744132","id":"e63fdfbe-d526-42c1-b984-ca9d067deaca","bits":"100","color":"#6120AC","subscriber":1,"turbo":1,"emotes":null,"mod":0,"badges":"staff/1,subscriber/24,turbo/1","user-type":"staff","display-name":"Mucx"}}
                #     {"username":null,"message":null,"data":{"usernotice":true,"badges":"subscriber/3","display-name":"TortoiseHelmet","msg-param-sub-plan":"1000","login":"tortoisehelmet","turbo":0,"mod":0,"user-id":"56128718","id":"9873e399-18ad-4c29-997f-10bddfdc3aa3","msg-param-months":"3","room-id":"23161357","msg-id":"resub","system-msg":"TortoiseHelmet subscribed for 3 months in a row!","color":"#738A42","emotes":null,"msg-param-sub-plan-name":"Channel Subscription","tmi-sent-ts":"1493485406901","user-type":null,"subscriber":1}}
                #     {"username":null,"message":"you earned it, fucking epic man.","data":{"usernotice":true,"badges":"subscriber/0,premium/1","display-name":null,"msg-param-sub-plan":"3000","login":"kilyin74","turbo":0,"mod":0,"user-id":"36264874","id":"0877a6b1-ad2f-411e-8a77-1c6bda0eaa7a","msg-param-months":1,"room-id":"23161357","msg-id":"sub","system-msg":"kilyin74 just subscribed with a $24.99 sub!","color":"#1940B3","emotes":null,"msg-param-sub-plan-name":"Channel Subscription (LIRIK): $24.99 Sub","tmi-sent-ts":"1493488925976","user-type":null,"subscriber":1}}
                #     {"username":null,"message":"you earned it, fucking epic man.","data":{"usernotice":true,"badges":"subscriber/0,premium/1","display-name":null,"msg-param-sub-plan":"3000","login":"kilyin74","turbo":0,"mod":0,"user-id":"36264874","id":"0877a6b1-ad2f-411e-8a77-1c6bda0eaa7a","msg-param-months":1,"room-id":"23161357","msg-id":"sub","system-msg":"kilyin74 just subscribed with a $24.99 sub!","color":"#1940B3","emotes":null,"msg-param-sub-plan-name":"Channel Subscription (LIRIK): $24.99 Sub","tmi-sent-ts":"1493488925976","user-type":null,"subscriber":1}}
                # ]
                # for l in testLines then @onmessage l.username, l.message, l.data
        queueNext()
    , 1

chat.onmessage = (username, message, data={}) ->
    # console.log username, message, data, action

    # check version
    if not @versionChecked and data.version
        @versionChecked = true
        if data.version < 14
            @addSpecialMessage '
                Update apps, run update.exe or download
                <a href="/downloads/ir-browser-server-64.zip">64bit</a>.
                <ul>
                    <li>timeout and ban notifications</li>
                    <li>"cheers" settings</li>
                </ul>
            ', 'update', false
            delete @onmessage

    if data.clearchat
        @clearChat message, params.strikeOutMessages
        if message
            if data['ban-duration']?
                message = "#{message} has been timed out for #{data['ban-duration']} seconds."
            else
                message = "#{message} is now banned from this room."
            if data['ban-reason']
                message += " Reason: #{data['ban-reason']}."
            @addSpecialMessage message, 'ban'
        else
            @addSpecialMessage 'Chat has been cleared', 'ban'
        return

    if not data.pubnotice? and not data.usernotice?
        if not username? or not message?
            return

    # filter betbot
    if message? and params.filterBetBot? and params.filterBetBot.length and \
            @filterBetBot message, username == params.filterBetBot
        return

    # filter bots
    if username and params.filterBots and username in params.filterBots
        return

    # filter !raffle
    if message == '!raffle'
        return

    # notify
    if data.pubnotice or data.usernotice or username == 'twitchnotify'
        newLine = $ '<div>'
        newLine.addClass 'chat-line notify'
        formattedMessage = $ '<span>'
        formattedMessage.addClass 'message'
        formattedMessage.text data['system-msg'] or message
        newLine.append formattedMessage
        newLine.appendTo @divId
        if data.usernotice and message
            username = data.login
            # sub / resub
            if data['msg-id'] in ['sub', 'resub', 'subgift']
                newLine.addClass 'sub'
        else
            @scrollChat()
            return

    data.color ?= @nameToColor username

    newLine = $ '<div>'
    newLine.attr 'data-username', username
    newLine.addClass 'chat-line'

    # badges
    if params.showBadges and data.badges
        for i in data.badges.split ','
            [badge, version] = i.split '/'
            tag = $ '<span>'
            tag.addClass "#{badge}#{version}"
            if badge == 'subscriber'
                @loadBadges null, "channels/#{data['room-id']}"
            tag.addClass 'tag'
            tag.html '&nbsp'
            newLine.append tag

    # irating badge
    if params.showIRatings
        wcDriver = @getWCByUserID data['user-id']
        # test
        # wcDriver = irating: 5900
        if wcDriver?
            tag = $ '<span>'
            tag.addClass 'irating-badge'
            tag.text "#{(Math.floor(wcDriver.irating / 100) / 10).toFixed 1}k"
            newLine.append tag

    # sub / resub
    if data.usernotice and data['msg-id'] in ['sub', 'resub', 'subgift']
        newLine.addClass 'sub'
        data.color = @calculateColor data.color
    else
        data.color = @calculateColor data.color, true

    displayName = data['display-name'] or (username[0].toUpperCase() + username[1..])
    if displayName[0].charCodeAt(0) > 255
        displayName += " (#{username})"

    formattedUser = $ '<span>'
    formattedUser.addClass 'username'
    formattedUser.css 'color', data.color
    formattedUser.text displayName
    newLine.append formattedUser
    newLine.append "#{if data.action then '' else ':'}&nbsp;"

    formattedMessage = $ '<span>'
    formattedMessage.addClass 'message'
    if data.action
        formattedMessage.css 'color', data.color
    # highlight messages
    if params.highlightMessages? and username != @channel
        for word in params.highlightMessages
            if message.search(word) != -1
                newLine.addClass 'highlight'
                break
    if params.showEmoticons
        message = @emoticonize message, data, true, '2.0'
    if params.showBits and data.bits? and data.bits > 0
        [message, bg] = @bitonize message, data.bits, params.bitsType, params.bitsTheme, '2'
        newLine.css backgroundImage: "linear-gradient(-90deg, #{bg}, rgba(0, 0, 0, 0) 50%)"
    formattedMessage.html message
    newLine.append formattedMessage
    needToScroll = @needToScroll()
    newLine.appendTo @divId

    # scroll after all images loaded
    if needToScroll
        messageImages = formattedMessage.find 'img'
        imagesCount = messageImages.length
        if imagesCount
            scrollHeight = $(@divId)[0].scrollHeight
            messageImages.on 'load error', =>
                h = $(@divId)[0].scrollHeight
                if scrollHeight < h
                    scrollHeight = h
                    @scrollChat()
                if not --imagesCount
                    messageImages.off 'load error', arguments.callee
        @scrollChat()

chat.addSpecialMessage = (message, cssClass, safe=true) ->
    newLine = $ '<div>'
    newLine.addClass 'chat-line'
    newLine.addClass cssClass
    formattedMessage = $ '<span>'
    formattedMessage.addClass 'message'
    if safe
        message = @escape message
        message = @linkonize message
    formattedMessage.html message
    newLine.append formattedMessage
    needToScroll = @needToScroll()
    newLine.appendTo @divId
    if needToScroll
        @scrollChat()

chat.log = (message) ->
    @addSpecialMessage message, 'log'

chat.needToScroll = ->
    hei = $(@divId)[0].scrollTop + $(@divId).height()
    hei >= $(@divId)[0].scrollHeight - 30 or hei >= @scrollEnd

chat.scrollChat = ->
    if params.smoothScrolling
        $(@divId).stop()
        $(@divId).animate scrollTop: $(@divId)[0].scrollHeight - $(@divId).height(),
            200, 'linear', => @clearHiddenMessages()
    else
        $(@divId)[0].scrollTop = $(@divId)[0].scrollHeight
        @clearHiddenMessages()

chat.clearHiddenMessages = ->
    # top = $("#{@divId}").position().top
    # wrapHeight = $("#{@divId}").height()
    for item in $ "#{@divId} > div.blank"
        item = $ item
        if item.position().top < -window.screen.height
            item.remove()
        else
            break
    while $("#{@divId} > div.chat-line").length > 1000
        $("#{@divId} > div.chat-line").first().remove()
    @scrollEnd = $(@divId)[0].scrollHeight - 30

#      _______  __    __   _______  __           ______     ___       __        ______
#     |   ____||  |  |  | |   ____||  |         /      |   /   \     |  |      /      |
#     |  |__   |  |  |  | |  |__   |  |        |  ,----'  /  ^  \    |  |     |  ,----'
#     |   __|  |  |  |  | |   __|  |  |        |  |      /  /_\  \   |  |     |  |
#     |  |     |  `--'  | |  |____ |  `----.   |  `----./  _____  \  |  `----.|  `----.
#     |__|      \______/  |_______||_______|    \______/__/     \__\ |_______| \______|
#

class FuelCalc
    constructor: ->
        @storageName = 'stream-monitor.settings'
        @show = false
        @firstTime = true

        $('#fuel-calc-btn').click =>
            @show = not @show
            if @show and @firstTime
                @firstTime = false
                size = @getModalSize()
                $('#fuel-calc').css
                    position: 'fixed'
                    top: size.top
                    left: Math.min(size.left, $(window).width() - $('#fuel-calc').width())
                    width: size.width
                    height: size.height
            @checkBorders()
            if @show
                $('<iframe src="/fuel-calc/"></iframe>').appendTo '#fuel-calc'
            $('#fuel-calc').toggle @show
            if not @show
                $('#fuel-calc iframe').remove()

        $('#fuel-calc .close').click =>
            @show = false
            $('#fuel-calc').toggle @show

        $('#fuel-calc').draggable
            handle: '.modal-fuel-calc-header'
            stop: => @saveModalSize()

        $('#fuel-calc').resizable
            minWidth: 300
            minHeight: 380
            stop: => @saveModalSize()

        # test
        # $('#fuel-calc-btn').click()

    checkBorders: ->
        div = $('#fuel-calc')
        pos = div.position()
        if pos.top < 0
            div.css top: 0
        if pos.left < 0
            div.css left: 0
        else if pos.left + div.width() > $(window).width()
            div.css left: $(window).width() - div.width()

    getModalSize: ->
        data = store.get @storageName, {}
        data.fuelCalcModalSize or
            top: 80
            left: $(window).width() - $('#fuel-calc').width() - 30
            width: 300
            height: 450

    saveModalSize: ->
        @checkBorders()
        div = $('#fuel-calc')
        size =
            top: div.position().top
            left: div.position().left
            width: div.width()
            height: div.height()
        data = store.get @storageName, {}
        data.fuelCalcModalSize = size
        store.set @storageName, data

#      _______   ______   .__   __.      ___   .___________. __    ______   .__   __.      _______.
#     |       \ /  __  \  |  \ |  |     /   \  |           ||  |  /  __  \  |  \ |  |     /       |
#     |  .--.  |  |  |  | |   \|  |    /  ^  \ `---|  |----`|  | |  |  |  | |   \|  |    |   (----`
#     |  |  |  |  |  |  | |  . `  |   /  /_\  \    |  |     |  | |  |  |  | |  . `  |     \   \
#     |  '--'  |  `--'  | |  |\   |  /  _____  \   |  |     |  | |  `--'  | |  |\   | .----)   |
#     |_______/ \______/  |__| \__| /__/     \__\  |__|     |__|  \______/  |__| \__| |_______/
#

# class ImRasing
#     constructor: (@key) ->
#         if not @key? then return
#         sse = new EventSource "https://imraising.tv/api/v1/listen?apikey=#{@key}"
#         sse.addEventListener 'donation.add', @add

#     add: (event) ->
#         data = JSON.parse event.data

#         currency = data.amount.display.currency
#         if currency == 'USD' then currency = '$'

#         chat.addSpecialMessage \
#             "#{currency}#{data.amount.display.total.toFixed 2} #{data.nickname}\
#             #{if data.message then ": #{data.message}" else ''}",
#             'donation'

class TwitchAlerts
    constructor: (@token) ->
        if not @token? then return
        @lastId = null
        @check()

    check: ->
        req = $.getJSON "http://#{params.host}/proxy/streamlabs/api/donations",
            access_token: @token
        , (data) =>
            if data.error?
                return
            if not data.donations.length
                @lastId = -1
            else if @lastId?
                for donation in data.donations
                    if donation.id > @lastId
                        chat.addSpecialMessage \
                            "#{donation.amount_label} #{donation.donator.name}: #{donation.message}",
                            'donation'
            for donation in data.donations
                @lastId = Math.max @lastId, donation.id
        setTimeout =>
            @check()
        , 15000

# class DonationTracker
#     constructor: (@channel, @key) ->
#         if not @channel? or not @key? then return
#         @lastTimestamp = null
#         @check()

#     check: ->
#         req = $.getJSON 'https://www.donation-tracker.com/api/',
#             channel: @channel
#             api_key: @key
#         , (data) =>
#             if data.error? or data.api_check != '1'
#                 return
#             if @lastTimestamp?
#                 for donation in data.donations
#                     if parseInt(donation.timestamp) > @lastTimestamp
#                         chat.addSpecialMessage \
#                             "#{donation.currency_symbol}#{donation.amount} #{donation.username}: #{donation.note}",
#                             'donation'
#             for donation in data.donations
#                 @lastTimestamp = Math.max @lastTimestamp, parseInt donation.timestamp
#         setTimeout =>
#             @check()
#         , 10000

#     .___________.____    __    ____  __  .___________.___________. _______ .______
#     |           |\   \  /  \  /   / |  | |           |           ||   ____||   _  \
#     `---|  |----` \   \/    \/   /  |  | `---|  |----`---|  |----`|  |__   |  |_)  |
#         |  |       \            /   |  |     |  |        |  |     |   __|  |      /
#         |  |        \    /\    /    |  |     |  |        |  |     |  |____ |  |\  \----.
#         |__|         \__/  \__/     |__|     |__|        |__|     |_______|| _| `._____|
#

class TwitterSearch
    constructor: (@id) ->
        if not @id? then return
        @requestTweets = 20
        @lastTweetId = null
        # test
        # @lastTweetId = '0'
        @fetchTweets()

    fetchTweets: ->
        twitterFetcher.fetch
            id: @id
            maxTweets: @requestTweets
            dataOnly: true
            customCallback: => @onGetTweets.apply @, arguments

    onGetTweets: (tweets) ->
        if not @lastTweetId?
            @lastTweetId = tweets[0].tid
        else
            for t in tweets.reverse()
                if t.rt then continue
                if @lastTweetId >= t.tid then continue
                @addTweet t
            $('#chat-box > .twitter a').prop 'target', '_blank'
        setTimeout =>
            @fetchTweets()
        , 5000

    addTweet: (tweet) ->
        @lastTweetId = tweet.tid
        chat.addSpecialMessage \
            "#{tweet.author}#{tweet.tweet}",
            'twitter', false

#      __  .__   __.  __  .___________.
#     |  | |  \ |  | |  | |           |
#     |  | |   \|  | |  | `---|  |----`
#     |  | |  . `  | |  |     |  |
#     |  | |  |\   | |  |     |  |
#     |__| |__| \__| |__|     |__|
#

twitchApi = new TwitchApi()
fuelCalc = new FuelCalc()
# imRaising = new ImRasing params.imRaisingLimitedKey
twitchAlerts = new TwitchAlerts params.streamLabsToken
# donationTracker = new DonationTracker params.donationTrackerChannel, params.donationTrackerKey
twitterSearch = new TwitterSearch params.twitterId
