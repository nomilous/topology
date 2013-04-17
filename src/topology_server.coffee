class TopologyServer

    constructor: (properties) -> 

        for prop of properties

            @[prop] = properties[prop]

        throw 'missing app' unless @app
        throw 'missing sockets' unless @sockets

        @sockets.on 'connection', (socket) -> 

            #
            # put more thought into protocol later
            # still on discovery path
            # 

            socket.on 'person:register', (person) -> 

                person.key = 'KEY'
                socket.emit 'person:register:ok', person


            socket.on 'topology:start_at', (payload) -> 

                console.log '\n\ntopology:start_at:\n', payload



module.exports = TopologyServer
