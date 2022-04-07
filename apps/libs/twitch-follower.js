// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let TwitchFollowers;
module.exports = (TwitchFollowers = class TwitchFollowers {
    constructor(channelId, token, clientId, checkEvery, callback) {
        this.channelId = channelId;
        this.checkEvery = checkEvery;
        this.callback = callback;
        this.followers = [];
        this.headers = {
            authorization: `Bearer ${token}`,
            'client-id': clientId
        };
        this.checkLastAmountFollowers = 10;
        this.grabFollowers();
    }

    getFollowers(limit, success, error) {
        let data;
        try {
            const url = new URL('https://api.twitch.tv/helix/users/follows');
            const params = new URLSearchParams;
            params.set('to_id', this.channelId);
            params.set('first', limit);
            url.search = params;
            const res = await(fetch(url, {headers: this.headers}));
            data = await(res.json());
            if (!res.ok) {
                console.error(data);
                return (typeof error === 'function' ? error(data) : undefined);
            } else {
                // console.log data
                return success(data);
            }
        } catch (error1) {
            error = error1;
            console.error(error);
            return (typeof error === 'function' ? error(data) : undefined);
        }
    }

    grabFollowers(limit, attempt) {
        if (limit == null) { limit = 100; }
        if (attempt == null) { attempt = 1; }
        return this.getFollowers(limit,
            data => {
                for (let f of Array.from(data.data)) {
                    if (!Array.from(this.followers).includes(f.from_id)) {
                        this.followers.push(f.from_id);
                    }
                }
                if (typeof this.callback === 'function') {
                    this.callback(null, data.total);
                }
                return setTimeout(() => {
                    return this.checkFollows();
                }
                , this.checkEvery * 1000);
            },
            () => {
                return setTimeout(() => {
                    return this.grabFollowers(limit, ++attempt);
                }
                , attempt * 1000);
        });
    }

    checkFollows() {
        this.getFollowers(this.checkLastAmountFollowers,
            data => {
                return (() => {
                    const result = [];
                    for (let i = data.data.length - 1; i >= 0; i--) {
                        const f = data.data[i];
                        if (!Array.from(this.followers).includes(f.from_id)) {
                            this.followers.push(f.from_id);
                            result.push((typeof this.callback === 'function' ? this.callback(f, data.total) : undefined));
                        } else {
                            result.push(undefined);
                        }
                    }
                    return result;
                })();
        });
        return setTimeout(() => {
            return this.checkFollows();
        }
        , this.checkEvery * 1000);
    }
});
