http     = require 'http'
assets   = require 'connect-assets'
express  = require 'express'

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


        http.createServer( app ).listen 3000, -> 

            console.log 'http://localhost:3000'
