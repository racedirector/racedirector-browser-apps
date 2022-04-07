/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const app = angular.module('ir.service', []);
app.provider('iRService', function() {
    this.options = {
        requestParams: [
            'DriverInfo',
            'SessionInfo'
        ],
        requestParamsOnce: [
            'QualifyResultsInfo'
        ],
        fps: 10
    };

    this.addOptions = function(data) {
        return (() => {
            const result = [];
            for (let k in data) {
                const v = data[k];
                var optV = this.options[k];
                if ((optV != null) && angular.isArray(optV) && angular.isArray(v)) {
                    result.push(Array.from(v).filter((p) => !Array.from(optV).includes(p)).map((p) =>
                        optV.push(p)));
                } else {
                    result.push(this.options[k] = v);
                }
            }
            return result;
        })();
    };

    this.serviceOnly = function() {
        return this.options = {fps: 1};
    };

    this.$get = function($rootScope, config) {
        const ir = new IRacing(this.options.requestParams, this.options.requestParamsOnce,
            config.fps || this.options.fps, config.server || this.options.server, this.options.readIbt,
            config.record, config.zipLibPath);

        ir.onConnect = function(update) {
            if (update == null) { update = true; }
            ir.data.connected = true;
            if (update) {
                return $rootScope.$apply();
            }
        };

        ir.onDisconnect = function(update) {
            if (update == null) { update = true; }
            ir.data.connected = false;
            if (update) {
                return $rootScope.$apply();
            }
        };

        ir.onUpdate = function(keys, update) {
            if (update == null) { update = true; }
            if (Array.from(keys).includes('DriverInfo')) {
                updateDriversByCarIdx();
            }
            if (Array.from(keys).includes('SessionInfo')) {
                updatePositionsByCarIdx();
                updateQualifyResultsByCarIdx();
            }
            if (Array.from(keys).includes('QualifyResultsInfo')) {
                updateQualifyResultsByCarIdx();
            }
            // test
            // ir.data.CamCarIdx = 19
            // ir.data.CamCarIdx = 1 + (ir.record.currentFrame / 10 % 25 | 0)
            // test
            // @onmessage = ->
            // test non metric for fuel calc
            // if 'DisplayUnits' in keys
            //     ir.data.DisplayUnits = 0
            if (update) {
                return $rootScope.$apply();
            }
        };

        ir.onBroadcast = data => $rootScope.$broadcast('broadcastMessage', data);

        var updateDriversByCarIdx = function() {
            if (ir.data.DriversByCarIdx == null) { ir.data.DriversByCarIdx = {}; }
            return Array.from(ir.data.DriverInfo.Drivers).map((driver) =>
                (ir.data.DriversByCarIdx[driver.CarIdx] = driver));
        };

        var updatePositionsByCarIdx = function() {
            if (ir.data.PositionsByCarIdx == null) { ir.data.PositionsByCarIdx = []; }
            return (() => {
                const result = [];
                for (var i = 0; i < ir.data.SessionInfo.Sessions.length; i++) {
                    const session = ir.data.SessionInfo.Sessions[i];
                    while (i >= ir.data.PositionsByCarIdx.length) {
                        ir.data.PositionsByCarIdx.push({});
                    }
                    if (session.ResultsPositions) {
                        result.push(Array.from(session.ResultsPositions).map((position) =>
                            (ir.data.PositionsByCarIdx[i][position.CarIdx] = position)));
                    } else {
                        result.push(undefined);
                    }
                }
                return result;
            })();
        };

        var updateQualifyResultsByCarIdx = function() {
            if (ir.data.QualifyResultsByCarIdx == null) { ir.data.QualifyResultsByCarIdx = {}; }
            const results = (ir.data.QualifyResultsInfo != null ? ir.data.QualifyResultsInfo.Results : undefined) || (ir.data.SessionInfo.Sessions[ir.data.SessionNum] != null ? ir.data.SessionInfo.Sessions[ir.data.SessionNum].QualifyPositions : undefined) || [];
            return Array.from(results).map((position) =>
                (ir.data.QualifyResultsByCarIdx[position.CarIdx] = position));
        };

        $rootScope.ir = ir.data;
        return ir;
    };

});
