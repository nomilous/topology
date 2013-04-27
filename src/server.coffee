http           = require 'http'
assets         = require 'connect-assets'
express        = require 'express'
io             = require 'socket.io'
TopologyServer = require './topology_server'
TileCache      = require './tile_cache'
ShapeServer    = require './shape_server'
ShapeCache     = require './shape_cache'

host           = 'localhost'
port           = 3000

module.exports = 

    start: (root) -> 

        app = express()


        app.set 'views', root + '/views'
        app.set 'view engine', 'jade'
        app.use express.logger 'dev'
        app.use assets()
        app.use express.static root + '/public'



        app.get '/', (req, res) -> 

            res.render 'index'


        app.get '/client.html', (req, res) -> 

            res.render 'client'


        server  = http.createServer app
        sockets = io.listen server

        new TopologyServer
   
            app: app
            sockets: sockets
            cache: new TileCache 

                type: 'GeoTiff'
                path: root + '/tiles'
                prefix: 'ASTGTM2_'
                suffix: '_dem.tif'

        new ShapeServer

            app: app
            sockets: sockets
            cache: new ShapeCache

                path: root + '/shapes'
            

        server.listen port, host, -> 

            console.log 'http://%s:%s',

                server.address().address, 
                server.address().port
