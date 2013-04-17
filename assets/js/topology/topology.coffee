ng = angular.module 'topology', ['socket']

TopologyService = ($log, socketService) -> 

    service = 

        init: (opts) -> 

            socketService.socket.emit 'topology:start_at', opts
            

ng.factory 'topologyService', TopologyService
