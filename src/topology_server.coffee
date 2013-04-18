TileCache = require './tile_cache' 

class TopologyServer

    constructor: (properties) -> 

        for prop of properties

            @[prop] = properties[prop]

        throw 'missing app' unless @app
        throw 'missing sockets' unless @sockets
        throw 'missing cache' unless @cache

        @sockets.on 'connection', (socket) => 

            #
            # put more thought into protocol later
            # still on discovery path
            # 

            socket.on 'person:register', (person) -> 

                person.key = 'KEY'
                socket.emit 'person:register:ok', person


            socket.on 'topology:start_at', (payload) => 

                @startAt 

                    socket: socket
                    payload: payload


    startAt: (params) ->

        throw 'missing socket' unless params.socket
        throw 'missing payload' unless params.payload

        lat  = params.payload.lat
        long = params.payload.long



        if lat < 0

            latVal = Math.floor( - lat )
            latDir = 'S'

        else

            latVal = Math.ceil lat
            latDir = 'N'

        if long < 0

            longVal = Math.ceil( - long )
            longDir = 'W'

        else 

            longVal = Math.floor( long )
            longDir = 'E'



        if latVal < 10 then latVal = '0' + latVal
        if longVal < 10 then longVal = '00' + longVal
        else if longVal < 100 then longVal = '0' + longVal

        tileID = latDir + latVal + longDir + longVal

        @loadTile tileID


    loadTile: (id) -> 

        console.log '\n\nload tile:', id



module.exports = TopologyServer
