angular.module 'kutu.ir-service', []
.service 'iRService', ($rootScope) ->
    settings = $rootScope.settings

    iRService = new IRacing [
            # yaml
            'DriverInfo'
            'SessionInfo'
            'QualifyResultsInfo'
            # telemetry
            # 'CarIdxTrackSurface'
            'DisplayUnits'
            'FuelLevel'
            'IsInGarage'
            'IsOnTrack'
            'Lap'
            'LapDistPct'
            'LFwearR'
            'OilTemp'
            'PlayerTrackSurface'
            # 'WaterTemp'
            'OnPitRoad'
            'RadioTransmitCarIdx'
            'SessionFlags'
            'SessionNum'
            'SessionState'
            'SessionTime'
            'SessionTimeRemain'
        ], [
            'WeekendInfo'
        ],
        10,
        settings.host

    $rootScope.ir = ir = iRService.data

    iRService.onWSConnect = ->
        $rootScope.wsConnected = true
        $rootScope.$apply()

    iRService.onWSDisconnect = ->
        $rootScope.wsConnected = false
        $rootScope.$apply()

    iRService.onConnect = ->
        ir.connected = true
        $rootScope.$apply()

    iRService.onDisconnect = ->
        ir.connected = false
        $rootScope.$apply()

    iRService.onUpdate = (keys) ->
        if 'DriverInfo' in keys
            updateDriversByCarIdx()
        $rootScope.$apply()

    updateDriversByCarIdx = ->
        ir.DriversByCarIdx ?= {}
        for driver in ir.DriverInfo.Drivers
            ir.DriversByCarIdx[driver.CarIdx] = driver

    ir.needToAnnounce = false
    ir.fuelPerLap = null
    ir.fuelRemainLaps = null
    ir.fuelNeedRefuel = null
    ir.sessionLaps = null
    ir.raceLaps = null
    ir.raceFuel = null

    useKg = false
    useImpGal = false
    $rootScope.normalizeFuelLevel = (fuel) ->
        # liters to kg
        if useKg
            fuel *= ir.DriverInfo.DriverCarFuelKgPerLtr or .75
        if not ir.DisplayUnits
            if useImpGal
                fuel *= 0.21996924829909
            # kg to lbs
            else if useKg
                fuel *= 2.20462262
            else
                fuel *= 0.264172052
        return fuel

    maxFuelLength = 5
    fuels = []
    lastDist = null
    lapStarted = false
    lapsComplete = 0
    lastFuelLevel = null
    # lapWatcher = null
    fuelWacther = null
    loadedPrevFuelUsage = false

    carClassId = null
    classCarIdxs = []
    maxLapTimes = 5
    avgLapTimes = {}

    # detect if car using kg
    # find car class id
    watchPlayerTrackSurface = null

    $rootScope.$watch 'ir.DriverInfo', onDriverInfo = (n, o) ->
        if not n?
            return
        for d in ir.DriverInfo.Drivers
            if d.CarIdx == ir.DriverInfo.DriverCarIdx
                useKg = d.CarID in [33, 39, 71, 77]
                useImpGal = d.CarID in [25, 42]
                carClassId = d.CarClassID
                ir.carId = d.CarID
                break
        for d in ir.DriverInfo.Drivers
            if d.CarClassID == carClassId
                classCarIdxs.push d.CarIdx

        # ctrl+r reset car to pit
        if not watchPlayerTrackSurface?
            watchPlayerTrackSurface = $rootScope.$watch 'ir.PlayerTrackSurface', (n, o) ->
                if n == -1 or (o == 3 and n == 1) or (o == 1 and n == 3)
                    lastDist = null
                    lastFuelLevel = null
                    lapStarted = false
                    # lapWatcher?()
                    # lapWatcher = null
                    ir.needToAnnounce = false
                # if n != -1 and n != 1 and not lapWatcher?
                #     updateCarFuelCalc true
                #     # lapWatcher?()
                #     # lapWatcher = $rootScope.$watch 'ir.LapDistPct', -> updateCarFuelCalc()

    # $rootScope.$watch 'ir.IsOnTrack', (n, o) ->
    #     if n
    #         lastDist = null
    #         lastFuelLevel = null
    #         lapStarted = false
    #         # lapWatcher?()
    #         # lapWatcher = null
    #         ir.needToAnnounce = false
    #     # else
    #     #     lapWatcher?()
    #     #     lapWatcher = $rootScope.$watch "ir.LapDistPct", -> updateCarFuelCalc()

    # restore previous fuel usage
    $rootScope.$watch 'ir.WeekendInfo', onWeekendInfo = (n, o) ->
        if not n? or loadedPrevFuelUsage
            return
        loadedPrevFuelUsage = true
        watchCarId = $rootScope.$watch 'ir.carId', (n, o) ->
            if not n?
                return
            watchCarId()
            if not fuels.length and $rootScope.settings.fuelPerLapPerTrack[ir.carId]
                f = $rootScope.settings.fuelPerLapPerTrack[ir.carId][ir.WeekendInfo.TrackID]
                if f > 0
                    fuels.push f
                    updateCarFuelCalc true
                    updateSessionLaps()

    $rootScope.$watch 'ir.LFwearR', (n, o) ->
        lapStarted = false

    $rootScope.$watch 'ir.SessionFlags', checkFlags = ->
        flags = ir.SessionFlags
        if not flags? or flags == -1
            false
        else if flags & 0x200 and (ir.WeekendInfo?.EventType != 'Test') or flags & (0x0400 | 0x4000 | 0x8000 | 0x080000)
            lapStarted = false
            false
        else
            true

    # calculate fuel
    updateCarFuelCalc = (updateDisplayOnly = false) ->
        dist = if ir.LapDistPct != -1 then ir.LapDistPct else null
        curFuelLevel = ir.FuelLevel
        lapChanged = false

        if ir.IsOnTrack
            if lastFuelLevel? and curFuelLevel > lastFuelLevel
                lapStarted = false

            if dist?
                if dist < .1 and lastDist? and lastDist > .9 and checkFlags()
                    lapChanged = lapStarted
                    if not lapStarted
                        updateDisplayOnly = true
                        lastFuelLevel = curFuelLevel
                    lapStarted = true
                    # check if need to add one lap
                    if ir.SessionInfo? and ir.SessionNum? and ir.SessionNum >= 0
                        session = ir.SessionInfo.Sessions[ir.SessionNum]
                        if session.SessionType == 'Race'
                            results = session.ResultsPositions
                            if results?
                                for pos in results
                                    if pos.CarIdx == ir.DriverInfo.DriverCarIdx
                                        lapsComplete = pos.LapsComplete + 1
                                        break
                lastDist = dist

        # test
        # fuels = [1.1,2.2,3.3]

        if lapChanged and ir.SessionState == 4
            legitLap = not (ir.OnPitRoad or ir.SessionFlags & (0x4000 | 0x8000))
            if legitLap and curFuelLevel? and curFuelLevel >= 0 and lastFuelLevel? and lastFuelLevel > curFuelLevel
                fuels.push lastFuelLevel - curFuelLevel
                console.log 'last lap fuel usage', fuels[fuels.length - 1]
                while fuels.length > maxFuelLength then fuels.shift()
            lastFuelLevel = curFuelLevel

        if (lapChanged or updateDisplayOnly) and fuels.length
            f = fuels.slice()
            if f.length >= 3
                f = f.sort()[1...-1]
            total = f.reduce (a, b) -> a + b

            ir.fuelPerLap = total / f.length
            ir.fuelRemainLaps = curFuelLevel / ir.fuelPerLap
            calcNeedRefuel()
            # save fuel per lap
            if lapChanged and ir.fuelPerLap? and ir.carId? and ir.WeekendInfo? and ir.WeekendInfo.TrackID
                console.log 'fuel per lap', ir.fuelPerLap, '| fuel remain laps', ir.fuelRemainLaps
                $rootScope.settings.fuelPerLapPerTrack[ir.carId] ?= {}
                $rootScope.settings.fuelPerLapPerTrack[ir.carId][ir.WeekendInfo.TrackID] = ir.fuelPerLap
                $rootScope.saveSettings()

        if lapChanged and ir.fuelPerLap? and ir.fuelRemainLaps?
            ir.needToAnnounce = true

    $rootScope.$watch "ir.LapDistPct", -> updateCarFuelCalc()

    calcNeedRefuel = ->
        # console.log new Date()
        # console.log 'fuelPerLap', ir.fuelPerLap
        # console.log 'fuelRemainLaps', ir.fuelRemainLaps
        # console.log 'sessionLaps', ir.sessionLaps
        # console.log 'lapsComplete', lapsComplete
        # console.log 'avgLapTimes', avgLapTimes
        if ir.sessionLaps? and ir.sessionLaps > 0 and lapsComplete?
            if ir.sessionLaps < lapsComplete
                ir.fuelNeedRefuel = null
            else if avgLapTimes[carClassId]?
                # if calculated laps in race more than *.9, then add 1 more lap, for safety reason
                # sesLaps = Math.ceil if ir.sessionLaps * 10 % 10 >= 9 then ir.sessionLaps + 0.5 else ir.sessionLaps
                # console.log 'sesLaps', sesLaps
                # reduce race laps if we are some laps behind the leader
                laps = Math.ceil(ir.sessionLaps) - Math.max(0, avgLapTimes[carClassId].lapsComplete, lapsComplete)
                ir.fuelNeedRefuel = Math.max 0, (laps - ir.fuelRemainLaps) * ir.fuelPerLap
                # add 0.5 to not choke at the end
                if ir.fuelNeedRefuel > 0
                    ir.fuelNeedRefuel += 0.5
                console.log 'laps left', laps, '| fuel need refuel', ir.fuelNeedRefuel

    $rootScope.$watch 'ir.OnPitRoad', (n, o) ->
        if n
            lapStarted = false
            fuelWacther?()
            fuelWacther = $rootScope.$watch 'ir.FuelLevel', (n, o) ->
                if ir.PlayerTrackSurface == 1
                    updateCarFuelCalc true
        else
            fuelWacther?()
            fuelWacther = null

    $rootScope.$watch 'ir.IsInGarage', (n, o) ->
        if n
            fuelWacther?()
            fuelWacther = $rootScope.$watch 'ir.FuelLevel', (n, o) ->
                if n > 0
                    updateCarFuelCalc true
        else
            fuelWacther?()
            fuelWacther = null

    # calculate session laps

    updateSessionLaps = ->
        if not ir.SessionInfo? or not (ir.SessionNum >= 0) or not ir.DriverInfo
            ir.sessionLaps = null
            return

        updateAvgLapTimes()
        session = ir.SessionInfo.Sessions[ir.SessionNum]
        lapsComplete = avgLapTimes[carClassId]?.lapsComplete

        if session.SessionType != 'Race' or not lapsComplete? or lapsComplete < 2
            for s in ir.SessionInfo.Sessions
                if s.SessionType == 'Race'
                    raceSession = s
                    break
            if raceSession?
                raceLaps = parseInt(raceSession.SessionLaps) or null
                avgRaceLaps = null
                raceSessionTime = parseInt raceSession.SessionTime
                if raceSessionTime > 0
                    results = ir.QualifyResultsInfo and ir.QualifyResultsInfo.Results
                    if not results?
                        for s in ir.SessionInfo.Sessions
                            if s.SessionType.search(/qual/i) != -1
                                if s.ResultsPositions
                                    results = s.ResultsPositions
                                    break
                            else if s.SessionType.search(/race/i) == -1 # not race
                                results = s.ResultsPositions
                    if results?
                        for p in results
                            if p.Position == 0 and p.FastestTime > 0
                                firstClassLapTime = p.FastestTime
                            if p.ClassPosition == 0 and p.FastestTime > 0 and p.CarIdx in classCarIdxs
                                if p.Position != 0 and firstClassLapTime > 0
                                    avgRaceLaps = Math.ceil(raceSessionTime / firstClassLapTime) * firstClassLapTime / p.FastestTime
                                else
                                    avgRaceLaps = raceSessionTime / p.FastestTime
                                break
                if (avgRaceLaps? and raceLaps? and avgRaceLaps < raceLaps) or avgRaceLaps? and not raceLaps?
                    ir.raceLaps = avgRaceLaps
                else if raceLaps?
                    ir.raceLaps = raceLaps
                console.log 'race laps based on qual or prac', ir.raceLaps
        else
            sessionLaps = parseInt session.SessionLaps
            ir.avgSessionLaps = null
            if sessionLaps > 0
                ir.sessionLaps = sessionLaps
            if avgLapTimes[carClassId]?
                avgSessionLaps = avgLapTimes[carClassId].sessionLaps
                if session.ResultsOfficial
                    ir.sessionLaps = avgLapTimes[carClassId].lapsComplete
                else if isNaN(sessionLaps) or (avgSessionLaps? and avgSessionLaps < sessionLaps - 1)
                    ir.sessionLaps = avgSessionLaps
                    ir.avgSessionLaps = avgSessionLaps
            ir.raceLaps = ir.sessionLaps
            # calcNeedRefuel()
        if ir.raceLaps? and ir.fuelPerLap?
            ir.raceFuel = 0.5 + ir.fuelPerLap * Math.ceil ir.raceLaps
    $rootScope.$watch 'ir.SessionNum', updateSessionLaps
    $rootScope.$watch 'ir.SessionInfo', updateSessionLaps

    updateAvgLapTimes = ->
        session = ir.SessionInfo.Sessions[ir.SessionNum]
        if session.SessionType != 'Race'
            return
        results = session.ResultsPositions
        if not results?
            return
        for pos in results
            if pos.ClassPosition != 0 or pos.CarIdx not in classCarIdxs
                continue
            carClass = ir.DriversByCarIdx[pos.CarIdx].CarClassID.toString()
            data = avgLapTimes[carClass] ?=
                lapsComplete: 0
                lapTimes: []
                avgLapTime: null
                sessionLaps: null
                sessionTimeRemain: null
            if pos.LapsComplete < 2 or pos.LapsComplete <= data.lapsComplete
                continue
            data.lapsComplete = pos.LapsComplete
            if ir.SessionState == 4 and pos.LastTime > 0
                data.lapTimes.push pos.LastTime
                console.log 'leader last lap time', pos.LastTime, 'for car class', carClass
                if ir.SessionTimeRemain? and 0 < ir.SessionTimeRemain < 604800
                    while data.lapTimes.length > maxLapTimes then data.lapTimes.shift()
                    total = 0
                    # dont count lap times that minimum + 2secs
                    minLapTime = 2 + Math.min.apply null, data.lapTimes
                    totalTimeCounts = 0
                    for t in data.lapTimes
                        if t < minLapTime
                            total += t
                            totalTimeCounts++
                    data.avgLapTime = total / totalTimeCounts
                    # ir.SessionTimeRemain + 5, update yaml take 5 seconds
                    data.sessionTimeRemain = ir.SessionTimeRemain
                    data.sessionLaps = data.lapsComplete + (ir.SessionTimeRemain + 5) / data.avgLapTime
                    console.log 'avg lap time', data.avgLapTime,
                        '| time remain', data.sessionTimeRemain,
                        '| laps', data.sessionLaps
                    # recalculate for multiclass
                    if ir.WeekendInfo.NumCarClasses > 1
                        fastClass = null
                        for carClass2 of avgLapTimes
                            if not fastClass?
                                fastClass = carClass2
                            else if avgLapTimes[carClass2].avgLapTime < avgLapTimes[fastClass].avgLapTime
                                fastClass = carClass2
                        if fastClass? and fastClass != carClass
                            fastData = avgLapTimes[fastClass]
                            # fastSessionTimeRemain = Math.ceil(fastData.sessionLaps - fastData.lapsComplete) * fastData.avgLapTime
                            # fastSessionTimeRemain = Math.ceil(ir.SessionTimeRemain / fastData.avgLapTime) * fastData.avgLapTime
                            # data.sessionLaps = data.lapsComplete + fastSessionTimeRemain / data.avgLapTime

                            # data.sessionLaps = Math.ceil(fastData.sessionLaps) * fastData.avgLapTime / data.avgLapTime

                            fastSessionTimeRemain = Math.ceil(fastData.sessionLaps - fastData.lapsComplete) * fastData.avgLapTime
                            fastSessionTimeRemain -= fastData.sessionTimeRemain - data.sessionTimeRemain
                            fastSessionTimeRemain = Math.max 1, fastSessionTimeRemain
                            data.sessionLaps = data.lapsComplete + fastSessionTimeRemain / data.avgLapTime
                            console.log 'recalc cause multiclass:',
                                'fast car class', fastClass, '| car class', carClass2,
                                '| time remain', fastSessionTimeRemain,
                                '| laps', sessionLaps

    $rootScope.$watch 'ir.connected', (n, o) ->
        # lapWatcher?()
        # lapWatcher = null
        fuels = []
        lastDist = null
        lapStarted = false
        lapsComplete = 0
        lastFuelLevel = null
        carClassId = null
        classCarIdxs = []
        avgLapTimes = {}
        watchPlayerTrackSurface?()
        watchPlayerTrackSurface = null
        loadedPrevFuelUsage = false
        if n
            ir.needToAnnounce = false
            ir.fuelPerLap = null
            ir.fuelRemainLaps = null
            ir.fuelNeedRefuel = null
            ir.sessionLaps = null
            ir.carId = null
            # test
            # ir.fuelPerLap = 1.75
            # ir.fuelRemainLaps = 51.64
            # ir.fuelNeedRefuel = 37.18
            # ir.raceLaps = 45.95
            # ir.raceFuel = 112.5

    return iRService
