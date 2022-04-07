// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let IRacing;
window.IRacing = (IRacing = class IRacing {
    constructor(requestParams, requestParamsOnce, fps, server, readIbt, record=null) {
        if (requestParams == null) { requestParams = []; }
        this.requestParams = requestParams;
        if (requestParamsOnce == null) { requestParamsOnce = []; }
        this.requestParamsOnce = requestParamsOnce;
        if (fps == null) { fps = 1; }
        this.fps = fps;
        if (server == null) { server = '127.0.0.1:8182'; }
        this.server = server;
        if (readIbt == null) { readIbt = false; }
        this.readIbt = readIbt;
        this.record = record;
        this.data = {};
        this.onConnect = null;
        this.onDisconnect = null;
        this.onUpdate = null;

        this.ws = null;
        this.onWSConnect = null;
        this.onWSDisconnect = null;
        this.reconnectTimeout = null;

        this.connected = false;
        this.firstTimeConnect = true;

        if (record != null) {
            this.loadRecord();
        } else {
            this.connect();
        }
    }

    connect() {
        this.ws = new WebSocket(`ws://${this.server}/ws`);
        this.ws.onopen = function() { return this.onopen.apply(this, arguments); }.bind(this);
        this.ws.onmessage = function() { return this.onmessage.apply(this, arguments); }.bind(this);
        return this.ws.onclose = function() { return this.onclose.apply(this, arguments); }.bind(this);
    }

    onopen() {
        if (typeof this.onWSConnect === 'function') {
            this.onWSConnect();
        }

        if (this.reconnectTimeout != null) {
            clearTimeout(this.reconnectTimeout);
        }

        for (let k in this.data) {
            delete this.data[k];
        }

        return this.ws.send(JSON.stringify({
            fps: this.fps,
            readIbt: this.readIbt,
            requestParams: this.requestParams,
            requestParamsOnce: this.requestParamsOnce
        })
        );
    }

    onmessage(event) {
        let k;
        const data = JSON.parse(event.data.replace(/\bNaN\b/g, 'null'));

        // on disconnect
        if (data.disconnected) {
            this.connected = false;
            if (this.onDisconnect) {
                this.onDisconnect();
            }
        }

        // clear data on connect
        if (data.connected) {
            for (k in this.data) {
                delete this.data[k];
            }
        }

        // on connect or first time connect
        if (data.connected || (this.firstTimeConnect && !this.connected)) {
            this.firstTimeConnect = false;
            this.connected = true;
            if (this.onConnect) {
                this.onConnect();
            }
        }

        // update data
        if (data.data) {
            const keys = [];
            for (k in data.data) {
                const v = data.data[k];
                keys.push(k);
                this.data[k] = v;
            }
            if (this.onUpdate) {
                return this.onUpdate(keys);
            }
        }
    }

    onclose() {
        if (typeof this.onWSDisconnect === 'function') {
            this.onWSDisconnect();
        }
        if (this.ws) {
            this.ws.onopen = (this.ws.onmessage = (this.ws.onclose = null));
        }
        if (this.connected) {
            this.connected = false;
            if (this.onDisconnect) {
                this.onDisconnect();
            }
        }
        return this.reconnectTimeout = setTimeout((() => this.connect.apply(this)), 2000);
    }

    sendCommand(command, ...args) {
        return this.ws.send(JSON.stringify({
            command,
            args
        })
        );
    }

    loadRecord() {
        const r = new XMLHttpRequest();
        r.onreadystatechange = function() {
            if ((r.readyState === 4) && (r.status === 200)) {
                const data = JSON.parse(r.responseText);
                return console.log(data);
            }
        };
        r.open('GET', this.record, true);
        return r.send();
    }
});
