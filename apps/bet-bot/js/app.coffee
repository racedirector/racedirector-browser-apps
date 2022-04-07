app = angular.module 'bet-bot', [
    'ngRoute'
    'mgcrea.ngStrap.navbar'
    'kutu.markdown'
]

app.config ($routeProvider) ->
    $routeProvider
        .when '/',
            templateUrl: 'tmpl/index.html'
        .otherwise redirectTo: '/'

app.run ($rootScope, $sce) ->
    $rootScope.$on '$routeChangeSuccess', (event, current, previous) ->
        title = 'Twitch Bet Bot &middot; iRacing Browser Apps'
        if current.$$route.title?
            title = current.$$route.title + ' &middot; ' + title
        $rootScope.title = $sce.trustAsHtml title

angular.bootstrap document, [app.name]
