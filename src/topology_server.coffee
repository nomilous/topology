class TopologyServer

    constructor: (properties) -> 

        for prop of properties

            @[prop] = properties[prop]

        throw 'missing app' unless @app
        throw 'missing socket' unless @socket


module.exports = TopologyServer
