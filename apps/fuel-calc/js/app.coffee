responsiveVoiceReady = false
onResponsiveVoiceReady = null

app = angular.module 'fuel-calc', [
    'ngRoute'
    'mgcrea.ngStrap.navbar'
    'LocalStorageModule'
    'kutu.markdown'
    'kutu.ir-service'
]

app.config ($routeProvider) ->
    $routeProvider
        .when '/',
            templateUrl: 'tmpl/index.html'
            controller: 'IndexCtrl'
        .when '/help',
            templateUrl: 'tmpl/help.html'
            title: 'Help'
        .when '/settings',
            templateUrl: 'tmpl/settings.html'
            controller: 'SettingsCtrl'
            title: 'Settings'
        .otherwise redirectTo: '/'

app.config (localStorageServiceProvider) ->
    localStorageServiceProvider.setPrefix app.name

#     .______       __    __  .__   __.
#     |   _  \     |  |  |  | |  \ |  |
#     |  |_)  |    |  |  |  | |   \|  |
#     |      /     |  |  |  | |  . `  |
#     |  |\  \----.|  `--'  | |  |\   |
#     | _| `._____| \______/  |__| \__|
#

app.run ($rootScope, $sce, localStorageService) ->
    $rootScope.$on '$routeChangeSuccess', (event, current, previous) ->
        title = 'Fuel Calculator &middot; iRacing Browser Apps'
        if current.$$route.title?
            title = current.$$route.title + ' &middot; ' + title
        $rootScope.title = $sce.trustAsHtml title

    $rootScope.settings = settings = localStorageService.get('settings') or {}
    settings.host ||= null
    settings.fuelPerLapPerTrack ?= {}
    settings.announceLang ?= null
    settings.announceVolume ?= {}
    settings.announceOn ?= false
    settings.announceAtTrackPct ?= {}
    settings.announcePerLap ?= true
    settings.announcePerLapTmpl ?= '{0} per lap.'
    settings.announceRemainLaps ?= true
    settings.announceRemainLapsTmpl ?= 'remain {1} laps.'
    settings.announceNeedRefuel ?= true
    settings.announceNeedRefuelTmpl ?= 'need {2} on pit-stop.'
    settings.announceAfterLaps ?= 3
    settings.announceDelay ?= 0
    settings.announceKeepSpeaking ?= false

    if not angular.isObject settings.announceLang
        settings.announceLang = responsiveVoice.getVoices()[0]
        settings.announceLang.lang = 'en'
    responsiveVoice.setDefaultVoice settings.announceLang.name

    $rootScope.showAnnounceRow = settings.announcePerLap or \
        settings.announceRemainLaps or settings.announceNeedRefuel
    if not $rootScope.showAnnounceRow
        $('.footer').hide()

    $rootScope.settingUpdate = (param, value) ->
        if param of $rootScope.settings
            $rootScope.settings[param] = value
        $rootScope.saveSettings()

    $rootScope.settingToggle = (param) ->
        if param of $rootScope.settings
            $rootScope.settings[param] = !$rootScope.settings[param]
        $rootScope.saveSettings()

    $rootScope.saveSettings = ->
        settings.host ||= null
        if settings.announceLang?
            responsiveVoice.setDefaultVoice settings.announceLang.name
        $rootScope.showAnnounceRow = settings.announcePerLap or \
            settings.announceRemainLaps or settings.announceNeedRefuel
        if $rootScope.showAnnounceRow then $('.footer').show() else $('.footer').hide()
        localStorageService.set 'settings', $rootScope.settings

#      __  .__   __.  _______   __________   ___
#     |  | |  \ |  | |       \ |   ____\  \ /  /
#     |  | |   \|  | |  .--.  ||  |__   \  V  /
#     |  | |  . `  | |  |  |  ||   __|   >   <
#     |  | |  |\   | |  '--'  ||  |____ /  .  \
#     |__| |__| \__| |_______/ |_______/__/ \__\
#

app.controller 'IndexCtrl', ($scope, $timeout, iRService) ->
    settings = $scope.settings
    ir = $scope.ir
    delayTimeout = null

    if $.isEmptyObject settings.announceAtTrackPct
        $('[data-toggle=popover]').popover
            placement: 'left'
            html: true
            trigger: 'hover'

    getVolume = ->
        (settings.announceVolume[ir.carId] or settings.announceVolume.default) / 100 or 1

    $scope.$watch 'ir.LapDistPct', (n, o) ->
        if not n? or not ir.needToAnnounce
            return
        # dont announce while someone talking
        if ir.RadioTransmitCarIdx != -1
            return
        announcePct = null
        if ir.WeekendInfo?
            announcePct = settings.announceAtTrackPct[ir.WeekendInfo.TrackID]
        if announcePct? and n < announcePct
            return

        ir.needToAnnounce = false
        if settings.announceOn
            $timeout.cancel delayTimeout
            if settings.announceAfterLaps > 0 and ir.SessionInfo? and ir.SessionNum >= 0 \
                    and ir.SessionInfo.Sessions[ir.SessionNum].SessionType == 'Race' \
                    and ir.Lap >= settings.announceAfterLaps
                $scope.announce()
            else if not announcePct? and settings.announceDelay > 0
                delayTimeout = $timeout ->
                    $scope.announce()
                , settings.announceDelay * 1000
            else
                $scope.announce()

    # stop announce while radio is on, and replay after
    $scope.$watch 'ir.RadioTransmitCarIdx', (n, o) ->
        if n? and n != -1 and (not settings.announceKeepSpeaking) and responsiveVoice.isPlaying()
            responsiveVoice.cancel()
            ir.needToAnnounce = true

    $scope.announce = ->
        $timeout.cancel delayTimeout
        if ir.carId? and settings.announceVolume[ir.carId] == 0
            return
        texts = []
        items = [
            [settings.announcePerLap, settings.announcePerLapTmpl, $scope.normalizeFuelLevel ir.fuelPerLap]
            [settings.announceRemainLaps, settings.announceRemainLapsTmpl, ir.fuelRemainLaps]
            [settings.announceNeedRefuel, settings.announceNeedRefuelTmpl, $scope.normalizeFuelLevel ir.fuelNeedRefuel]
        ]
        for item in items
            if item[0] and item[2]? and item[2] > 0
                params = [
                    item[2].toLocaleString settings.announceLang.lang, maximumFractionDigits: 2
                    item[2].toLocaleString settings.announceLang.lang, maximumFractionDigits: 1
                    Math.ceil(item[2])
                    Math.floor(item[2])
                ]
                text = item[1]
                for v, i in params
                    text = text.split("{#{i}}").join v
                texts.push text
        if texts.length
            responsiveVoice.speak texts.join(' '), null, volume: getVolume()

    $scope.toggleAnnounceOn = ->
        $scope.settingToggle('announceOn')
        if not settings.announceOn
            responsiveVoice.cancel()

    $scope.setAnnouncePointHere = ->
        if not ir.IsOnTrack or not ir.LapDistPct? or not ir.WeekendInfo?
            return false
        settings.announceAtTrackPct[ir.WeekendInfo.TrackID] = ir.LapDistPct
        $scope.saveSettings()
        return true

app.directive 'appAnnouncePoint', ($timeout) ->
    link: (scope, element, attrs) ->
        t = null
        element.on 'click', ->
            element.addClass 'btn-announce-point'
            if scope.setAnnouncePointHere()
                element.addClass 'btn-success'
            else
                element.addClass 'btn-danger'
            t = $timeout ->
                element.removeClass 'btn-success btn-danger'
                t = $timeout ->
                    element.removeClass 'btn-announce-point'
                , 100
            , 1000
        scope.$on '$destroy', ->
            $timeout.cancel t

app.directive 'appFuelLevel', ->
    link: (scope, element, attrs) ->
        ir = scope.ir
        element.text '0.00'
        updateFuelLevel = ->
            if not ir.FuelLevel?
                # or not scope.ir.IsOnTrack
                return
            fuel = scope.normalizeFuelLevel ir.FuelLevel
            element.text fuel.toFixed if fuel < 100 then 2 else 1
        scope.$watch 'ir.DisplayUnits', updateFuelLevel
        scope.$watch 'ir.FuelLevel', updateFuelLevel

app.directive 'appFuelPerLap', ->
    link: (scope, element, attrs) ->
        ir = scope.ir
        updateFuelPerLap = ->
            if not ir.fuelPerLap?
                element.text '-.--'
                return
            fuel = scope.normalizeFuelLevel ir.fuelPerLap
            element.text \
                if fuel <= 9.99 then (Math.ceil(fuel * 100) / 100).toFixed 2
                else (Math.ceil(fuel * 10) / 10).toFixed 1
        scope.$watch 'ir.DisplayUnits', updateFuelPerLap
        scope.$watch 'ir.fuelPerLap', updateFuelPerLap

app.directive 'appFuelRemainLaps', ->
    link: (scope, element, attrs) ->
        scope.$watch 'ir.fuelRemainLaps', (n, o) ->
            if not n?
                element.text '--.--'
                return
            element.text n.toFixed if n < 100 then 2 else 1

app.directive 'appFuelNeedRefuel', ->
    link: (scope, element, attrs) ->
        ir = scope.ir
        updateFuelNeedRefuel = ->
            if not ir.fuelNeedRefuel?
                element.text '--.-'
                return
            fuel = scope.normalizeFuelLevel ir.fuelNeedRefuel
            element.text \
                if fuel <= 9.99 then (Math.ceil(fuel * 100) / 100).toFixed 2
                else if fuel <= 99.9 then (Math.ceil(fuel * 10) / 10).toFixed 1
                else Math.ceil fuel
        scope.$watch 'ir.DisplayUnits', updateFuelNeedRefuel
        scope.$watch 'ir.fuelNeedRefuel', updateFuelNeedRefuel

app.directive 'appRaceLaps', ->
    link: (scope, element, attrs) ->
        scope.$watch 'ir.raceLaps', (n, o) ->
            if not n?
                element.text '--.--'
                return
            laps = n
            element.text \
                if laps <= 99.99 then (Math.ceil(laps * 100) / 100).toFixed 2
                else if laps <= 999.9 then (Math.ceil(laps * 10) / 10).toFixed 1
                else Math.ceil laps

app.directive 'appRaceFuel', ->
    link: (scope, element, attrs) ->
        ir = scope.ir
        updateRaceFuel = ->
            if not ir.raceFuel?
                element.text '--.-'
                return
            fuel = scope.normalizeFuelLevel ir.raceFuel
            element.text \
                if fuel <= 9.99 then (Math.ceil(fuel * 100) / 100).toFixed 2
                else if fuel <= 99.9 then (Math.ceil(fuel * 10) / 10).toFixed 1
                else Math.ceil fuel
        scope.$watch 'ir.DisplayUnits', updateRaceFuel
        scope.$watch 'ir.raceFuel', updateRaceFuel

#          _______. _______ .___________.___________. __  .__   __.   _______      _______.
#         /       ||   ____||           |           ||  | |  \ |  |  /  _____|    /       |
#        |   (----`|  |__   `---|  |----`---|  |----`|  | |   \|  | |  |  __     |   (----`
#         \   \    |   __|      |  |        |  |     |  | |  . `  | |  | |_ |     \   \
#     .----)   |   |  |____     |  |        |  |     |  | |  |\   | |  |__| | .----)   |
#     |_______/    |_______|    |__|        |__|     |__| |__| \__|  \______| |_______/
#

app.controller 'SettingsCtrl', ($scope, $timeout, iRService) ->
    settings = $scope.settings
    ir = $scope.ir

    onResponsiveVoice = ->
        announceLangOptions = angular.copy responsiveVoice.getVoices()
        for v in responsiveVoice.responsivevoices
            foundVoice = false
            for i in announceLangOptions
                if foundVoice then continue
                if i.name == v.name
                    foundVoice = true
                    i.lang = v.mappedProfile.systemvoice.lang or v.mappedProfile.collectionvoice.lang
        $timeout ->
            $scope.announceLangOptions = announceLangOptions
        , 1
    if responsiveVoiceReady
        onResponsiveVoice()
    else
        onResponsiveVoiceReady = onResponsiveVoice

    $('[data-toggle=popover]').popover
        container: 'body'
        placement: 'auto'
        html: true
        trigger: 'focus'

    getVolume = ->
        (settings.announceVolume[ir.carId] or settings.announceVolume.default) / 100 or 1

    $scope.testAnnounceLanguage = ->
        testAnnounce '1 2 3'

    $scope.testAnnouncePerLap = ->
        testAnnounce settings.announcePerLapTmpl

    $scope.testAnnounceRemainLaps = ->
        testAnnounce settings.announceRemainLapsTmpl, 20, 60

    $scope.testAnnounceNeedRefuel = ->
        testAnnounce settings.announceNeedRefuelTmpl, 10, 40

    testAnnounce = (text, start=.1, end=3) ->
        value = start + (end - start) * Math.random()
        params = [
            value.toLocaleString settings.announceLang.lang, maximumFractionDigits: 2
            value.toLocaleString settings.announceLang.lang, maximumFractionDigits: 1
            Math.ceil(value)
            Math.floor(value)
        ]
        for v, i in params
            text = text.split("{#{i}}").join v
        responsiveVoice.speak text, null, volume: getVolume()

    # volume by car id
    $scope.announceVolume = 100
    $scope.$watch 'ir.carId', (n, o) ->
        if n?
            $scope.announceVolume = settings.announceVolume[ir.carId] or 100
    $scope.announceVolumeChange = ->
        volume = parseInt $scope.announceVolume
        if ir.carId?
            settings.announceVolume[ir.carId] = volume
        else
            settings.announceVolume.default = volume
        $scope.saveSettings()

#      __    __  .___________. __   __          _______.
#     |  |  |  | |           ||  | |  |        /       |
#     |  |  |  | `---|  |----`|  | |  |       |   (----`
#     |  |  |  |     |  |     |  | |  |        \   \
#     |  `--'  |     |  |     |  | |  `----.----)   |
#      \______/      |__|     |__| |_______|_______/
#

app.directive 'ngEnter', ->
    link: (scope, element, attrs) ->
        element.bind 'keydown keypress', (event) ->
            if event.which == 13
                scope.$apply ->
                    scope.$eval attrs.ngEnter
                event.preventDefault()

angular.bootstrap document, [app.name]

#     ____    ____  ______    __    ______  _______
#     \   \  /   / /  __  \  |  |  /      ||   ____|
#      \   \/   / |  |  |  | |  | |  ,----'|  |__
#       \      /  |  |  |  | |  | |  |     |   __|
#        \    /   |  `--'  | |  | |  `----.|  |____
#         \__/     \______/  |__|  \______||_______|
#

responsiveVoice.OnVoiceReady = ->
    responsiveVoiceReady = true
    onResponsiveVoiceReady?()
    onResponsiveVoiceReady = null
