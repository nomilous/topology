class ShapeServer

    constructor: (properties) ->

        for prop of properties

            @[prop] = properties[prop]

        throw 'missing app' unless @app
        throw 'missing sockets' unless @sockets
        throw 'missing cache' unless @cache

        @sockets.on 'connection', (socket) => 

            socket.on 'shape:register', (payload) =>

                id = payload.id

                @loadShapes id, (err, shapes) -> 

                    socket.emit 'shape:register:ack', shapes


    loadShapes: (id, callback) -> 

        console.log 'TODO: multiple concurrent clients on requesting the same uncached tile cause a simultanoues load from disk'

        @cache.loadShapes id, callback

module.exports = ShapeServer
