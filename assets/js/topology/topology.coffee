ng = angular.module 'topology', ['socket']

TopologyService = ($log, socketService) -> 

    service = 

        register: (opts, callback) -> 

            socketService.socket.emit 'topology:register', opts

            socketService.socket.on 'topology:register:ack', (config) ->

                callback null, config

                service.pixelScale = config.pixelScale

                #
                # ASTER GDEM is reporting 0.0002777777777777778 degrees between samples
                # 
                #   = 1 second of arc
                #   = 30 meters
                #
                # 3600 x 3600 samples per 1 degree tile
                # 
                #   3600 x 30 meters = 108 km
                # 
                # Set viewport vector units to 1 meter
                # 
                # maintain 360 x 360 grid of samples with firstperson at center
                # 
                # update the grid edge with a new row of samples whenever firstperson 
                # has moved more than 30 meters (or 1 unit) along a vector perpendicular 
                # to the edge (and remove the row on the oposite edge)
                # 

            

ng.factory 'topologyService', TopologyService
