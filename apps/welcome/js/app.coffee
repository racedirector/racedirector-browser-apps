app = angular.module 'welcome', [
    'ngRoute'
    'mgcrea.ngStrap.navbar'
    'kutu.markdown'
]

app.config ($routeProvider) ->
    $routeProvider
        .when '/',
            templateUrl: '/welcome/tmpl/index.html'
        .when '/docs',
            templateUrl: '/welcome/tmpl/docs.html'
            title: 'Docs'
        .otherwise redirectTo: '/'

app.run ($rootScope, $sce, $http) ->
    $rootScope.$on '$routeChangeSuccess', (event, current, previous) ->
        title = 'iRacing Browser Apps'
        if current.$$route.title?
            title = current.$$route.title + ' &middot; ' + title
        $rootScope.title = $sce.trustAsHtml title
    $rootScope.currentYear = (new Date()).getFullYear()

angular.bootstrap document, [app.name]
