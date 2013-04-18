ng = angular.module 'topology', ['socket']

TopologyService = ($log, socketService) -> 

    service = 

        register: (opts, callback) -> 

            socketService.socket.emit 'topology:register', opts

            socketService.socket.on 'topology:register:ack', (config) ->

                callback null, config
            

ng.factory 'topologyService', TopologyService
