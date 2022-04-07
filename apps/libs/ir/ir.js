// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let IRacing;
window.IRacing = (IRacing = class IRacing {
    constructor(requestParams, requestParamsOnce, fps, server, readIbt, record=null, zipLibPath=null) {
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
        this.zipLibPath = zipLibPath;
        this.data = {};
        this.onConnect = null;
        this.onDisconnect = null;
        this.onUpdate = null;
        this.onBroadcast = null;

        this.ws = null;
        this.onWSConnect = null;
        this.onWSDisconnect = null;
        this.reconnectTimeout = null;

        this.connected = false;
        this.firstTimeConnect = true;

        if (this.record != null) {
            this.loadRecord();
        }
        this.connect();
    }

    connect() {
        this.ws = new WebSocket(`ws://${this.server}/ws`);
        this.ws.onopen = (...args) => this.onopen(...Array.from(args || []));
        this.ws.onmessage = (...args) => this.onmessage(...Array.from(args || []));
        return this.ws.onclose = (...args) => this.onclose(...Array.from(args || []));
    }

    close() {
        this.ws.onclose = null;
        return this.ws.close();
    }

    onopen() {
        if (typeof this.onWSConnect === 'function') {
            this.onWSConnect();
        }

        if (this.reconnectTimeout != null) {
            clearTimeout(this.reconnectTimeout);
        }

        if ((this.record == null)) {
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
    }

    onmessage(event) {
        // data = JSON.parse event.data.replace /\bNaN\b/g, 'null'
        const data = JSON.parse(event.data);

        if ((this.record == null)) {
            // on disconnect
            let k;
            if (data.disconnected) {
                this.connected = false;
                if (typeof this.onDisconnect === 'function') {
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
                if (typeof this.onConnect === 'function') {
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
                if (typeof this.onUpdate === 'function') {
                    this.onUpdate(keys);
                }
            }
        }

        // broadcast message
        if (data.broadcast) {
            return (typeof this.onBroadcast === 'function' ? this.onBroadcast(data.broadcast) : undefined);
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
            if ((this.record == null)) {
                if (typeof this.onDisconnect === 'function') {
                    this.onDisconnect();
                }
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

    broadcast(data) {
        return this.ws.send(JSON.stringify({broadcast: data}));
    }

    loadRecord() {
        const isZip = this.zipLibPath && (this.record.search(/\.zip$/i) !== -1);
        const r = new XMLHttpRequest;
        r.onreadystatechange = () => {
            if ((r.readyState === 4) && (r.status === 200)) {
                if (isZip) {
                    const {
                        head
                    } = document;
                    const zipSrc = document.createElement('script');
                    zipSrc.src = this.zipLibPath + 'zip.js';
                    head.appendChild(zipSrc);
                    return zipSrc.addEventListener('load', () => {
                        zip.useWebWorkers = false;
                        const inflateSrc = document.createElement('script');
                        inflateSrc.src = this.zipLibPath + 'inflate.js';
                        head.appendChild(inflateSrc);
                        return inflateSrc.addEventListener('load', () => {
                            return zip.createReader(new zip.BlobReader(r.response), zipReader => {
                                return zipReader.getEntries(entry => {
                                    return entry[0].getData(new zip.TextWriter, text => {
                                        (zipReader.close)();
                                        head.removeChild(inflateSrc);
                                        head.removeChild(zipSrc);
                                        return this.onRecord(JSON.parse(text));
                                    });
                                });
                            });
                        });
                    });
                } else {
                    return this.onRecord(r.response);
                }
            }
        };
        r.open('GET', this.record, true);
        r.responseType = isZip ? 'blob' : 'json';
        return r.send();
    }

    onRecord(frames) {
        this.connected = true;
        if (!('connected' in frames[0])) {
            frames.unshift({connected: true});
        }
        this.record = {
            frames,
            requestedParamsOnce: []
        };
        return (typeof this.onConnect === 'function' ? this.onConnect() : undefined);
    }

    playRecord(startFrame, stopFrame=null, speed) {
        if (startFrame == null) { startFrame = 0; }
        if (speed == null) { speed = 1; }
        this.record.currentFrame = 0;
        if (typeof this.onConnect === 'function') {
            this.onConnect(false);
        }

        let i = startFrame;
        while (i-- >= 0) {
            this.record.currentFrame++;
            this.playRecordFrame(false);
        }

        if (this.record.playInterval != null) {
            clearInterval(this.record.playInterval);
        }
        if (!speed || ((stopFrame != null) && (startFrame >= stopFrame))) {
            if (this.record.currentFrame < (this.record.frames.length - 1)) {
                return setTimeout(() => {
                    this.record.currentFrame++;
                    return this.playRecordFrame();
                }
                , 1);
            }
        } else {
            return this.record.playInterval = setInterval(() => {
                if ((this.record.currentFrame < (this.record.frames.length - 1)) && !((stopFrame != null) && (this.record.currentFrame >= stopFrame))) {
                    this.record.currentFrame++;
                    return this.playRecordFrame();
                } else {
                    return clearInterval(this.record.playInterval);
                }
            }
            , 1000 / speed);
        }
    }

    resetRecord() {
        if (this.record.playInterval != null) {
            clearInterval(this.record.playInterval);
        }
        return setTimeout(() => {
            this.record.requestedParamsOnce = [];
            for (let k in this.data) {
                delete this.data[k];
            }
            if (typeof this.onDisconnect === 'function') {
                this.onDisconnect();
            }
            return setTimeout(() => {
                return (typeof this.onConnect === 'function' ? this.onConnect() : undefined);
            }
            , 500);
        }
        , 100);
    }

    playRecordFrame(update) {
        if (update == null) { update = true; }
        const data = this.record.frames[this.record.currentFrame];
        if (data != null ? data.data : undefined) {
            const keys = [];
            for (let k in data.data) {
                const v = data.data[k];
                if (Array.from(this.requestParams).includes('__all_telemetry__') || Array.from(this.requestParams).includes(k) || 
                        (Array.from(this.requestParamsOnce).includes(k) && !Array.from(this.record.requestedParamsOnce).includes(k))) {
                    keys.push(k);
                    this.data[k] = v;
                    if (Array.from(this.requestParamsOnce).includes(k) && !Array.from(this.record.requestedParamsOnce).includes(k)) {
                        this.record.requestedParamsOnce.push(k);
                    }
                }
            }
            return (typeof this.onUpdate === 'function' ? this.onUpdate(keys, update) : undefined);
        }
    }
});
