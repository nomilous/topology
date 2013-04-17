ng = angular.module 'socket', []

SocketService = ($log) -> 

    service = 

        register: (opts, callback) -> 

            service.socket = io.connect()

            service.socket.on 'connect', ->

                service.socket.emit 'person:register', opts

            service.socket.on 'person:register:ok', (payload) ->

                callback null, payload


ng.factory 'socketService', SocketService
