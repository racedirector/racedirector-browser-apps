#     .______      ___      .______          ___      .___  ___.      _______.
#     |   _  \    /   \     |   _  \        /   \     |   \/   |     /       |
#     |  |_)  |  /  ^  \    |  |_)  |      /  ^  \    |  \  /  |    |   (----`
#     |   ___/  /  /_\  \   |      /      /  /_\  \   |  |\/|  |     \   \
#     |  |     /  _____  \  |  |\  \----./  _____  \  |  |  |  | .----)   |
#     | _|    /__/     \__\ | _| `._____/__/     \__\ |__|  |__| |_______/
#

params =
    bgColor: '#000000'
    bgOpacity: 30
    showEmoticons: true
    showBadges: true
    showBits: true
    bitsType: true
    bitsTheme: true
    filterBetBot: 'BatManCave'
    filterBots: 'MooBot,NightBot'
    smoothScrolling: true
    strikeOutMessages: false
    reversedMessages: false
    hideMessageAfter: 0
    showIRatings: false

for v in (window.location.search.substring 1).split '&'
    [key, val] = v.split '='
    val = decodeURIComponent val
    if !key.startsWith('channel') and /^\d+$/.test val
        val = parseInt val
    params[key] = val

# if params.test
#     params.bgOpacity = 100
#     params.showBadges = false
#     params.showBits = false

if params.filterBetBot?
    params.filterBetBot = params.filterBetBot.toLowerCase()
if params.filterBots?
    if not params.filterBots.length
        params.filterBots = null
    else
        params.filterBots = for bot in params.filterBots.split ','
            bot.trim().toLowerCase()

if params.highlightWords? and params.highlightWords
    params.highlightWords = new RegExp "(@)?\\b(#{params.highlightWords.split(',').join '|'})\\b", 'ig'

if params.hideMessageAfter?
    params.hideMessageAfter = parseInt params.hideMessageAfter
    if params.hideMessageAfter < 0 or isNaN params.hideMessageAfter
        params.hideMessageAfter = 0

#       ______  __    __       ___   .___________.
#      /      ||  |  |  |     /   \  |           |
#     |  ,----'|  |__|  |    /  ^  \ `---|  |----`
#     |  |     |   __   |   /  /_\  \    |  |
#     |  `----.|  |  |  |  /  _____  \   |  |
#      \______||__|  |__| /__/     \__\  |__|
#

chat = new TwitchChat params.channel_id or "@#{params.channel}", '#chat-box', 20, params.host

chat.init = ->
    # customizes
    if params.borderRadius?
        $('#chat-wrap').css
            borderRadius: params.borderRadius.toString().split('.').join('px ') + 'px'

    if params.margin
        $(@divId).css margin: params.margin.split('.').join('px ') + 'px'

    if params.boldText?
        $(@divId).css fontWeight: if params.boldText then 'bold' else 'normal'

    if params.bgOpacity == 0
        $(@divId).css margin: 0

    if params.textShadow
        $(@divId).css
            padding: '0 2px'
            textShadow: '
                rgba(0,0,0,0.8) 1px 1px 1px,
                rgba(0,0,0,0.8) -1px -1px 1px,
                rgba(0,0,0,0.8) 1px -1px 1px,
                rgba(0,0,0,0.8) -1px 1px 1px'

    if params.zoom
        chatStyle = $('<style type="text/css">').appendTo 'head'
        chatStyle.append "
            #{@divId} > .chat-line {
                zoom: #{params.zoom / 100};
            }"
        if params.zoom > 100
            chatStyle.append "
                #{@divId} > .chat-line > .message > .emoticon {
                    zoom: .5;
                    max-height: 56px;
                }"

    # if params.reversedMessages
    #     $(@divId).css flexDirection: 'column-reverse'

    # add blank lines, then connect
    timer = setInterval =>
        for i in [0...10]
            $('<div class="chat-line blank">&nbsp;</div>').appendTo @divId
        if $(@divId)[0].scrollHeight > $(@divId).height()
            clearInterval timer
            @scrollChat()
            # scroll down on resize
            $(window).resize =>
                requestAnimationFrame =>
                    $(@divId).stop()
                    $(@divId)[0].scrollTop = if params.reversedMessages then 0 else $(@divId)[0].scrollHeight
            queue = [
                [params.channel_id, @getChannelByID]
                [not params.channel_id, @getChannelID]
                [params.showBadges, @loadBadges]
                [params.showBadges and params.channel_id, @loadBadges, ["channels/#{@channel_id}"]]
                [params.showBits, @loadCheerEmotes]
                [params.showIRatings, @loadIRatings]
                [true, @preconnect]
            ].filter (q) -> q[0]
            queueNext = =>
                if queue.length
                    queueItem = queue.shift()
                    queueItem[1].apply @, [queueNext, queueItem[2] or []...]
                else
                    # test
                    if params.test
                        testLines = [
                            # {"username":null,"message":"Since its my 7th month subiversary can i get 7 lirikN s from chat","data":{"usernotice":true,"badges":"subscriber/6,premium/1","display-name":null,"msg-param-sub-plan":"Prime","login":"creeperslayer803","turbo":0,"mod":0,"user-id":"49262100","id":"a0d8e6e1-c1c3-45a0-9862-f5c7c456288b","msg-param-months":"7","room-id":"23161357","msg-id":"resub","system-msg":"creeperslayer803 just subscribed with Twitch Prime. creeperslayer803 subscribed for 7 months in a row!","color":null,"emotes":"96286:47-52","msg-param-sub-plan-name":"Channel Subscription (LIRIK)","tmi-sent-ts":"1493490407549","user-type":null,"subscriber":1}}
                            # {"username":"twitchnotify","message":"taytoes93 just subscribed with Twitch Prime!","data":{}}
                            # {"username":null,"message":"LUV ME DADDY PogChamp","data":{"usernotice":true,"badges":"subscriber/0","display-name":"f00d_p0rn420","msg-param-sub-plan":"1000","login":"f00d_p0rn420","turbo":0,"mod":0,"user-id":"126830175","id":"f53563b6-8133-4d89-a47a-1a1915de78f3","msg-param-months":1,"room-id":"23161357","msg-id":"sub","system-msg":"f00d_p0rn420 just subscribed with a $4.99 sub!","color":"#FF69B4","emotes":"88:13-20","msg-param-sub-plan-name":"Channel Subscription (LIRIK)","tmi-sent-ts":"1493485519519","user-type":null,"subscriber":1}}
                            # {"username":"babycakeswaffle","message":"Tiago lirikCHAMP lirikHug geersH waffleLove lirikH :P /","data":{"room-id":"23161357","turbo":0,"id":"58eaab37-aa63-4e60-ab27-d36f5302068e","mod":1,"badges":"moderator/1,subscriber/24","user-type":"mod","user-id":"40316546","subscriber":1,"color":"#7E2F9D","emotes":"50741:6-15/29049:17-24/65079:26-31/49868:33-42/15020:44-49/12:51-52","display-name":"Babycakeswaffle"}}
                            # {"username":"mucx","message":"cheer100 here yo go baby grill","data":{"room-id":"23161357","user-id":"744132","id":"e63fdfbe-d526-42c1-b984-ca9d067deaca","bits":"100","color":"#6120AC","subscriber":1,"turbo":1,"emotes":null,"mod":0,"badges":"staff/1,subscriber/24,turbo/1","user-type":"staff","display-name":"Mucx"}}
                            # {"username":null,"message":null,"data":{"usernotice":true,"badges":"subscriber/3","display-name":"TortoiseHelmet","msg-param-sub-plan":"1000","login":"tortoisehelmet","turbo":0,"mod":0,"user-id":"56128718","id":"9873e399-18ad-4c29-997f-10bddfdc3aa3","msg-param-months":"3","room-id":"23161357","msg-id":"resub","system-msg":"TortoiseHelmet subscribed for 3 months in a row!","color":"#738A42","emotes":null,"msg-param-sub-plan-name":"Channel Subscription","tmi-sent-ts":"1493485406901","user-type":null,"subscriber":1}}
                            # {"username":null,"message":"you earned it, fucking epic man.","data":{"usernotice":true,"badges":"subscriber/0,premium/1","display-name":null,"msg-param-sub-plan":"3000","login":"kilyin74","turbo":0,"mod":0,"user-id":"36264874","id":"0877a6b1-ad2f-411e-8a77-1c6bda0eaa7a","msg-param-months":1,"room-id":"23161357","msg-id":"sub","system-msg":"kilyin74 just subscribed with a $24.99 sub!","color":"#1940B3","emotes":null,"msg-param-sub-plan-name":"Channel Subscription (LIRIK): $24.99 Sub","tmi-sent-ts":"1493488925976","user-type":null,"subscriber":1}}
                            # {"username":"thesalamanda","message":"Tiago lirikCHAMP lirikHug geersH waffleLove lirikH :P /","data":{"room-id":"23161357","turbo":0,"id":"58eaab37-aa63-4e60-ab27-d36f5302068e","mod":1,"badges":"moderator/1,subscriber/24","user-type":"mod","user-id":"40316546","subscriber":1,"color":"#7E2F9D","emotes":"50741:6-15/29049:17-24/65079:26-31/49868:33-42/15020:44-49/354:51-52","display-name":"고르도나"}}
                            # {"username":null,"message":null,"data":{"usernotice":true,"badges":"subscriber/0","display-name":"f00d_p0rn420","msg-param-sub-plan":"1000","login":"f00d_p0rn420","turbo":0,"mod":0,"user-id":"126830175","id":"f53563b6-8133-4d89-a47a-1a1915de78f3","msg-param-months":1,"room-id":"23161357","msg-id":"subgift","system-msg":"TWW2 gifted a Tier 1 sub to Mr_Woodchuck!","color":"#FF69B4","emotes":"88:13-20","msg-param-sub-plan-name":"Channel Subscription (LIRIK)","tmi-sent-ts":"1493485519519","user-type":null,"subscriber":1,"msg-param-recipient-display-name":"Mr_Woodchuck","msg-param-recipient-name":"mr_woodchuck"}}
                            # {"username":"babycakeswaffle","message":"qwe KutU zxc kutu182 asd /","data":{"room-id":"23161357","turbo":0,"id":"58eaab37-aa63-4e60-ab27-d36f5302068e","mod":1,"badges":"moderator/1,subscriber/24","user-type":"mod","user-id":"40316546","subscriber":1,"color":"#7E2F9D","emotes":null,"display-name":"Babycakeswaffle"}}
                            # {"username":"babycakeswaffle","message":"qwe asd /","data":{"room-id":"23161357","turbo":0,"id":"58eaab37-aa63-4e60-ab27-d36f5302068e","mod":1,"badges":"moderator/1,subscriber/24","user-type":"mod","user-id":"40316546","subscriber":1,"color":"#7E2F9D","emotes":null,"display-name":"Babycakeswaffle"}}
                            # {"username":"babycakeswaffle","message":"qwe @kutu182. asd /","data":{"room-id":"23161357","turbo":0,"id":"58eaab37-aa63-4e60-ab27-d36f5302068e","mod":1,"badges":"moderator/1,subscriber/24","user-type":"mod","user-id":"40316546","subscriber":1,"color":"#7E2F9D","emotes":null,"display-name":"Babycakeswaffle"}}
                            # {"username":"babycakeswaffle","message":"qwe asd /","data":{"room-id":"23161357","turbo":0,"id":"58eaab37-aa63-4e60-ab27-d36f5302068e","mod":1,"badges":"moderator/1,subscriber/24","user-type":"mod","user-id":"40316546","subscriber":1,"color":"#7E2F9D","emotes":null,"display-name":"Babycakeswaffle"}}
                            # {"username":"babycakeswaffle","message":"qwe mihail asd /","data":{"room-id":"23161357","turbo":0,"id":"58eaab37-aa63-4e60-ab27-d36f5302068e","mod":1,"badges":"moderator/1,subscriber/24","user-type":"mod","user-id":"40316546","subscriber":1,"color":"#7E2F9D","emotes":null,"display-name":"Babycakeswaffle"}}
                            # {"username":"babycakeswaffle","message":"qwe asd /","data":{"room-id":"23161357","turbo":0,"id":"58eaab37-aa63-4e60-ab27-d36f5302068e","mod":1,"badges":"moderator/1,subscriber/24","user-type":"mod","user-id":"40316546","subscriber":1,"color":"#7E2F9D","emotes":null,"display-name":"Babycakeswaffle"}}
                            # {"username":"cyborg_v7","message":"Cheer100","data":{"room-id":"23161357","user-id":"30857246","id":"16c25afc-c950-4089-8aa7-8011a1cf2aea","bits":"100","color":"#0000FF","subscriber":1,"turbo":0,"emotes":null,"mod":0,"badges":"subscriber/12","user-type":null,"display-name":"Cyborg_V7"}}
                            # highlighted message
                            # {"username":"kutu182","message":"willplZ_TK","data":{"badge-info":null,"badges":"moderator/1","color":"#008000","display-name":"kutu182","emote-only":1,"emotes":"2129980_TK:0-9","flags":null,"id":"bf080b6d-d254-4b90-baee-69ad7b332a11","mod":1,"room-id":"45794203","subscriber":0,"tmi-sent-ts":"1575563011598","turbo":0,"user-id":"26361988","user-type":"mod"}}
                            # {"username":"kutu182","message":"test 2 kutu18C","data":{"badge-info":null,"badges":"moderator/1","color":"#008000","display-name":"kutu182","emotes":"300282543:7-13","flags":null,"id":"ab7b218d-21ab-4396-8d8c-924eb70c61e0","mod":1,"msg-id":"highlighted-message","room-id":"45794203","subscriber":0,"tmi-sent-ts":"1575561872192","turbo":0,"user-id":"26361988","user-type":"mod"}}
                            # {"username":"kutu182","message":"test 2 kutu18C","data":{"badge-info":null,"badges":"moderator/1","color":"#008000","display-name":"kutu182","emotes":"300282543:7-13","flags":null,"id":"ab7b218d-21ab-4396-8d8c-924eb70c61e0","mod":1,"msg-id":"highlighted-message","room-id":"45794203","subscriber":0,"tmi-sent-ts":"1575561872192","turbo":0,"user-id":"26361988","user-type":"mod"}}
                            # # modified emote
                            # {"username":"kutu182","message":"willplZ_TK","data":{"badge-info":null,"badges":"moderator/1","color":"#008000","display-name":"kutu182","emote-only":1,"emotes":"2129980_TK:0-9","flags":null,"id":"bf080b6d-d254-4b90-baee-69ad7b332a11","mod":1,"room-id":"45794203","subscriber":0,"tmi-sent-ts":"1575563011598","turbo":0,"user-id":"26361988","user-type":"mod"}}
                            # {"username":null,"message":null,"data":{"badge-info":null,"badges":"premium/1","color":"#850000","display-name":"Flip8383","emotes":null,"flags":null,"id":"f64c5e3a-f52b-4c0a-9183-11e62c3672bd","login":"flip8383","mod":0,"msg-id":"resub","msg-param-cumulative-months":"57","msg-param-months":0,"msg-param-should-share-streak":0,"msg-param-sub-plan-name":"Channel Subscription (LIRIK)","msg-param-sub-plan":"Prime","room-id":"23161357","subscriber":1,"system-msg":"Flip8383 subscribed with Twitch Prime. They've subscribed for 57 months!","tmi-sent-ts":"1575652956377","user-id":"80564008","user-type":null,"usernotice":true}}
                            # # custom reward
                            # {"username":"kutu182","message":"test3","data":{"badge-info":null,"badges":"moderator/1","color":"#008000","custom-reward-id":"7a592aa5-1987-48c7-be25-ab9f3eff9858","display-name":"kutu182","emotes":null,"flags":null,"id":"eedd0295-81ae-45b3-abf8-62aa974812c4","mod":1,"room-id":"45794203","subscriber":0,"tmi-sent-ts":"1575653514885","turbo":0,"user-id":"26361988","user-type":"mod"}}
                            # {"username":null,"message":null,"data":{"badge-info":null,"badges":null,"color":"#00FF7F","display-name":"Zonear","emotes":null,"flags":null,"id":"bb38219f-a508-4638-9b6f-aca8e84408f9","login":"zonear","mod":0,"msg-id":"rewardgift","msg-param-domain":"megacommerce_2019","msg-param-selected-count":"5","msg-param-total-reward-count":"5","msg-param-trigger-amount":1,"msg-param-trigger-type":"SUBSCRIPTION","room-id":"26610234","subscriber":1,"system-msg":"Zonear's Sub shared rewards to 5 others in Chat!","tmi-sent-ts":"1575812023735","user-id":"100814342","user-type":null,"usernotice":true}}
                            # # prime no message
                            # {"username":null,"message":null,"data":{"badge-info":null,"badges":null,"color":null,"display-name":"Lockl34d","emotes":null,"flags":null,"id":"419e3cc4-c9b7-4abb-b3c1-0751e26d803e","login":"lockl34d","mod":0,"msg-id":"sub","msg-param-cumulative-months":1,"msg-param-months":0,"msg-param-should-share-streak":0,"msg-param-sub-plan-name":"Channel Subscription (kutu182)","msg-param-sub-plan":"Prime","room-id":"26361988","subscriber":1,"system-msg":"Lockl34d subscribed with Twitch Prime.","tmi-sent-ts":"1582977696188","user-id":"56299357","user-type":null,"usernotice":true}}
                            # # prime resub no message
                            # {"username":null,"message":null,"data":{"badge-info":"subscriber/12","badges":"subscriber/12,premium/1","color":"#8A2BE2","display-name":"shizzynizzlebits","emotes":null,"flags":null,"id":"9f6aedf7-47ad-4623-8884-3e77323d66e7","login":"shizzynizzlebits","mod":0,"msg-id":"resub","msg-param-cumulative-months":"12","msg-param-months":0,"msg-param-should-share-streak":1,"msg-param-streak-months":"2","msg-param-sub-plan-name":"Channel Subscription (LIRIK)","msg-param-sub-plan":"Prime","room-id":"23161357","subscriber":1,"system-msg":"shizzynizzlebits subscribed with Twitch Prime. They've subscribed for 12 months, currently on a 2 month streak!","tmi-sent-ts":"1582574748625","user-id":"116139856","user-type":null,"usernotice":true}}
                            # # tier 1 resub with message
                            # {"username":null,"message":"Hi Y'all","data":{"badge-info":"subscriber/67","badges":"subscriber/60","color":"#00FF7F","display-name":"AkameGaKill_Plz","emotes":null,"flags":null,"id":"bf5c5d35-53f9-48ca-a1ad-877d6e4cdb45","login":"akamegakill_plz","mod":0,"msg-id":"resub","msg-param-cumulative-months":"67","msg-param-months":0,"msg-param-should-share-streak":1,"msg-param-streak-months":"67","msg-param-sub-plan-name":"Channel Subscription (LIRIK)","msg-param-sub-plan":"1000","room-id":"23161357","subscriber":1,"system-msg":"AkameGaKill_Plz subscribed at Tier 1. They've subscribed for 67 months, currently on a 67 month streak!","tmi-sent-ts":"1582574745119","user-id":"69407216","user-type":null,"usernotice":true}}
                            # # sindre irating badge test
                            # {"username":"core_sindre","message":"xD","data":{"badge-info":null,"badges":null,"color":null,"display-name":"CORE_Sindre","emotes":null,"flags":null,"id":"738e19ad-d607-4652-b1c4-80e34837b235","mod":0,"room-id":"58573771","subscriber":0,"tmi-sent-ts":"1584804044296","turbo":0,"user-id":"52616400","user-type":null}}
                            # # animated emote
                            # {"username":"ziivv_","message":"Nostoroth lirikWavy","data":{"badge-info":"subscriber/11","badges":"subscriber/6,glitchcon2020/1","client-nonce":"08542fea73fe7ce1117c27c1dad96c48","color":"#DAA520","display-name":"Ziivv_","emotes":"emotesv2_5c009ac072684d9fa6a251db4fa5222e:10-18","flags":null,"id":"7fdef5b1-e275-4598-b93a-1cf034135e9c","mod":0,"room-id":"23161357","subscriber":1,"tmi-sent-ts":"1624461506265","turbo":0,"user-id":"197933298","user-type":null}}
                            # {"username":"ribsicles","message":"lirikCozysip lirikCozysip lirikCozysip","data":{"badge-info":"subscriber/11","badges":"subscriber/6,premium/1","client-nonce":"0c86773d32daa3bb7fd33c73173e4ab2","color":null,"display-name":"ribsicles","emote-only":1,"emotes":"emotesv2_33e4c19c71dd40e7b3e8220aa6bdb4ba:0-11,13-24,26-37","flags":null,"id":"e90eb725-93d2-4a7d-85c5-7c72980b92e6","mod":0,"room-id":"23161357","subscriber":1,"tmi-sent-ts":"1624461838755","turbo":0,"user-id":"509883750","user-type":null}}
                            # /me
                            {"username":"kutu182","message":"test","data":{"badge-info":null,"badges":"moderator/1","color":"#008000","display-name":"kutu182","emotes":null,"flags":null,"id":"ab593043-31a9-45fe-ac43-96bb5a44312d","mod":1,"room-id":"64721139","subscriber":0,"tmi-sent-ts":"1624462490687","turbo":0,"user-id":"26361988","user-type":"mod","action":true}}
                        ]
                        for l in testLines then @onmessage l.username, l.message, l.data
                        # setTimeout =>
                        #     l = {"username":null,"message":null,"data":{"badge-info":null,"badges":null,"color":null,"display-name":"Lockl34d","emotes":null,"flags":null,"id":"419e3cc4-c9b7-4abb-b3c1-0751e26d803e","login":"lockl34d","mod":0,"msg-id":"sub","msg-param-cumulative-months":1,"msg-param-months":0,"msg-param-should-share-streak":0,"msg-param-sub-plan-name":"Channel Subscription (kutu182)","msg-param-sub-plan":"Prime","room-id":"26361988","subscriber":1,"system-msg":"Lockl34d subscribed with Twitch Prime.","tmi-sent-ts":"1582977696188","user-id":"56299357","user-type":null,"usernotice":true}}
                        #     @onmessage l.username, l.message, l.data
                        # , 1000
                        # setInterval =>
                        #     # l = testLines[Math.round Math.random() * (testLines.length - 1)]
                        #     l = {"username":"kutu182","message":"test3","data":{"badge-info":null,"badges":"moderator/1","color":"#008000","custom-reward-id":"7a592aa5-1987-48c7-be25-ab9f3eff9858","display-name":"kutu182","emotes":null,"flags":null,"id":"eedd0295-81ae-45b3-abf8-62aa974812c4","mod":1,"room-id":"45794203","subscriber":0,"tmi-sent-ts":"1575653514885","turbo":0,"user-id":"26361988","user-type":"mod"}}
                        #     @onmessage l.username, l.message, l.data
                        # , 300
            queueNext()
    , 1

chat.preconnect = (callback) ->
    setTimeout =>
        if params.bgOpacity?
            $('#chat-wrap').css background: "rgba(
                #{parseInt params.bgColor[1..2], 16},
                #{parseInt params.bgColor[3..4], 16},
                #{parseInt params.bgColor[5..6], 16},
                #{params.bgOpacity / 100})"
        setTimeout =>
            @connect callback
        , 500
    , 100

chat.onmessage = (username, message, data={}) ->
    # if data.usernotice or data.pubnotice or username == 'twitchnotify'
    #     console.log username, message, data
    # console.log JSON.stringify
    #     username: username
    #     message: message
    #     data: data

    # check version
    if not @versionChecked and data.version
        @versionChecked = true
        if data.version < 14
            username = 'twitchnotify'
            message = 'Update apps, run update.exe or download it from ir-apps.kutu.ru'
            delete @onmessage

    if data.clearchat
        @clearChat message, params.strikeOutMessages
        if message
            username = 'twitchnotify'
            if data['ban-duration']?
                message = "#{message} has been timed out for #{data['ban-duration']} seconds."
            else
                message = "#{message} is now banned from this room."
            if data['ban-reason']
                message += " Reason: #{data['ban-reason']}."

    if not data.pubnotice and not data.usernotice
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

    # reward
    if data['msg-id'] == 'rewardgift' or data['custom-reward-id']
        newLine = $ '<div>'
        newLine.addClass 'chat-line reward'
        formattedMessage = $ '<span>'
        formattedMessage.addClass 'message'
        switch
            when data['custom-reward-id']
                formattedMessage.text 'Redeemed a custom reward'
            when data['msg-id'] == 'rewardgift'
                formattedMessage.text message or data['system-msg']
        newLine.append formattedMessage
        headerNewLine = newLine
        if data['msg-id'] == 'rewardgift'
            @addLine newLine
            @scrollChat()
            return
    # notify
    else if data.pubnotice or data.usernotice or username == 'twitchnotify'
        newLine = $ '<div>'
        newLine.addClass 'chat-line notify'
        formattedMessage = $ '<span>'
        formattedMessage.addClass 'message'
        formattedMessage.text data['system-msg'] or message
        newLine.append formattedMessage
        headerNewLine = newLine
        # sub / resub
        if data.usernotice and data['msg-id'] in ['sub', 'resub', 'subgift']
            username = data.login
            newLine.addClass 'sub'
        else
            @addLine newLine
            @scrollChat()
            return

    # filter emotes spam
    if params.antiEmotesSpam and @checkEmotesSpam message, data, params.antiEmotesSpam
        return

    data.color ?= @nameToColor username

    newLine = $ '<div>'
    newLine.attr 'data-username', username
    newLine.addClass 'chat-line'

    # irating badge
    if params.showIRatings
        wcDriver = @getWCByUserID data['user-id']
        # test
        # wcDriver = irating: 5900
        if wcDriver?
            tag = $ '<span>'
            tag.addClass 'irating-badge'
            tag.text "#{((wcDriver.irating / 100 | 0) / 10).toFixed 1}#{if wcDriver.irating >= 10000 then '' else 'k'}"
            newLine.append tag

    window.customBadge? data, newLine

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

    data.color = @calculateColor data.color

    # sub / resub
    if data.usernotice and data['msg-id'] in ['sub', 'resub', 'subgift']
        newLine.addClass 'sub'

    # highlighted message
    if data['msg-id'] == 'highlighted-message'
        newLine.addClass 'highlighted-message'

    # custom reward
    if data['custom-reward-id']
        newLine.addClass 'reward'

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
        # formattedMessage.css 'color', data.color
        formattedMessage.css 'fontStyle', 'italic'
    if params.showEmoticons
        if params.zoom > 100
            message = @emoticonize message, data, false, '2.0'
        else
            message = @emoticonize message, data
    if params.showBits and data.bits? and data.bits > 0
        [message, bg] = @bitonize message, data.bits, params.bitsType, params.bitsTheme, if params.zoom > 100 then '2' else '1'
        newLine.addClass 'cheer'
        newLine.css borderLeftColor: bg
    if params.highlightWords
        message = @highlightWords message, params.highlightWords
    formattedMessage.html message
    newLine.append formattedMessage

    if headerNewLine and not params.reversedMessages then @addLine headerNewLine
    if message then @addLine newLine
    if headerNewLine and params.reversedMessages then @addLine headerNewLine

    # scroll after all images loaded
    messageImages = formattedMessage.find 'img'
    imagesCount = messageImages.length
    if imagesCount
        scrollHeight = $(@divId)[0].scrollHeight
        messageImages.on 'load error', onMessageImages = =>
            h = $(@divId)[0].scrollHeight
            if scrollHeight < h
                scrollHeight = h
                @scrollChat()
            if not --imagesCount
                messageImages.off 'load error', onMessageImages
    @scrollChat()

chat.addLine = (newLine) ->
    if params.reversedMessages
        newLine.prependTo @divId
        if params.smoothScrolling
            el = $(@divId)
            if el[0].scrollTop == 0
                el[0].scrollTop += newLine.height()
    else
        newLine.appendTo @divId
    @hideMessageAfter newLine[0]

chat.scrollChat = ->
    el = $(@divId)
    if params.smoothScrolling
        el.stop()
        el.animate
            scrollTop: if params.reversedMessages then 0 else el[0].scrollHeight - el.height(),
            200, 'linear', => @clearHiddenMessages()
    else
        el[0].scrollTop = if params.reversedMessages then 0 else el[0].scrollHeight
        @clearHiddenMessages()

chat.clearHiddenMessages = ->
    wrapHeight = $(@divId).height()
    for item in $ "#{@divId} > div:not(.blank)"
        item = $(item)
        item.stop()
        if params.reversedMessages
            if item.position().top >= 3 * wrapHeight
                item.remove()
        else if item.position().top < -wrapHeight
            item.remove()
        else
            break

chat.hideMessageAfter = (el) ->
    if not params.hideMessageAfter then return
    el.animate [
        {opacity: 1}
        {opacity: 0}
    ],
        duration: 400
        delay: params.hideMessageAfter * 1000
        fill: 'forwards'

chat.init()
