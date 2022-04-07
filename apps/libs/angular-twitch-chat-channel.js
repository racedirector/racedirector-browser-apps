// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
// also need in twitch-chat
// https://api.twitch.tv/kraken/oauth2/authorize?client_id=4lpom5pnvv6hvsqs034mia4zv0gwcs&redirect_uri=http://localhost&response_type=token

angular.module('twitch-chat-channel', [])
.directive('twitchChatChannel', ($sce, $http, $compile) => ({
    scope: {
        channel: '=ngModel',
        channelID: '=twitchChatChannel',
        save: '<ngChange'
    },

    link(scope, element, attrs) {
        let twitchUser = null;
        let twitchUserPending = false;
        let twitchUserPendingValue = null;
        const parentEl = element.parent();
        const headers = {
            // accept: 'application/vnd.twitchtv.v5+json'
            authorization: 'Bearer 3hmuyd8o3ztryxgg4nbja9jgz8kmwl',
            'client-id': '4lpom5pnvv6hvsqs034mia4zv0gwcs'
        };

        return scope.$watch('channel', function(newValue, oldValue) {
            let url;
            if ((newValue == null) || ((oldValue != null) && (newValue.toLowerCase() === oldValue.toLowerCase()))) {
                if (!twitchUser) {
                    if (scope.channelID && !twitchUserPending) {
                        twitchUserPending = true;
                        // url = $sce.trustAsResourceUrl "https://api.twitch.tv/kraken/users/#{scope.channelID}"
                        url = $sce.trustAsResourceUrl('https://api.twitch.tv/helix/users');
                        $http.get(url, {headers, params: {id: scope.channelID}})
                        .then(function(result) {
                            if (__guard__(result.data != null ? result.data.data : undefined, x => x.length)) {
                                twitchUser = result.data.data[0];
                                scope.channel = twitchUser.display_name.toLowerCase() === twitchUser.login.toLowerCase() ? twitchUser.display_name : twitchUser.login;
                                return parentEl.toggleClass('has-error', false);
                            } else {
                                return parentEl.toggleClass('has-error', true);
                            }}).catch(() => parentEl.toggleClass('has-error', true)).finally(() => twitchUserPending = false);
                    }
                } else {
                    scope.channel = twitchUser.display_name.toLowerCase() === twitchUser.login.toLowerCase() ? twitchUser.display_name : twitchUser.login;
                }
                return;
            }

            if (!newValue) {
                parentEl.toggleClass('has-error', false);
                scope.channelID = '';
                scope.$applyAsync(scope.save);
                return;
            }

            twitchUser = null;
            twitchUserPending = true;
            twitchUserPendingValue = newValue;
            // url = $sce.trustAsResourceUrl 'https://api.twitch.tv/kraken/users'
            url = $sce.trustAsResourceUrl('https://api.twitch.tv/helix/users');
            return $http.get(url, {headers, params: {login: newValue}})
            .then(function(result) {
                if (__guard__(result.data != null ? result.data.data : undefined, x => x.length)) {
                    twitchUser = result.data.data[0];
                    scope.channel = twitchUser.display_name.toLowerCase() === twitchUser.login.toLowerCase() ? twitchUser.display_name : twitchUser.login;
                    scope.channelID = twitchUser.id;
                    scope.$applyAsync(scope.save);
                    twitchUserPendingValue = null;
                    return parentEl.toggleClass('has-error', false);
                } else {
                    // scope.channelID = ''
                    // scope.$applyAsync scope.save
                    return parentEl.toggleClass('has-error', true);
                }}).catch(() => parentEl.toggleClass('has-error', true)).finally(() => twitchUserPending = false);
        });
    }
}));

        // scope.channel = (newValue) ->
        //     if newValue?
        //         twitchUser = null
        //         twitchUserPending = true
        //         twitchUserPendingValue = newValue
        //         if newValue
        //             $http.jsonp $sce.trustAsResourceUrl('https://api.twitch.tv/kraken/users'),
        //                 params:
        //                     api_version: 5
        //                     client_id: clientId
        //                     login: newValue
        //             .then (result) ->
        //                 if result.data?.users?.length
        //                     twitchUser = result.data.users[0]
        //                     scope.channelID = twitchUser._id
        //                     scope.$applyAsync scope.save
        //                     twitchUserPendingValue = null
        //                     parentEl.toggleClass 'has-error', false
        //                 else
        //                     scope.channelID = ''
        //                     scope.$applyAsync scope.save
        //                     parentEl.toggleClass 'has-error', true
        //             .catch ->
        //                 parentEl.toggleClass 'has-error', true
        //             .finally ->
        //                 twitchUserPending = false
        //     else
        //         if not twitchUser
        //             if scope.channelID and not twitchUserPending
        //                 twitchUserPending = true
        //                 $http.jsonp $sce.trustAsResourceUrl("https://api.twitch.tv/kraken/users/#{scope.channelID}"),
        //                     params:
        //                         api_version: 5
        //                         client_id: clientId
        //                 .then (result) ->
        //                     if result.data?
        //                         twitchUser = result.data
        //                         parentEl.toggleClass 'has-error', false
        //                     else
        //                         parentEl.toggleClass 'has-error', true
        //                 .catch ->
        //                     parentEl.toggleClass 'has-error', true
        //                 .finally ->
        //                     twitchUserPending = false
        //             else
        //                 return twitchUserPendingValue
        //         else
        //             return twitchUser.display_name

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}