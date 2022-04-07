app = angular.module 'setup-cover', [
    'ir.service'
]

app.config (iRServiceProvider) ->
    iRServiceProvider.serviceOnly()
    iRServiceProvider.addOptions
        requestParams: [
            'DriverMarker'
            'IsInGarage'
            'IsOnTrack'
        ]

app.service 'config', ->
    data =
        fps: 20
        recordFPS: 50
        recordStartFrame: 0

    for v in (window.location.search.substring 1).split '&'
        [key, val] = v.split '='
        val = decodeURIComponent val
        if /^\d{1,10}$/.test val
            val = parseInt val
        data[key] = val

    data

#     .___  ___.      ___       __  .__   __.
#     |   \/   |     /   \     |  | |  \ |  |
#     |  \  /  |    /  ^  \    |  | |   \|  |
#     |  |\/|  |   /  /_\  \   |  | |  . `  |
#     |  |  |  |  /  _____  \  |  | |  |\   |
#     |__|  |__| /__/     \__\ |__| |__| \__|
#

app.controller 'MainCtrl', ($scope, $timeout, config, iRService) ->
    ir = $scope.ir
    $scope.show = false
    hideTimeout = null
    connectedTime = null
    skipFirstGarage = false

    $scope.$watch 'ir.connected', onConnected = (n, o) ->
        if not n then return
        if o == false
            console.log 'skip true'
            connectedTime = Date.now()
            skipFirstGarage = true
        if iRService.record?
            iRService.playRecord config.recordStartFrame, config.recordStopFrame, config.recordFPS

    $scope.$watchGroup ['ir.connected', 'ir.DriverMarker', 'ir.IsInGarage', 'ir.IsOnTrack'], ->
        # console.log ir.IsInGarage, ir.DriverMarker, ir.IsOnTrack
        $timeout.cancel hideTimeout

        # test
        # $scope.show = true
        # return

        # skip garage on connect
        if skipFirstGarage and ir.DriverMarker
            connectedTime = null
            skipFirstGarage = false
        if connectedTime? and Date.now() - connectedTime < 10000
            if not skipFirstGarage and not ir.IsInGarage
                connectedTime = null
            if skipFirstGarage and ir.IsInGarage
                skipFirstGarage = false
            return

        if not ir.connected or ir.IsOnTrack
            $scope.show = false
        else if ir.IsInGarage or ir.DriverMarker
            $scope.show = true
        else
            hideTimeout = $timeout ->
                $scope.show = false
            , 1000

angular.bootstrap document, [app.name]
