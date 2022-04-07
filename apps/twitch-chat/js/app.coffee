app = angular.module 'twitch-chat', [
    'twitch-chat-channel'
    'ngRoute'
    'mgcrea.ngStrap.navbar'
    'LocalStorageModule'
    'kutu.markdown'
    'selectize'
]

app.config ($routeProvider) ->
    $routeProvider
        .when '/',
            templateUrl: 'tmpl/index.html'
        .when '/settings',
            templateUrl: 'tmpl/settings.html'
            controller: 'SettingsCtrl'
            title: 'Settings'
        .otherwise redirectTo: '/'

app.config (localStorageServiceProvider) ->
    localStorageServiceProvider.setPrefix app.name

app.run ($rootScope, $sce) ->
    $rootScope.$on '$routeChangeSuccess', (event, current, previous) ->
        title = 'Twitch Chat &middot; iRacing Browser Apps'
        if current.$$route.title?
            title = current.$$route.title + ' &middot; ' + title
        $rootScope.title = $sce.trustAsHtml title

#          _______. _______ .___________.___________. __  .__   __.   _______      _______.
#         /       ||   ____||           |           ||  | |  \ |  |  /  _____|    /       |
#        |   (----`|  |__   `---|  |----`---|  |----`|  | |   \|  | |  |  __     |   (----`
#         \   \    |   __|      |  |        |  |     |  | |  . `  | |  | |_ |     \   \
#     .----)   |   |  |____     |  |        |  |     |  | |  |\   | |  |__| | .----)   |
#     |_______/    |_______|    |__|        |__|     |__| |__| \__|  \______| |_______/
#

app.controller 'SettingsCtrl', ($scope, localStorageService) ->
    defaultSettings =
        host: ''
        channel_id: ''
        bgColor: '#000000'
        bgOpacity: 30
        borderRadiusEach: false
        borderRadius1: 6
        borderRadius2: 6
        borderRadius3: 6
        borderRadius4: 6
        borderRadius: '6'
        boldText: true
        textShadow: false
        zoom: 100
        margin1: 2
        margin2: 4
        margin: '2.4'
        showEmoticons: true
        showBadges: true
        showBits: true
        bitsType: true
        bitsTheme: true
        filterBetBot: 'BatManCave'
        filterBots: ['MooBot', 'NightBot']
        smoothScrolling: true
        strikeOutMessages: false
        highlightWords: []
        reversedMessages: false
        hideMessageAfter: 0
        showIRatings: false

    $scope.settings = settings = localStorageService.get('settings') or {}
    for p of defaultSettings
        if p not of settings
            settings[p] = defaultSettings[p]

    if not settings.channel_id and settings.channel
        $scope.$applyAsync ->
            $scope.channel settings.channel

    $scope.saveSettings = saveSettings = ->
        settings.bgOpacity = parseInt settings.bgOpacity
        settings.zoom = parseInt settings.zoom

        if settings.bgOpacity
            # border radius
            settings.borderRadius = if not settings.borderRadiusEach
                "#{settings.borderRadius1}"
            else
                "#{settings.borderRadius1}.#{settings.borderRadius2}.#{settings.borderRadius3}.#{settings.borderRadius4}"
            # margin
            settings.margin = "#{settings.margin1}.#{settings.margin2}"

        chat.updateSettings()
        localStorageService.set 'settings', settings
        updateURL()

    actualKeys = [
        'host'
        'channel_id'
        'bgColor'
        'bgOpacity'
        'borderRadius'
        'boldText'
        'textShadow'
        'zoom'
        'margin'
        'showEmoticons'
        'showBadges'
        'showBits'
        'bitsType'
        'bitsTheme'
        'filterBetBot'
        'filterBots'
        'smoothScrolling'
        'strikeOutMessages'
        'highlightWords'
        'reversedMessages'
        'hideMessageAfter'
        'showIRatings'
    ]

    do updateURL = ->
        keys = actualKeys.filter (k) ->
            if not settings.bgOpacity and k in ['bgColor', 'borderRadius', 'margin'] then false
            else if not settings.showBits and k in ['bitsType', 'bitsTheme'] then false
            else true
        params = []
        for k, v of settings
            if k of defaultSettings and (
                v == defaultSettings[k] or \
                (
                    angular.isArray(v) and angular.isArray(defaultSettings[k]) \
                    and v.toString() == defaultSettings[k].toString()
                )
                ) then continue
            if k == 'host' and not v? then continue
            if v == '' and v == defaultSettings[k] then continue
            if typeof v is 'boolean'
                v = if v then 1 else 0
            if k in keys
                params.push "#{k}=#{encodeURIComponent v}"
        localRx = /^(localhost|127\.0\.0\.1)(:|$)/
        canUseHttps = (not settings.host or localRx.test settings.host) and not localRx.test document.location.host
        $scope.url = "http#{if canUseHttps then 's' else ''}://#{document.location.host}/twitch-chat/chat.html\
            #{if params.length then '?' + params.join '&' else ''}"

    # chat preview
    chatLines = [
        # {"username":"larryfromsupraball","message":"CoolCat CoolCat CoolCat","data":{"room-id":"23161357","turbo":0,"id":"1fb9bca2-5cc3-413a-b9d7-2f0f1d0e31a6","mod":0,"badges":"subscriber/12,bits/100","user-type":null,"user-id":"63626498","subscriber":1,"color":"#DAA520","emotes":"58127:0-6,8-14,16-22","display-name":"LARRYfromsupraball"}}
        # {"username":"jeff3231","message":"sup","data":{"room-id":"23161357","turbo":0,"id":"26a76b27-9b67-450f-8d2f-182e47c1f175","mod":0,"badges":"bits/100","user-type":null,"user-id":"43981078","subscriber":0,"color":"#FF69B4","emotes":null,"display-name":"Jeff3231"}}
        # {"username":null,"message":null,"data":{"room-id":"23161357","user-id":"22732193","color":null,"user-type":null,"system-msg":"Recti1 subscribed for 3 months in a row!","usernotice":true,"display-name":"Recti1","turbo":0,"emotes":null,"mod":0,"badges":"subscriber/6","login":"recti1","msg-id":"resub","subscriber":1,"msg-param-months":"3"}}
        # {"username":"reifiedash","message":"cheer10000","data":{"room-id":"23161357","user-id":"60060664","id":"7ee15913-81dd-4e48-b73c-a1a96d348db9","bits":"10000","color":"#5F9EA0","subscriber":1,"turbo":0,"emotes":null,"mod":0,"badges":"subscriber/6","user-type":null,"display-name":"ReifiedAsh"}}
        # {"username":"twitchnotify","message":"taytoes93 just subscribed with Twitch Prime!","data":{}}
        # {"username":null,"message":"LUV ME DADDY PogChamp","data":{"usernotice":true,"badges":"subscriber/0","display-name":"f00d_p0rn420","msg-param-sub-plan":"1000","login":"f00d_p0rn420","turbo":0,"mod":0,"user-id":"126830175","id":"f53563b6-8133-4d89-a47a-1a1915de78f3","msg-param-months":1,"room-id":"23161357","msg-id":"sub","system-msg":"f00d_p0rn420 just subscribed with a $4.99 sub!","color":"#FF69B4","emotes":"88:13-20","msg-param-sub-plan-name":"Channel Subscription (LIRIK)","tmi-sent-ts":"1493485519519","user-type":null,"subscriber":1}}
        # {"username":null,"message":null,"data":{"usernotice":true,"badges":"subscriber/3","display-name":"TortoiseHelmet","msg-param-sub-plan":"1000","login":"tortoisehelmet","turbo":0,"mod":0,"user-id":"56128718","id":"9873e399-18ad-4c29-997f-10bddfdc3aa3","msg-param-months":"3","room-id":"23161357","msg-id":"resub","system-msg":"TortoiseHelmet subscribed for 3 months in a row!","color":"#738A42","emotes":null,"msg-param-sub-plan-name":"Channel Subscription","tmi-sent-ts":"1493485406901","user-type":null,"subscriber":1}}
        # {"username":null,"message":"you earned it, fucking epic man.","data":{"usernotice":true,"badges":"subscriber/0,premium/1","display-name":null,"msg-param-sub-plan":"3000","login":"kilyin74","turbo":0,"mod":0,"user-id":"36264874","id":"0877a6b1-ad2f-411e-8a77-1c6bda0eaa7a","msg-param-months":1,"room-id":"23161357","msg-id":"sub","system-msg":"kilyin74 just subscribed with a $24.99 sub!","color":"#1940B3","emotes":null,"msg-param-sub-plan-name":"Channel Subscription (LIRIK): $24.99 Sub","tmi-sent-ts":"1493488925976","user-type":null,"subscriber":1}}
        # {"username":null,"message":null,"data":{"badge-info":"subscriber/4","badges":"subscriber/3,premium/1","color":"#19B3AD","display-name":"NearSingularity","emotes":null,"flags":null,"id":"7c55ee0b-4445-47f0-bd6a-712b8fcab21a","login":"nearsingularity","mod":0,"msg-id":"submysterygift","msg-param-mass-gift-count":"5","msg-param-origin-id":"00 0a 1c b8 95 bc ce 72 c2 d4 08 74 72 f1 ae 3e 6c d2 0f 14","msg-param-sender-count":"25","msg-param-sub-plan":"1000","room-id":"14408894","subscriber":1,"system-msg":"NearSingularity is gifting 5 Tier 1 Subs to LIRIK's community! They've gifted a total of 25 in the channel!","tmi-sent-ts":"1566727122014","user-id":"54648656","user-type":null,"usernotice":true}}

        {"username":"reloadinko","message":"hacked The Golden Badge to every sub on this channel","data":{"room-id":"23161357","user-id":"72862080","id":"cd76a78c-4f2b-4927-ab5b-1f14f9397264","emotes":null,"display-name":"Reloadinko","turbo":1,"color":"#00FF7F","mod":0,"badges":"subscriber/0,turbo/1","user-type":null,"subscriber":1,"action":true}}
        {"username":"cburson","message":"finally a good stream","data":{"room-id":"23161357","turbo":1,"id":"76f5887f-c5a6-4415-b938-bc102bab2560","mod":0,"badges":"subscriber/3,bits/100000","user-type":null,"user-id":"29930451","subscriber":1,"color":"#CF902A","emotes":null,"display-name":"cburson"}}
        {"username":"mucx","message":"cheer100 here yo go baby grill","data":{"room-id":"23161357","user-id":"744132","id":"e63fdfbe-d526-42c1-b984-ca9d067deaca","bits":"100","color":"#6120AC","subscriber":1,"turbo":1,"emotes":null,"mod":0,"badges":"staff/1,subscriber/24,turbo/1","user-type":"staff","display-name":"Mucx"}}
        {"username":"cyborg_v7","message":"cheer1000","data":{"room-id":"23161357","user-id":"30857246","id":"16c25afc-c950-4089-8aa7-8011a1cf2aea","bits":"1000","color":"#0000FF","subscriber":1,"turbo":0,"emotes":null,"mod":0,"badges":"subscriber/12","user-type":null,"display-name":"Cyborg_V7"}}
        {"username":"zetless","message":"Just go read all the lore if you want a league mmo","data":{"badge-info":"subscriber/27","badges":"vip/1,subscriber/24,bits/5000","color":"#DAA520","display-name":"Zetless","emotes":null,"flags":null,"id":"3e050741-99b1-41e1-a018-b6e023d47f2e","mod":0,"room-id":"23161357","subscriber":1,"tmi-sent-ts":"1566740571061","turbo":0,"user-id":"45894824","user-type":null}}
        {"username":"xfilosofem","message":"I'm waitng for sub sunday","data":{"badge-info":"subscriber/13","badges":"subscriber/12,premium/1","color":"#707BC8","display-name":"xFilosofem","emotes":null,"flags":null,"id":"239ac8a8-00fa-496b-9781-65e0ab07e178","mod":0,"room-id":"23161357","subscriber":1,"tmi-sent-ts":"1566742597357","turbo":0,"user-id":"61941001","user-type":null}}
        {"username":"omerozdemir","message":"lirikA lirikPHONE Hello Chat","data":{"badge-info":"subscriber/6","badges":"subscriber/6","color":"#FF0000","display-name":"OmerOzdemir","emotes":"300359268:0-5/2095592:7-16","flags":null,"id":"b56d924e-15ca-4458-8e63-53fe69948570","mod":0,"room-id":"23161357","subscriber":1,"tmi-sent-ts":"1566747334397","turbo":0,"user-id":"145335108","user-type":null}}
        {"username":null,"message":"lirikD","data":{"badge-info":"subscriber/52","badges":"subscriber/48,bits/1000","color":"#0000FF","display-name":"SmackDE","emotes":"1771989:0-5","flags":null,"id":"acaff1b9-91c3-4eb6-90dd-93a88324b957","login":"smackde","mod":0,"msg-id":"resub","msg-param-cumulative-months":"52","msg-param-months":0,"msg-param-should-share-streak":1,"msg-param-streak-months":"52","msg-param-sub-plan-name":"Channel Subscription (LIRIK)","msg-param-sub-plan":"1000","room-id":"23161357","subscriber":1,"system-msg":"SmackDE subscribed at Tier 1. They've subscribed for 52 months, currently on a 52 month streak!","tmi-sent-ts":"1566746984126","user-id":"91884727","user-type":null,"usernotice":true}}
        {"username":null,"message":"johnybrahvo","data":{"ban-duration":"69","room-id":"23161357","target-user-id":"56158823","tmi-sent-ts":"1566750709743","clearchat":true}}
        {"username":"umara_samura_2077","message":"lirikCHAMP its looping","data":{"badge-info":"subscriber/10","badges":"subscriber/6,premium/1","color":"#FF69B4","display-name":"umara_samura_2077","emotes":"1795152:0-9","flags":null,"id":"22077627-a723-4c16-95eb-d419a03bc603","mod":0,"room-id":"23161357","subscriber":1,"tmi-sent-ts":"1566750995160","turbo":0,"user-id":"162292862","user-type":null}}
        {"username":null,"message":"Pogileeee","data":{"badge-info":"subscriber/2","badges":"subscriber/0,premium/1","color":null,"display-name":"RyFrizz","emotes":null,"flags":null,"id":"e6f7cddf-b5b7-4f56-aa32-3b1f4794ddf4","login":"ryfrizz","mod":0,"msg-id":"resub","msg-param-cumulative-months":"2","msg-param-months":0,"msg-param-should-share-streak":1,"msg-param-streak-months":1,"msg-param-sub-plan-name":"Channel Subscription (LIRIK)","msg-param-sub-plan":"Prime","room-id":"23161357","subscriber":1,"system-msg":"RyFrizz subscribed with Twitch Prime. They've subscribed for 2 months, currently on a 1 month streak!","tmi-sent-ts":"1566751034958","user-id":"145062084","user-type":null,"usernotice":true}}
        {"username":"fossabot","message":"Lading with Twitch Prime sub! lirikH","data":{"badge-info":"subscriber/10","badges":"moderator/1,subscriber/6,partner/1","color":"#3F51B5","display-name":"Fossabot","emotes":"1498561:30-35","flags":null,"id":"de94450d-c85b-4203-ac89-e6a2a8c73109","mod":1,"room-id":"23161357","subscriber":1,"tmi-sent-ts":"1566751098815","turbo":0,"user-id":"237719657","user-type":"mod"}}
        {"username":null,"message":null,"data":{"badge-info":"subscriber/12","badges":"subscriber/12,premium/1","color":"#FDF800","display-name":"MvPGEO","emotes":null,"flags":null,"id":"5137a8d1-65a7-456a-a818-a96bb1bf0388","login":"mvpgeo","mod":0,"msg-id":"resub","msg-param-cumulative-months":"12","msg-param-months":0,"msg-param-should-share-streak":0,"msg-param-sub-plan-name":"Channel Subscription (LIRIK)","msg-param-sub-plan":"Prime","room-id":"23161357","subscriber":1,"system-msg":"MvPGEO subscribed with Twitch Prime. They've subscribed for 12 months!","tmi-sent-ts":"1566751121451","user-id":"29546842","user-type":null,"usernotice":true}}
    ]

    chat = new TwitchChat 'lirik', '#chat-box'
    chat.init = ->
        timer = setInterval =>
            $('<div class="chat-line">&nbsp;</div>').appendTo @divId
            if $(@divId)[0].scrollHeight > $(@divId).height()
                clearInterval timer
                chat.updateSettings()
                queue = [
                    [true, @getChannelID]
                    [true, @loadBadges]
                    [true, @loadCheerEmotes]
                ].filter (q) -> q[0]
                queueNext = =>
                    if queue.length
                        queue.shift()[1].call @, queueNext
                    else
                        do addLine = =>
                            timer = setTimeout =>
                                data = angular.copy chatLines[Math.round(Math.random() * (chatLines.length - 1))]
                                @onmessage data.username, data.message, data.data
                                do addLine
                            , 100 + Math.random() * 900
                queueNext()
        , 1
        $scope.$on '$destroy', ->
            clearInterval timer
            clearTimeout timer

    chat.onmessage = (username, message, data={}) ->
        if data.clearchat
            if message
                username = 'twitchnotify'
                if data['ban-duration']?
                    message = "#{message} has been timed out for #{data['ban-duration']} seconds."
                else
                    message = "#{message} is now banned from this room."
                if data['ban-reason']
                    message += " Reason: #{data['ban-reason']}."

        if not data.pubnotice? and not data.usernotice?
            if not username? or not message?
                return

        # notify
        if data.pubnotice or data.usernotice or username == 'twitchnotify'
            newLine = $ '<div>'
            newLine.addClass 'chat-line notify'
            formattedMessage = $ '<span>'
            formattedMessage.addClass 'message'
            formattedMessage.text data['system-msg'] or message
            newLine.append formattedMessage
            headerNewLine = newLine
            if data.usernotice and message
                username = data.login
                # sub / resub
                if data['msg-id'] in ['sub', 'resub', 'subgift', 'rewardgift']
                    newLine.addClass 'sub'
            else
                @addLine newLine
                @scrollChat()
                return

        data.color ?= @nameToColor username

        newLine = $ '<div>'
        newLine.addClass 'chat-line'
        newLine.attr 'data-username', username

        # badges
        if settings.showBadges and data.badges
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
        if data.usernotice and data['msg-id'] in ['sub', 'resub']
            newLine.addClass 'sub'

        formattedUser = $ '<span>'
        formattedUser.addClass 'username'
        formattedUser.css 'color', data.color
        formattedUser.text data['display-name'] or (username[0].toUpperCase() + username[1..])
        newLine.append formattedUser
        newLine.append "#{if data.action then '' else ':'}&nbsp;"

        formattedMessage = $ '<span>'
        formattedMessage.addClass 'message'
        if data.action
            formattedMessage.css 'color', data.color
        if settings.showEmoticons
            if settings.zoom <= 100
                message = @emoticonize message, data
            else
                message = @emoticonize message, data, false, '2.0'
        if settings.showBits and data.bits? and data.bits > 0
            [message, bg] = @bitonize message, data.bits, settings.bitsType, settings.bitsTheme, if settings.zoom <= 100 then '1' else '2'
            newLine.addClass 'cheer'
            newLine.css borderLeftColor: bg
        formattedMessage.html message
        newLine.append formattedMessage

        if headerNewLine and not settings.reversedMessages then @addLine headerNewLine
        if message then @addLine newLine
        if headerNewLine and settings.reversedMessages then @addLine headerNewLine

        # scroll after all images loaded
        messageImages = formattedMessage.find 'img'
        imagesCount = messageImages.length
        if imagesCount
            messageHeight = formattedMessage.height()
            messageImages.on 'load error', onMessageImages = =>
                if messageHeight < formattedMessage.height()
                    messageHeight = formattedMessage.height()
                    @scrollChat()
                if not --imagesCount
                    messageImages.off 'load error', onMessageImages
        @scrollChat()

    chat.addLine = (newLine) ->
        if settings.reversedMessages
            newLine.prependTo @divId
            if settings.smoothScrolling
                el = $(@divId)
                if el[0].scrollTop == 0
                    el[0].scrollTop += newLine.height()
        else
            newLine.appendTo @divId

    chat.scrollChat = ->
        el = $(@divId)
        if settings.smoothScrolling
            el.stop()
            el.animate
                scrollTop: if settings.reversedMessages then 0 else el[0].scrollHeight - el.height(),
                200, 'linear', => @clearHiddenMessages()
        else
            el[0].scrollTop = if settings.reversedMessages then 0 else el[0].scrollHeight
            @clearHiddenMessages()

    chat.clearHiddenMessages = ->
        wrapHeight = $(@divId).height()
        wrapPos = $(@divId).position()
        for item in $("#{@divId} > div")
            item = $(item)
            if settings.reversedMessages
                if item.position().top > wrapPos.top + 3 * wrapHeight
                    item.remove()
            else if item.position().top < -wrapHeight
                item.remove()
            else
                break

    chat.updateSettings = ->
        $('#chat-wrap').css
            borderRadius: settings.borderRadius.split('.').join('px ') + 'px'
            background: "rgba(
                #{parseInt settings.bgColor[1..2], 16},
                #{parseInt settings.bgColor[3..4], 16},
                #{parseInt settings.bgColor[5..6], 16},
                #{settings.bgOpacity / 100})"
        margins = settings.margin.split('.')
        $(@divId).css
            fontWeight: if settings.boldText then 'bold' else 'normal'
            margin: if not settings.bgOpacity then 0 else "#{margins[0]}px #{margins[1]}px"
            padding: if settings.textShadow then '0 2px' else 0
            textShadow: if settings.textShadow then '
                rgba(0,0,0,0.8) 1px 1px 1px,
                rgba(0,0,0,0.8) -1px -1px 1px,
                rgba(0,0,0,0.8) 1px -1px 1px,
                rgba(0,0,0,0.8) -1px 1px 1px' else 'none'
        chatStyle.text "
            #{@divId} .chat-line {
                zoom: #{settings.zoom / 100};
            }
            #{@divId} > .chat-line > .message > .emoticon {
                zoom: #{if settings.zoom <= 100 then 1 else 0.5};
                max-height: #{if settings.zoom <= 100 then 28 else 56}px;
            }"
        @scrollChat()

    chatStyle = $('<style type="text/css">').appendTo 'head'
    chat.init()

#      __  .__   __.  __  .___________.
#     |  | |  \ |  | |  | |           |
#     |  | |   \|  | |  | `---|  |----`
#     |  | |  . `  | |  |     |  |
#     |  | |  |\   | |  |     |  |
#     |__| |__| \__| |__|     |__|
#

angular.bootstrap document, [app.name]
