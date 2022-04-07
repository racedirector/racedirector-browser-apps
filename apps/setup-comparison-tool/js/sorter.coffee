angular.module 'server.setup-comparison-tool.sorter', []
.service 'ServerSetupComparisonToolSorter', ($rootScope) ->
    carId = null

    $rootScope.$watch 'ir.DriverInfo', onDriverInfo = (n, o) ->
        if not n then return
        for d in n.Drivers
            if d.CarIdx == n.DriverCarIdx
                carId = d.CarID
                break

    sortHelpFunc = (list, a, b) ->
        for r, i in list when r?
            if not ai? and a.search(r) != -1 then ai = i
            if not bi? and b.search(r) != -1 then bi = i
            if ai? and bi? then break
        if not ai? and not bi?
            if a.key > b.key then 1 else if a.key < b.key then -1 else 0
        else if ai? and not bi? then -1
        else if not ai? and bi? then 1
        else ai - bi

    sortGroupFunc = (a, b) ->
        arr = [
            /tires/i
            /chassis/i
            /dampers/i
            /drive/i
        ]
        sortHelpFunc arr, a.key, b.key

    sortSectionFunc = (a, b) ->
        arr = [
            # chassis
            /^front$/i
            /incardials/i

            # dampers
            /frontheave/i

            # tires
            /leftfront/i
            /rightfront/i
            /leftrear/i
            /rightrear/i

            # aero
            /frontaero/i
            /rearaero/i
            /aeropackage/i
            /aerocalculator/i

            # drive
            /diffbuild/i
            /diffincar/i
            /pudesign/i
            /launchcontrol/i
            /gearbox/i
            /frontdiff/i
            /reardiff/i
            /drivetrain/i
        ]
        sortHelpFunc arr, a.key, b.key

    sortParameterFunc = (a, b) ->
        tires = [
            /startingpressure/i
            /coldpressure/i
            /lasthotpressure/i
            /lasttemps/i
            /tread/i
        ]
        aero = [
            /downforcetrim/i
            /frontflap/i
            /rearwing/i
            /frontrh/i
            /rearrh/i
            /frontdownforce/i
            /downforce/i
        ]
        dampers = [
            /lscomp/i
            /hscomp/i
            /compdamp/i
            /lsrbd/i
            /hsrbd/i
            /rbddamping/i
        ]
        gears = [
            /finaldrive/i
            /firstgear/i
            /secondgear/i
            /thirdgear/i
            /fourthgear/i
            /fifthgear/i
            /sixgear/i
        ]
        arr = switch carId
            # f1
            when 71 then [
                tires
                aero
                # chassis
                /ballast/i
                /noseweight/i
                /crossweight/i
                /cornerweight/i
                /rideheight/i
                /fuellevel/i
                /arbrate/i
                /arbpreload/i
                /heaverate/i
                /heaveperchoffset/i
                /torsionbaroffset$/i
                /torsionbarrate$/i
                /springdefl/i
                /camber/i
                /toein/i
                dampers
                # diff
                /entrypreload/i
                /entry/i
                /middle/i
                /exit/i
                # pudesign
                /consumption/i
                /regengain/i
                /deploymode/i
                /deploytrim/i
                /deploythrottle/i
                # break
                /brakepressure/i
                /basebrakebias/i
                /peakbrakebias$/i
                /peakbrakebiasoffset/i
                /totalpeak/i
                /beginbias/i
            ]
            # fr2.0
            when 74 then [
                tires
                aero
                /cornerweight/i
                /rideheight/i
                /pushrodlength/i
                /springrate/i
                /bump/i
                /rebound/i
                /brakepressure/i
                /crossweight/i
                /camber/i
                /toein/i
                /fuellevel/i
                /antirollbar/i
                /^arb/i
                /seventhgearratio/i
                /finaldriveoption/i
                /diffpreload/i
                /difframpangles/i
            ]
            # gt3 - mclaren, bmw, ford, merc, audi, ferrari
            when 43, 55, 59, 72, 73, 94 then [
                tires

                /brakepressure/i
                /absswitch/i
                if carId != 73 then /abs/i
                /tractioncontrolswitch/i
                /traction/i
                /throttlecontrol/i
                if carId != 94 then /throttleshape/i
                if carId == 73 then /abs/i
                /enginemap/i
                if carId == 94 then /throttleshape/i
                /leftnight/i
                /rightnight/i

                /cornerweight/i
                /rideheight/i
                /shock/i
                /bumpstop/i
                /pushrodlength/i
                /springperchoffset/i
                /springset/i
                /springselected/i
                /springrate/i
                /bumprubbers/i
                dampers
                /camber/i
                /caster/i

                /fuellevel/i
                /arbblades/i
                /arb/i
                /toein/i
                /brakepads/i
                /crossweight/i

                /gearstack$/i
                /diffclutch/i
                /diffpreload/i
                /wing/i
                /gear/i
                /gurney/i
            ]
            # v8sc
            when 60, 61 then [
                tires
                /fuellevel/i
                /noseweight/i
                /crossweight/i

                /cornerweight/i
                /rideheight/i
                /shock/i
                /bumprubbergap/i
                /damper/i
                /springperchoffset/i
                /springrate/i
                dampers
                /toein/i
                /camber/i
                /caster/i

                /brakepressure/i
                /dropgeararatio/i
                /rollcenter/i
                /arbarm/i
                /arb/i
            ]
            # ruf cspec
            when 52 then [
                tires
                /fuellevel/i
                /arbarms/i
                /toein/i
                /brakepressurebias/i

                /cornerweight/i
                /rideheight/i
                /shock/i
                /bumpstop/i
                /springperchoffset/i
                /springrate/i
                dampers
                /camber/i
                /caster/i

                /crossweight/i
                /wing/i
                /gurney/i
                /finaldriveoption/i
            ]
            # porsche cup
            when 88 then [
                tires

                /cornerweight/i
                /rideheight/i
                /springperchoffset/i
                /camber/i

                /fuellevel/i
                /arbblades/i
                /wing/i

                /toein/i
                /crossweight/i
            ]
            # rx ford fiesta, vw
            when 81, 91 then [
                tires

                /ballast/i
                /noseweight/i
                /crossweight/i

                /cornerweight/i
                /rideheight/i
                /springperchoffset/i
                /springrate/i
                /bump/i
                /rebound/i
                /camber/i

                /fuellevel/i
                /antirollbardiameter/i
                /antirollbarbladelength/i
                /toein/i
                /brakepressurebias/i

                gears

                /clutchplates/i
                /preload/i
                /driverampangle/i
            ]
            # gte - ford, ferrari, porsche, bmw
            when 92, 93, 102, 109 then [
                tires

                /displaypage/i
                /brakepressurebias/i
                /tractioncontrolsetting/i
                /tractioncontrolsetting1/i
                /tractioncontrolsetting2/i
                /traccontrolslipsetting/i
                if carId == 109 then /throttleshape/i
                /boostmap/i
                /enginemap/i
                /throttleshape/i
                /leftnight/i
                /rightnight/i
                /fuelusetarget/i

                /cornerweight/i
                /rideheight/i
                /torsionbarpreload/i
                /torsionbarod/i
                /springperchoffset/i
                /springrate/i
                dampers
                /camber/i
                /caster/i

                if carId != 102 then /fuellevel/i
                /arbstiffness/i
                /arbblades/i
                /arbsetting/i
                /arb/i
                /toein/i
                /brakepads/i
                if carId == 102 then /fuellevel/i
                /crossweight/i

                gears
                /clutchplates/i
                /coast/i
                /drive/i
                /clutch/i
                /preload/i
            ]
            else
                tires

        sortHelpFunc [].concat(arr...), a.key, b.key

    return {
        sortGroupFunc: sortGroupFunc
        sortSectionFunc: sortSectionFunc
        sortParameterFunc: sortParameterFunc
    }
