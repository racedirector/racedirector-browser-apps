app = angular.module 'setup-cover', [
    'ngRoute'
    'mgcrea.ngStrap.navbar'
    'LocalStorageModule'
    'kutu.markdown'
]

app.config ($routeProvider) ->
    $routeProvider
        .when '/',
            templateUrl: 'tmpl/index.html'
        .otherwise redirectTo: '/'

app.config (localStorageServiceProvider) ->
    localStorageServiceProvider.setPrefix app.name

app.run ($rootScope, $sce) ->
    $rootScope.$on '$routeChangeSuccess', (event, current, previous) ->
        title = 'Setup Cover &middot; iRacing Browser Apps'
        if current.$$route.title?
            title = current.$$route.title + ' &middot; ' + title
        $rootScope.title = $sce.trustAsHtml title

#      __  .__   __.  __  .___________.
#     |  | |  \ |  | |  | |           |
#     |  | |   \|  | |  | `---|  |----`
#     |  | |  . `  | |  |     |  |
#     |  | |  |\   | |  |     |  |
#     |__| |__| \__| |__|     |__|
#

angular.bootstrap document, [app.name]
