app = angular.module 'setup-comparison-tool', [
    'ngRoute'
    'mgcrea.ngStrap.navbar'
    'kutu.markdown'
    'server.setup-comparison-tool.sorter'
    'ir.service'
]

app.config ($routeProvider, iRServiceProvider) ->
    $routeProvider
        .when '/',
            templateUrl: 'tmpl/index.html'
            controller: 'ComparisonCtrl'
        .when '/help',
            templateUrl: 'tmpl/help.html'
            title: 'Help'
        .otherwise redirectTo: '/'

    iRServiceProvider.serviceOnly()
    iRServiceProvider.addOptions
        requestParams: [
            'CarSetup'
            'DriverInfo'
        ]

app.run ($rootScope, $sce, config, iRService) ->
    $rootScope.$on '$routeChangeSuccess', (event, current, previous) ->
        title = 'Setup Comparison Tool &middot; iRacing Browser Apps'
        if current.$$route.title?
            title = current.$$route.title + ' &middot; ' + title
        $rootScope.title = $sce.trustAsHtml title

    $rootScope.$watch 'ir.connected', onConnected = (n, o) ->
        if not n then return
        if iRService.record?
            iRService.playRecord config.recordStartFrame, config.recordStopFrame, config.recordFPS

    $rootScope.compareMode = 0

app.service 'config', ->
    data =
        fps: 1
        recordFPS: 10000
        recordStartFrame: 527

    for v in (window.location.search.substring 1).split '&'
        [key, val] = v.split '='
        val = decodeURIComponent val
        if /^\d{1,10}$/.test val
            val = parseInt val
        data[key] = val

    data

#       ______   ______   .___  ___. .______      ___      .______       __       _______.  ______   .__   __.
#      /      | /  __  \  |   \/   | |   _  \    /   \     |   _  \     |  |     /       | /  __  \  |  \ |  |
#     |  ,----'|  |  |  | |  \  /  | |  |_)  |  /  ^  \    |  |_)  |    |  |    |   (----`|  |  |  | |   \|  |
#     |  |     |  |  |  | |  |\/|  | |   ___/  /  /_\  \   |      /     |  |     \   \    |  |  |  | |  . `  |
#     |  `----.|  `--'  | |  |  |  | |  |     /  _____  \  |  |\  \----.|  | .----)   |   |  `--'  | |  |\   |
#      \______| \______/  |__|  |__| | _|    /__/     \__\ | _| `._____||__| |_______/     \______/  |__| \__|
#

app.controller 'ComparisonCtrl', ($rootScope, $scope, config, iRService, ServerSetupComparisonToolSorter) ->
    ir = $scope.ir
    setupUpdateCount = null
    $scope.newSnapshotAvailable = false

    $scope.$watch 'ir.connected', onConnected = (n, o) ->
        setupUpdateCount = null
        $scope.newSnapshotAvailable = false

    $scope.$watch 'ir.DriverInfo', onDriverInfo = (n, o) ->
        if not n then return
        for d in ir.DriverInfo.Drivers
            if d.CarIdx == ir.DriverInfo.DriverCarIdx
                newCarId = d.CarID
                break
        if newCarId? and $rootScope.carId != newCarId
            $rootScope.carId = newCarId
            $rootScope.clearSetups = true

    $scope.$watch 'ir.CarSetup', onCarSetup = (n, o) ->
        if n? and (not setupUpdateCount? or (n.UpdateCount != setupUpdateCount))
            $scope.newSnapshotAvailable = true

    # test
    if iRService.record
        $scope.$watch 'ir.CarSetup', (n, o) ->
            if not n then return
            if $rootScope.clearSetups
                $rootScope.setups = []
                $rootScope.clearSetups = false
            $rootScope.setups.push parseSetup n

    $scope.snapshot = ->
        if $rootScope.clearSetups
            $rootScope.setups = []
            $rootScope.clearSetups = false
        if $scope.newSnapshotAvailable and ir.CarSetup?
            setupUpdateCount = ir.CarSetup.UpdateCount
            $scope.newSnapshotAvailable = false
            $rootScope.setups.push parseSetup ir.CarSetup

    $scope.clearAll = ->
        if $rootScope.setups?
            $rootScope.setups.length = 0
            setupUpdateCount = null
            $scope.newSnapshotAvailable = true

    $scope.onShowOnlyChanges = ->
        $rootScope.showOnlyChanges = !$rootScope.showOnlyChanges

    $scope.moveSetupTo = (setup, way) ->
        index = $rootScope.setups.indexOf setup
        if index != -1 and 0 <= index + way < $rootScope.setups.length
            tmp = $rootScope.setups[index]
            $rootScope.setups[index] = $rootScope.setups[index + way]
            $rootScope.setups[index + way] = tmp

    $scope.removeSetup = (setup) ->
        index = $rootScope.setups.indexOf setup
        if index != -1
            $rootScope.setups.splice index, 1

    parseSetup = (n) ->
        groups = []
        for k, v of n
            if k == 'UpdateCount' then continue
            sections = []
            for k1, v1 of v
                parameters = []
                for k2, v2 of v1
                    parameters.push key: k2, value: v2
                    # parameters.sort ServerSetupComparisonToolSorter.sortParameterFunc
                sections.push key: k1, value: parameters
                # sections.sort ServerSetupComparisonToolSorter.sortSectionFunc
            groups.push key: k, value: sections
            # groups.sort ServerSetupComparisonToolSorter.sortGroupFunc
        title: new Date().toLocaleTimeString()
        groups: groups

    $('.toolbar').affix offset: 8

app.directive 'appParameter', ->
    link: (scope, element, attrs) ->
        group = scope.$parent.$parent.$index
        section = scope.$parent.$index
        parameter = scope.$index
        parentScope = scope.$parent.$parent.$parent.$parent

        scope.$watch 'parameterHover', (n, o) ->
            element.toggleClass 'hover', n? and group == n[0] and section == n[1] and parameter == n[2]

        element.on 'mouseenter', ->
            scope.$apply ->
                parentScope.parameterHover = [group, section, parameter]
        element.on 'mouseleave', ->
            scope.$apply ->
                delete parentScope.parameterHover

        update = ->
            if not scope.showOnlyChanges
                element.removeClass 'ng-hide'
                return
            v = null
            vChanged = false
            for s in scope.setups
                v2 = s.groups[group].value[section].value[parameter].value
                if not v?
                    v = v2
                else if v != v2
                    vChanged = true
                    break
            element.toggleClass 'ng-hide', not vChanged

        scope.$watch 'showOnlyChanges', update
        scope.$watchCollection 'setups', update

app.directive 'appParameterValue', ->
    link: (scope, element, attrs) ->
        group = scope.$parent.$parent.$index
        section = scope.$parent.$index
        parameter = scope.$index
        element.text scope.parameter.value

        update = ->
            setup = scope.$parent.$parent.$parent.$index
            value = scope.parameter.value
            changed = false
            for s, i in scope.setups by -1
                if i >= setup then continue
                changed = value != s.groups[group].value[section].value[parameter].value
                if changed or scope.compareMode == 0 then break
            element.toggleClass 'changed', changed

        scope.$watchCollection 'setups', update
        scope.$watch 'compareMode', update

angular.bootstrap document, [app.name]
