app = angular.module 'ir.service', []
app.provider 'iRService', ->
    @options =
        requestParams: [
            'DriverInfo'
            'SessionInfo'
        ]
        requestParamsOnce: [
            'QualifyResultsInfo'
        ]
        fps: 10

    @addOptions = (data) ->
        for k, v of data
            optV = @options[k]
            if optV? and angular.isArray(optV) and angular.isArray(v)
                for p in v when p not in optV
                    optV.push p
            else
                @options[k] = v

    @serviceOnly = ->
        @options = fps: 1

    @$get = ($rootScope, config) ->
        ir = new IRacing @options.requestParams, @options.requestParamsOnce,
            config.fps or @options.fps, config.server or @options.server, @options.readIbt,
            config.record, config.zipLibPath

        ir.onConnect = (update=true) ->
            ir.data.connected = true
            if update
                $rootScope.$apply()

        ir.onDisconnect = (update=true) ->
            ir.data.connected = false
            if update
                $rootScope.$apply()

        ir.onUpdate = (keys, update=true) ->
            if 'DriverInfo' in keys
                updateDriversByCarIdx()
            if 'SessionInfo' in keys
                updatePositionsByCarIdx()
                updateQualifyResultsByCarIdx()
            if 'QualifyResultsInfo' in keys
                updateQualifyResultsByCarIdx()
            # test
            # ir.data.CamCarIdx = 19
            # ir.data.CamCarIdx = 1 + (ir.record.currentFrame / 10 % 25 | 0)
            # test
            # @onmessage = ->
            # test non metric for fuel calc
            # if 'DisplayUnits' in keys
            #     ir.data.DisplayUnits = 0
            if update
                $rootScope.$apply()

        ir.onBroadcast = (data) ->
            $rootScope.$broadcast 'broadcastMessage', data

        updateDriversByCarIdx = ->
            ir.data.DriversByCarIdx ?= {}
            for driver in ir.data.DriverInfo.Drivers
                ir.data.DriversByCarIdx[driver.CarIdx] = driver

        updatePositionsByCarIdx = ->
            ir.data.PositionsByCarIdx ?= []
            for session, i in ir.data.SessionInfo.Sessions
                while i >= ir.data.PositionsByCarIdx.length
                    ir.data.PositionsByCarIdx.push {}
                if session.ResultsPositions
                    for position in session.ResultsPositions
                        ir.data.PositionsByCarIdx[i][position.CarIdx] = position

        updateQualifyResultsByCarIdx = ->
            ir.data.QualifyResultsByCarIdx ?= {}
            results = ir.data.QualifyResultsInfo?.Results or ir.data.SessionInfo.Sessions[ir.data.SessionNum]?.QualifyPositions or []
            for position in results
                ir.data.QualifyResultsByCarIdx[position.CarIdx] = position

        $rootScope.ir = ir.data
        return ir

    return
