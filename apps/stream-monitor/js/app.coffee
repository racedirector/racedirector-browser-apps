app = angular.module 'stream-monitor', [
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
        title = 'Stream Monitor &middot; iRacing Browser Apps'
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

app.controller 'SettingsCtrl', ($sce, $scope, $http, $location, localStorageService) ->
    defaultSettings =
        host: '127.0.0.1:8184'
        twitchOAuthToken: ''
        # imRaisingLimitedKey: ''
        streamLabsToken: ''
        # donationTrackerChannel: ''
        # donationTrackerKey: ''
        showViewersCounter: true
        showFollowersCounter: true
        showEmoticons: true
        showBadges: true
        showBits: true
        bitsType: true
        bitsTheme: false
        filterBetBot: 'BatManCave'
        filterBots: ['MooBot', 'NightBot']
        smoothScrolling: true
        strikeOutMessages: true
        highlightMessages: []
        showIRatings: false

    $scope.settings = settings = localStorageService.get('settings') or {}
    settings.host ?= null
    for p of defaultSettings
        if p not of settings
            settings[p] = defaultSettings[p]

    # for localhost:8184
    clienId = 'k75ira73ixi4h8gc0zzdl8k0tu71cil'
    redirectUri = encodeURIComponent 'http://localhost:8184/stream-monitor/#!/settings'

    # for ir-apps.kutu.ru
    if document.location.host == 'ir-apps.kutu.ru'
        clienId = 'pqm8imevmf2gdewgucdl538h2lhbj19'
        redirectUri = encodeURIComponent 'http://ir-apps.kutu.ru/stream-monitor/#!/settings'

    scopes = [
        'channel_editor'
        # 'channel_subscriptions'
        'channel_commercial'
    ]
    token = null
    baseUri = 'https://api.twitch.tv/kraken'

    # get twitch oauth token from location
    hash = $location.hash()
    if hash
        for p in hash.split '&'
            [k, v] = p.split '='
            if k == 'access_token'
                settings.twitchOAuthToken = v
                break
        localStorageService.set 'settings', settings
        $location.hash null

    # copy twitchalerts to streamlabs
    if settings.twitchAlertsToken and not settings.streamLabsToken
        settings.streamLabsToken = settings.twitchAlertsToken
        delete settings.twitchAlertsToken

    $scope.connect = ->
        window.location = "#{baseUri}/oauth2/authorize\
            ?response_type=token\
            &client_id=#{clienId}\
            &redirect_uri=#{redirectUri}\
            &scope=#{scopes.join '+'}"

    checkAuthenticated = ->
        $http.jsonp $sce.trustAsResourceUrl(baseUri),
            params:
                oauth_token: settings.twitchOAuthToken
                client_id: clienId
        .then (response) ->
            # console.log response.data
            $scope.ready = true
            if not response.data.token.authorization
                return
            for scope in scopes
                if scope not in response.data.token.authorization.scopes
                    return
            $scope.authenticated = response.data.token.valid
            token = response.data.token

    if settings.twitchOAuthToken?
        checkAuthenticated()
    else
        $scope.ready = true

    $scope.saveSettings = saveSettings = ->
        # reset host
        if settings.host == ''
            settings.host = null

        # imraising
        # if settings.imRaisingLimitedKey?
        #     settings.imRaisingLimitedKey = settings.imRaisingLimitedKey.replace /\s/g, ''

        # twitchalerts
        if settings.streamLabsToken?
            settings.streamLabsToken = settings.streamLabsToken.replace /\s/g, ''

        # donation tracker
        # if settings.donationTrackerChannel?
        #     settings.donationTrackerChannel = settings.donationTrackerChannel.replace /\s/g, ''
        # if settings.donationTrackerKey?
        #     settings.donationTrackerKey = settings.donationTrackerKey.replace /\s/g, ''

        localStorageService.set 'settings', settings
        updateURL()

    actualKeys = [
        'host'
        'showViewersCounter'
        'showFollowersCounter'
        'showEmoticons'
        'showBadges'
        'showBits'
        'bitsType'
        'bitsTheme'
        'filterBetBot'
        'filterBots'
        'smoothScrolling'
        'strikeOutMessages'
        'highlightMessages'
        'showIRatings'
        'twitchOAuthToken'
        # 'imRaisingLimitedKey'
        'streamLabsToken'
        # 'donationTrackerChannel'
        # 'donationTrackerKey'
    ]

    do updateURL = ->
        params = []
        for k in actualKeys
            if k not of settings then continue
            v = settings[k]
            if k of defaultSettings and (
                v == defaultSettings[k] or \
                (
                    angular.isArray(v) and angular.isArray(defaultSettings[k]) \
                    and v.toString() == defaultSettings[k].toString()
                )
                ) then continue
            if k == 'host' and not v? then continue
            if not settings.showBits and k in ['bitsType', 'bitsTheme'] then continue
            if v == '' and v == defaultSettings[k] then continue
            if v == true then v = 1
            if v == false then v = 0
            params.push "#{k}=#{encodeURIComponent v}"
        $scope.url = "http://#{document.location.host}/stream-monitor/monitor.html\
            #{if params.length then '?' + params.join '&' else ''}"

#      __  .__   __.  __  .___________.
#     |  | |  \ |  | |  | |           |
#     |  | |   \|  | |  | `---|  |----`
#     |  | |  . `  | |  |     |  |
#     |  | |  |\   | |  |     |  |
#     |__| |__| \__| |__|     |__|
#

angular.bootstrap document, [app.name]
