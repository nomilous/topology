ng = angular.module 'shape', ['socket']

ShapeService = ($log, socketService) -> 

    service = 

        register: (opts, callback) -> 

            socketService.socket.emit 'shape:register', opts

            socketService.socket.on 'shape:register:ack', (shapes) ->

                callback null, shapes


ng.factory 'shapeService', ShapeService
