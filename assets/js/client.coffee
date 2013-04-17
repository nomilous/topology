ng = angular.module 'client', []

ng.config ($routeProvider) -> 

    $routeProvider.when '/',

        controller: ClientController
        templateUrl: 'client.html'

    $routeProvider.otherwise 

        redirectTo: '/'


ClientController = ($log) ->

    $log.info 'init ClientController' 

    
