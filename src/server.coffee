http           = require 'http'
assets         = require 'connect-assets'
express        = require 'express'
io             = require 'socket.io'
TopologyServer = require './topology_server'

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


        server = http.createServer app
        socket = io.listen server

        new TopologyServer
   
            app: app
            socket: socket
            

        server.listen port, host, -> 

            console.log 'http://%s:%s',

                server.address().address, 
                server.address().port
