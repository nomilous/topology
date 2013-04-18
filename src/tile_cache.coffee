GeoTiff = require './geo_tiff'

class TileCache

    constructor: (properties) -> 

        for prop of properties

            @[prop] = properties[prop]

        throw 'missing type' unless @type
        throw 'missing path' if @type == 'GeoTiff' and not @path
        @prefix = '' unless @prefix
        @suffix = '' unless @suffix

        @tiles = {}


    loadTile: (id, callback) -> 

        #
        # TODO: remove not recently used tiles from cache
        #

        if @tiles[id]

            #
            # alreaady got tile
            #

            console.log 'cached tile "%s"', id

            callback null, @tiles[id]
            return

        console.log 'load tile "%s" from file', id

        file = @path + '/' + @prefix + id + @suffix

        new GeoTiff( file ).loadFile (err, tile) => 

            if err

                callback err
                return

            @tiles[id] = tile
            callback null, tile


module.exports = TileCache