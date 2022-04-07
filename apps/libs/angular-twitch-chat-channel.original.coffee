# also need in twitch-chat
# https://api.twitch.tv/kraken/oauth2/authorize?client_id=4lpom5pnvv6hvsqs034mia4zv0gwcs&redirect_uri=http://localhost&response_type=token

angular.module 'twitch-chat-channel', []
.directive 'twitchChatChannel', ($sce, $http, $compile) ->
    scope:
        channel: '=ngModel'
        channelID: '=twitchChatChannel'
        save: '<ngChange'
    link: (scope, element, attrs) ->
        twitchUser = null
        twitchUserPending = false
        twitchUserPendingValue = null
        parentEl = element.parent()
        headers =
            # accept: 'application/vnd.twitchtv.v5+json'
            authorization: 'Bearer 3hmuyd8o3ztryxgg4nbja9jgz8kmwl'
            'client-id': '4lpom5pnvv6hvsqs034mia4zv0gwcs'

        scope.$watch 'channel', (newValue, oldValue) ->
            if not newValue? or (oldValue? and newValue.toLowerCase() == oldValue.toLowerCase())
                if not twitchUser
                    if scope.channelID and not twitchUserPending
                        twitchUserPending = true
                        # url = $sce.trustAsResourceUrl "https://api.twitch.tv/kraken/users/#{scope.channelID}"
                        url = $sce.trustAsResourceUrl 'https://api.twitch.tv/helix/users'
                        $http.get url, headers: headers, params: id: scope.channelID
                        .then (result) ->
                            if result.data?.data?.length
                                twitchUser = result.data.data[0]
                                scope.channel = if twitchUser.display_name.toLowerCase() == twitchUser.login.toLowerCase() then twitchUser.display_name else twitchUser.login
                                parentEl.toggleClass 'has-error', false
                            else
                                parentEl.toggleClass 'has-error', true
                        .catch ->
                            parentEl.toggleClass 'has-error', true
                        .finally ->
                            twitchUserPending = false
                else
                    scope.channel = if twitchUser.display_name.toLowerCase() == twitchUser.login.toLowerCase() then twitchUser.display_name else twitchUser.login
                return

            if not newValue
                parentEl.toggleClass 'has-error', false
                scope.channelID = ''
                scope.$applyAsync scope.save
                return

            twitchUser = null
            twitchUserPending = true
            twitchUserPendingValue = newValue
            # url = $sce.trustAsResourceUrl 'https://api.twitch.tv/kraken/users'
            url = $sce.trustAsResourceUrl 'https://api.twitch.tv/helix/users'
            $http.get url, headers: headers, params: login: newValue
            .then (result) ->
                if result.data?.data?.length
                    twitchUser = result.data.data[0]
                    scope.channel = if twitchUser.display_name.toLowerCase() == twitchUser.login.toLowerCase() then twitchUser.display_name else twitchUser.login
                    scope.channelID = twitchUser.id
                    scope.$applyAsync scope.save
                    twitchUserPendingValue = null
                    parentEl.toggleClass 'has-error', false
                else
                    # scope.channelID = ''
                    # scope.$applyAsync scope.save
                    parentEl.toggleClass 'has-error', true
            .catch ->
                parentEl.toggleClass 'has-error', true
            .finally ->
                twitchUserPending = false

        # scope.channel = (newValue) ->
        #     if newValue?
        #         twitchUser = null
        #         twitchUserPending = true
        #         twitchUserPendingValue = newValue
        #         if newValue
        #             $http.jsonp $sce.trustAsResourceUrl('https://api.twitch.tv/kraken/users'),
        #                 params:
        #                     api_version: 5
        #                     client_id: clientId
        #                     login: newValue
        #             .then (result) ->
        #                 if result.data?.users?.length
        #                     twitchUser = result.data.users[0]
        #                     scope.channelID = twitchUser._id
        #                     scope.$applyAsync scope.save
        #                     twitchUserPendingValue = null
        #                     parentEl.toggleClass 'has-error', false
        #                 else
        #                     scope.channelID = ''
        #                     scope.$applyAsync scope.save
        #                     parentEl.toggleClass 'has-error', true
        #             .catch ->
        #                 parentEl.toggleClass 'has-error', true
        #             .finally ->
        #                 twitchUserPending = false
        #     else
        #         if not twitchUser
        #             if scope.channelID and not twitchUserPending
        #                 twitchUserPending = true
        #                 $http.jsonp $sce.trustAsResourceUrl("https://api.twitch.tv/kraken/users/#{scope.channelID}"),
        #                     params:
        #                         api_version: 5
        #                         client_id: clientId
        #                 .then (result) ->
        #                     if result.data?
        #                         twitchUser = result.data
        #                         parentEl.toggleClass 'has-error', false
        #                     else
        #                         parentEl.toggleClass 'has-error', true
        #                 .catch ->
        #                     parentEl.toggleClass 'has-error', true
        #                 .finally ->
        #                     twitchUserPending = false
        #             else
        #                 return twitchUserPendingValue
        #         else
        #             return twitchUser.display_name
