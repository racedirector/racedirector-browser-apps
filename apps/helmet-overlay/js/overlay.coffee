app = angular.module 'helmet-overlay', [
    'ir.service'
]

app.config (iRServiceProvider) ->
    iRServiceProvider.serviceOnly()
    iRServiceProvider.addOptions
        requestParams: [
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

    $scope.$watch 'ir.connected', onConnected = (n, o) ->
        if not n then return
        if iRService.record?
            iRService.playRecord config.recordStartFrame, config.recordStopFrame, config.recordFPS

    $scope.$watch 'ir.IsOnTrack', ->
        $scope.show = ir.IsOnTrack

angular.bootstrap document, [app.name]
