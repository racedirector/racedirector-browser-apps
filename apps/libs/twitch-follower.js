module.exports = class TwitchFollowers
    constructor: (@channelId, token, clientId, @checkEvery, @callback) ->
        @followers = []
        @headers =
            authorization: "Bearer #{token}"
            'client-id': clientId
        @checkLastAmountFollowers = 10
        @grabFollowers()

    getFollowers: (limit, success, error) ->
        try
            url = new URL 'https://api.twitch.tv/helix/users/follows'
            params = new URLSearchParams
            params.set 'to_id', @channelId
            params.set 'first', limit
            url.search = params
            res = await fetch url, headers: @headers
            data = await res.json()
            if not res.ok
                console.error data
                error? data
            else
                # console.log data
                success data
        catch error
            console.error error
            error? data

    grabFollowers: (limit=100, attempt=1) ->
        @getFollowers limit,
            (data) =>
                for f in data.data
                    if f.from_id not in @followers
                        @followers.push f.from_id
                @callback? null, data.total
                setTimeout =>
                    @checkFollows()
                , @checkEvery * 1000
            =>
                setTimeout =>
                    @grabFollowers limit, ++attempt
                , attempt * 1000

    checkFollows: ->
        @getFollowers @checkLastAmountFollowers,
            (data) =>
                for f in data.data by -1
                    if f.from_id not in @followers
                        @followers.push f.from_id
                        @callback? f, data.total
        setTimeout =>
            @checkFollows()
        , @checkEvery * 1000
