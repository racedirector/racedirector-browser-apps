/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// also need in angular-twitch-chat-channel
// https://api.twitch.tv/kraken/oauth2/authorize?client_id=4lpom5pnvv6hvsqs034mia4zv0gwcs&redirect_uri=http://localhost&response_type=token

let TwitchChat;
window.TwitchChat = (TwitchChat = class TwitchChat {
    constructor(channel_id, divId, history=null, host) {
        this.channel_id = channel_id;
        this.divId = divId;
        this.history = history;
        if (host == null) { host = '127.0.0.1:8184'; }
        this.host = host;
        this.conn = null;
        this.reconnectTimeout = null;
        this.emoticons = {default: []};
        this.css = $('<style type="text/css">').appendTo('head');
        this.USER_COLORS = ['#ff0000', '#0000ff', '#008000', '#b22222', '#ff7f50', '#9acd32', '#ff4500', '#2e8b57', '#daa520', '#d2691e', '#5f9ea0', '#1e90ff', '#ff69b4', '#8a2be2', '#00ff7f'];
        this.clientID = '4lpom5pnvv6hvsqs034mia4zv0gwcs';
        this.token = '3hmuyd8o3ztryxgg4nbja9jgz8kmwl';
        if (this.channel_id != null ? this.channel_id.toString().startsWith('@') : undefined) {
            this.channel = this.channel_id.slice(1);
            this.channel_id = null;
        }
        this.badgesLoading = [];
        this.badgesLoaded = [];
        this.cheermotes = null;
        this.onConnected = null;
        this.onDisconnected = null;
    }

    connect(callback) {
        this.conn = new WebSocket(`ws://${this.host}/chat/websocket`);

        this.conn.onopen = () => {
            console.log('chat connected');
            if (typeof callback === 'function') {
                callback();
            }
            if (typeof this.onConnected === 'function') {
                this.onConnected();
            }
            this.conn.send(JSON.stringify({
                channel: this.channel.toLowerCase(),
                history: this.history
            })
            );
            return this.checkVersionTimeout = setTimeout(() => {
                return this.onmessage();
            }
            , 1000);
        };

        this.conn.onmessage = event => {
            if (this.checkVersionTimeout != null) {
                clearTimeout(this.checkVersionTimeout);
                delete this.checkVersionTimeout;
            }
            let {
                data
            } = event;
            if (typeof data === 'string') {
                data = JSON.parse(data);
            }
            if (this.onmessage) {
                return this.onmessage(data.username, data.message, data.data);
            }
        };

        return this.conn.onclose = () => {
            console.log('chat disconnected');
            if (typeof this.onDisconnected === 'function') {
                this.onDisconnected();
            }
            return this.reconnectTimeout = setTimeout((() => this.connect()), 2000);
        };
    }

    sendMessage(message, oauth) {
        return this.conn.send(JSON.stringify({
            oauth,
            channel: this.channel.toLowerCase(),
            message
        })
        );
    }

    getChannelByID(callback) {
        if (this.channel) {
            if (typeof callback === 'function') {
                callback();
            }
            return;
        }
        return $.ajax('https://api.twitch.tv/helix/users', {
            headers: {
                // accept: 'application/vnd.twitchtv.v5+json'
                authorization: `Bearer ${this.token}`,
                'client-id': this.clientID
            },
            data: {
                id: this.channel_id
            }
        }).done(data => {
            if (data.error != null) {
                console.log(data.status, data.error, data.message);
                setTimeout(() => {
                    return this.getChannelByID(callback);
                }
                , 1000);
                return;
            }
            this.channel = data.data[0].login;
            return (typeof callback === 'function' ? callback() : undefined);
            }).fail(() => {
            return setTimeout(() => {
                return this.getChannelByID(callback);
            }
            , 1000);
        });
    }

    getChannelID(callback) {
        if (this.channel_id) {
            if (typeof callback === 'function') {
                callback();
            }
            return;
        }
        return $.ajax('https://api.twitch.tv/helix/users', {
            headers: {
                // accept: 'application/vnd.twitchtv.v5+json'
                authorization: `Bearer ${this.token}`,
                'client-id': this.clientID
            },
            data: {
                login: this.channel
            }
        }).done(data => {
            if (data.error != null) {
                console.log(data.status, data.error, data.message);
                setTimeout(() => {
                    return this.getChannelID(callback);
                }
                , 1000);
                return;
            }
            this.channel_id = data.data[0].id;
            return (typeof callback === 'function' ? callback() : undefined);
            }).fail(() => {
            return setTimeout(() => {
                return this.getChannelID(callback);
            }
            , 1000);
        });
    }

    loadBadges(callback, roomId) {
        if (roomId == null) { roomId = 'global'; }
        if (Array.from(this.badgesLoaded).includes(roomId) || Array.from(this.badgesLoading).includes(roomId)) {
            if (typeof callback === 'function') {
                callback();
            }
            return;
        }
        if (!Array.from(this.badgesLoading).includes(roomId)) {
            this.badgesLoading.push(roomId);
        }
        return $.ajax(`https://badges.twitch.tv/v1/badges/${roomId}/display`)
        .done(data => {
            if (data.error != null) {
                console.log(data.status, data.error, data.message);
                setTimeout(() => {
                    this.badgesLoading.splice(this.badgesLoading.indexOf(roomId), 1);
                    return this.loadBadges(callback, roomId);
                }
                , 1000);
                return;
            }
            for (let type in data.badge_sets) {
                // console.log v.versions
                const v = data.badge_sets[type];
                for (let version in v.versions) {
                    const v2 = v.versions[version];
                    this.css.append(`${this.divId} .${type}${version} { background-image: url(${v2.image_url_2x}); }`);
                }
            }
                    // @css.append "#{@divId} .#{type}#{version} { background-image: -webkit-image-set(url(#{v2.image_url_1x}) 1x, url(#{v2.image_url_2x}) 2x); }"
            this.badgesLoaded.push(roomId);
            this.badgesLoading.splice(this.badgesLoading.indexOf(roomId), 1);
            return (typeof callback === 'function' ? callback() : undefined);
    }).fail(() => {
            if (typeof callback === 'function') {
                callback();
            }
            return setTimeout(() => {
                this.badgesLoading.splice(this.badgesLoading.indexOf(roomId), 1);
                return this.loadBadges(null, roomId);
            }
            , 1000);
        });
    }

    loadCheerEmotes(callback) {
        if (this.cheermotes) { return; }
        return $.ajax('https://api.twitch.tv/helix/bits/cheermotes', {
            headers: {
                // accept: 'application/vnd.twitchtv.v5+json'
                authorization: `Bearer ${this.token}`,
                'client-id': this.clientID
            },
            data: {
                broadcaster_id: this.channel_id
            }
        }).done(data => {
            if (data.error != null) {
                console.log(data.status, data.error, data.message);
                setTimeout(() => {
                    return this.loadCheerEmotes(callback);
                }
                , 1000);
                return;
            }
            this.cheermotes = {list: new Map};
            const prefixes = (() => {
                const result = [];
                for (let e of Array.from(data.data)) {
                    this.cheermotes.list.set(e.prefix.toLowerCase(), e);
                    result.push(e.prefix.toLowerCase());
                }
                return result;
            })();
            this.cheermotes.regex = new RegExp(`\\b(?<prefix>${prefixes.join('|')})(?<bits>\\d+)\\b`, 'gi');
            return (typeof callback === 'function' ? callback() : undefined);
            }).fail(() => {
            return setTimeout(() => {
                return this.loadCheerEmotes(callback);
            }
            , 1000);
        });
    }

    loadIRatings(callback) {
        return $.getJSON('https://ir-apps.kutu.ru/twitch-chat/js/wc_drivers.json')
        .done(data => {
            const wcDrivers = data;
            this.twitchToIRacingPair = {};
            for (let i of Array.from(wcDrivers)) {
                this.twitchToIRacingPair[i.user_id] = i;
            }
            return (typeof callback === 'function' ? callback() : undefined);
    }).fail(() => {
            return setTimeout(() => {
                return this.loadIRatings(callback);
            }
            , 1000);
        });
    }

    clearChat(username, strikeOut) {
        let a;
        if (username != null) {
            a = $(`${this.divId} .chat-line[data-username=${username}]`).slice(-5);
        } else {
            a = $(`${this.divId} .chat-line:not(.blank)`);
        }
        if (strikeOut) {
            return a.css({'text-decoration': 'line-through'});
        } else {
            return a.remove();
        }
    }

    escape(message) {
        return message.replace(/</g, '&lt;').replace(/>/g, '&gt;');
    }

    emoticonize(message, data, linkonize, scale) {
        if (linkonize == null) { linkonize = false; }
        if (scale == null) { scale = '1.0'; }
        if (!message) { return message; }
        const emotes = [];
        if (data.emotes != null) {
            let e, end, id, start;
            for (e of Array.from(data.emotes.split('/'))) {
                let places;
                [id, places] = Array.from(e.split(':'));
                id = id;
                for (let p of Array.from(places.split(','))) {
                    [start, end] = Array.from(p.split('-'));
                    emotes.push({
                        id,
                        start: parseInt(start),
                        end: parseInt(end)
                    });
                }
            }
            emotes.sort(function(a, b) { if (a.start > b.start) { return 1; } else if (a.start < b.start) { return -1; } else { return 0; } });
            let msg = [];
            let prevEmote = null;
            for (e of Array.from(emotes)) {
                msg.push(message.substring(((prevEmote != null ? prevEmote.end : undefined) + 1) || 0, e.start), e);
                prevEmote = e;
            }
            msg.push(message.substring(prevEmote.end + 1));
            msg = msg.map((m, i) => {
                if (i % 2) {
                    let src;
                    if (m.id.startsWith('emotesv2_')) {
                        src = `https://static-cdn.jtvnw.net/emoticons/v2/${m.id}/default/dark/${scale}`;
                    } else {
                        src = `https://static-cdn.jtvnw.net/emoticons/v1/${m.id}/${scale}`;
                    }
                    return `<img class="emoticon"
src="${src}"
alt="${message.substring(m.start, m.end + 1)}"
title="${message.substring(m.start, m.end + 1)}">`;
                } else {
                    if (linkonize) { return this.linkonize(this.escape(m)); } else { return this.escape(m); }
                }
            });
            message = msg.join('');
        } else {
            message = this.escape(message);
            if (linkonize) {
                message = this.linkonize(message);
            }
        }
        return message;
    }

    generateEmoticonCss(e, t) {
        return `.emo-${t} {\
background-image: url(${e.url});\
width: ${e.width}px;\
height: ${e.height}px;\
margin: ${(12 - e.height) >> 1}px 0;\
}`;
    }

    nameToColor(name) {
        let acc = 0;
        for (let i = 0, end = name.length, asc = 0 <= end; asc ? i < end : i > end; asc ? i++ : i--) {
            acc += name.charCodeAt(i);
        }
        return this.USER_COLORS[acc % this.USER_COLORS.length];
    }

    calculateColor(color, background) {
        // background - true for bright, false for dark
        if (background == null) { background = false; }
        if (typeof color === 'number') {
            color = `000000${color.toString(16)}`.slice(-6);
        } else {
            color = color.toLowerCase().replace(/[^0-9a-f]/g, '');
        }
        if (color.length === 3) {
            color = color[0] + color[0] + color[1] + color[1] + color[2] + color[2];
        }
        if (color.length !== 6) {
            return `#${color}`;
        }

        const hash = this.calculateColorHash != null ? this.calculateColorHash : (this.calculateColorHash = {});
        if (color in hash) {
            if (hash[color][background]) {
                return hash[color][background];
            }
        } else {
            hash[color] = {};
        }

        let out = color;
        while (true) {
            const yiq = this.calculateColorBackground(out);
            if (yiq === background) { break; }
            out = this.calculateColorReplacement(out, yiq);
        }

        return hash[color][background] = `#${out}`;
    }

    calculateColorBackground(color) {
        // Converts HEX to YIQ to judge what color background the color would look best on
        const r = parseInt(color.substr(0, 2), 16);
        const g = parseInt(color.substr(2, 2), 16);
        const b = parseInt(color.substr(4, 2), 16);
        const yiq = ((r * 299) + (g * 587) + (b * 114)) / 1000;
        return yiq < 128;
    }

    calculateColorReplacement(color, background) {
        // Modified from http://www.sitepoint.com/javascript-generate-lighter-darker-color/
        const brightness = background ? 0.2 : -0.5;

        for (let i = 0; i < 3; i++) {
            const c = Math.max(10, parseInt(color.substr(i * 2, 2), 16));
            out |= Math.round(Math.min(Math.max(0, c + (c * brightness)), 255)) << ((2 - i) * 8);
        }
        var out = `000000${out.toString(16)}`.slice(-6);

        if (color === out) {
            out = background ? 'ffffff' : '000000';
        }
        return out;
    }

    linkonize(message) {
        if (!message) { return message; }
        const arr = message.split(/((?:https?:[-a-z0-9@:%_+.~!#$*()?&\/=]*)|(?:https?:\/\/)?(?:[-a-z0-9@:%_\+~#=]{1,256}\.)+[a-z]{2,6}(?::\d+)?(?:[\/?][-a-z0-9@:%_+.~!#$*()?&\/=]*)?)/ig);
        if (arr.length > 1) {
            for (let i = 1, end = arr.length; i < end; i += 2) {
                let link = arr[i];
                if (link.search(/^https?/) === -1) {
                    link = 'http://' + link;
                }
                arr[i] = `<a href='${link}' target='_blank' rel='noreferrer'>${arr[i]}</a>`;
            }
        }
        return arr.join('');
    }

    filterBetBot(message, isBetBot) {
        if (!message) { return false; }
        if (message.search(/^\s*!bet /i) === 0) {
            return true;
        }
        if (isBetBot) {
            if (message.search('TOP5: P1') === 0) { return true; }
            if (message.search(/No one has more than [\d,]+/) === 0) { return true; }
            if (message.search(/\s*Use "!bet win 100" to make a bet./) === 0) { return true; }
            if (message.search(/, you have [\d,]+ .+/) !== -1) { return true; }
            if (message.search(/, you can bet at least half of your .+/) !== -1) { return true; }
            if (message.search(/, you can bet only all of your .+/) !== -1) { return true; }
        }
        return false;
    }

    bitonize(message, bits, type, theme, scale) {
        // console.log @cheermotes, message, bits
        let e, foundTier, t;
        if (scale == null) { scale = '1'; }
        if (!this.cheermotes) { return; }
        if (!message) { return message; }
        message = message.split(this.cheermotes.regex);
        // console.log message
        type = type ? 'animated' : 'static';
        theme = theme ? 'dark' : 'light';
        bits = parseInt(bits);
        // scale 1, 1.5, 2, 3, 4
        // obsVersion = if obsstudio? then (parseInt(i) for i in obsstudio.pluginVersion.split '.')
        // if obsVersion
        //     isOldOBS = not (obsVersion[0] >= 1 and obsVersion[1] >= 31)

        for (let i = 0; i < message.length; i += 3) {
            const v = message[i];
            if (message.length < (i + 2)) { break; }
            const prefix = message[i + 1];
            const cheerBits = parseInt(message[i + 2]);
            foundTier = null;
            // console.log @cheermotes.actions, prefix
            e = this.cheermotes.list.get(prefix.toLowerCase());
            for (t of Array.from(e.tiers)) {
                if (cheerBits >= t.min_bits) { foundTier = t; } else { break; }
            }
            message[i + 1] = '';
            const src = foundTier.images[theme][type][scale];
            // if isOldOBS
            //     src = src.replace 'https://d3aqoihi2n8ty8.cloudfront.net/', "http://#{@host}/proxy/cheers/"
            message[i + 2] = `\
<span class="bits" style="color: ${foundTier.color};">
    <img src="${src}"
         alt="${prefix}${cheerBits}"
         title="${prefix}${cheerBits}">
    ${cheerBits}
</span>`;
        }

        // bg style
        foundTier = null;
        for (e of this.cheermotes.list.values()) {
            for (t of Array.from(e.tiers)) {
                if (bits >= t.min_bits) { foundTier = t; } else { break; }
            }
            if (foundTier) { break; }
        }

        return [message.join(''), foundTier.color];
    }

    getWCByUserID(userId) {
        if ((this.twitchToIRacingPair == null) || !(userId in this.twitchToIRacingPair)) { return null; }
        return this.twitchToIRacingPair[userId];
    }

    checkEmotesSpam(message, data, max) {
        if (max == null) { max = 5; }
        if ((data.emotes == null)) { return false; }
        let count = 0;
        for (let e of Array.from(data.emotes.split('/'))) {
            const [id, places] = Array.from(e.split(':'));
            for (let p of Array.from(places.split(','))) {
                let [start, end] = Array.from(p.split('-'));
                start = parseInt(start);
                end = parseInt(end);
                message = message.substring(0, start) + ' '.repeat((end - start)+1) + message.substring(end + 1);
                count++;
            }
        }
        return (count >= max) && (message.trim().length === 0);
    }

    highlightWords(message, words) {
        if (!words || !message) { return message; }
        return message.replace(words, "<span class=\"highlight-word\">$1$2</span>");
    }
});
