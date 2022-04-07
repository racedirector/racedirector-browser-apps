app = angular.module 'app', []

app.service 'iRService', ($rootScope) ->
    ir = new IRacing \
        # request params
        [
            # yaml
            'CameraInfo'
            'CarSetup'
            'DriverInfo'
            'QualifyResultsInfo'
            'RadioInfo'
            'SessionInfo'
            'SplitTimeInfo'
            'WeekendInfo'
            # telemetry
            '__all_telemetry__'
        ]

    firstTimeUpdated = false

    ir.onConnect = ->
        firstTimeUpdated = false
        $rootScope.connected = true
        $rootScope.$apply()

    ir.onDisconnect = ->
        $rootScope.connected = false
        $rootScope.$apply()

    ir.onUpdate = ->
        if not firstTimeUpdated
            firstTimeUpdated = true
            $rootScope.$apply()

    return ir





app.controller 'ViewersCtrl', ($scope, iRService) ->
    $scope.ir = ir = iRService.data

    yamlViewer = new JSONEditor document.getElementById('yaml'),
        mode: 'view'
        name: 'Session Data'
        sortObjectKeys: true
    telemetryViewer = new JSONEditor document.getElementById('telemetry'),
        mode: 'view'
        name: 'Telemetry Data'
        sortObjectKeys: true

    update = ->
        jsonYaml = {}
        jsonTelemetry = {}
        for k, v of ir
            if v? and v instanceof Object and v not instanceof Array
                if k in ['DriversByCarIdx', 'PositionsByCarIdx', 'QualifyResultsByCarIdx'] then continue
                jsonYaml[k] = v
            else
                if k in ['CarClassIDs'] then continue
                jsonTelemetry[k] = v
        yamlViewer.set jsonYaml
        telemetryViewer.set jsonTelemetry

    $scope.refresh = refresh = ->
        $scope.ir = ir
        update()

    $scope.$watch 'connected', (n, o) ->
        if not n
            return
        irWatch = $scope.$watch 'ir', (n, o) ->
            if n != o
                irWatch()
                refresh()
        , true





app.controller 'CommandsCtrl', ($scope, iRService) ->
    $scope.ir = iRService.data

    $scope.cam_switch_pos = [0, 1, 0]
    $scope.cam_switch_num = ['1', 1, 0]
    $scope.cam_set_state = [4]
    $scope.replay_set_play_speed = [0, false]
    $scope.replay_set_play_position = [0, 0]
    $scope.replay_search = [0]
    $scope.replay_set_state = [0]
    $scope.reload_all_textures = []
    $scope.reload_texture = [0]
    $scope.chat_command = [1]
    $scope.chat_command_macro = [0]
    $scope.pit_command = [0, 0]
    $scope.telem_command = [0]
    $scope.ffb_command = [0, 0]
    $scope.replay_search_session_time = [0, 0]

    $scope.send = (command) ->
        args = [command].concat $scope[command]
        iRService.sendCommand.apply iRService, args

app.directive 'appSendCommand', ->
    link: (scope, element, attrs) ->
        scope.$watchCollection attrs.appSendCommand, (n, o) ->
            args = for a in n
                if typeof a == 'string'
                    "\"#{a}\""
                else
                    a
            element.text """
                ir.sendCommand("#{attrs.appSendCommand}"\
                    #{if args.length then ", #{args.join ', '}" else ''}\
                    )"""






angular.bootstrap document, ['app']





# commands

$('#command-select').change ->
    id = $(this).val()
    $('#commands > div').each (index, element) ->
        $(element).toggleClass 'hide', id != element.id

$('#commands > div').each (index, element) ->
    $(element).toggleClass 'hide', index != 0
