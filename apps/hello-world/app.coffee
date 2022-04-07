app = angular.module 'example-app', []

app.service 'iRService', ($rootScope) ->
    ir = new IRacing ['Speed'], [], 10

    ir.onConnect = ->
        console.log 'connected'

    ir.onDisconnect = ->
        console.log 'disconnected'

    ir.onUpdate = (keys) ->
        $rootScope.$apply()

    return ir

app.controller 'MainCtrl', ($scope, iRService) ->
    $scope.ir = iRService.data

angular.bootstrap document, [app.name]
