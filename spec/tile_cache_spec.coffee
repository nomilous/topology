require('nez').realize 'TileCache', (TileCache, test, context, should) -> 

    context 'as type GeoTiff', (it) ->

        it 'expects path: in config', (done) ->

            try

                new TileCache 

                    type: 'GeoTiff'

            catch error

                error.should.match /missing path/
                test done

        it 'uses path, prefix and suffix to load tile', (done, fs) -> 

            swap = fs.readFile 
            fs.readFile = (path, callback) -> 

                fs.readFile = swap
                path.should.equal '/path/to/tiles/PREFIX_S01E001_SIFFIX'
                test done

            cache = new TileCache

                type: 'GeoTiff'
                path: '/path/to/tiles'
                prefix: 'PREFIX_'
                suffix: '_SIFFIX'

            cache.loadTile 'S01E001', ->


        it 'callback with aleady loaded tiles', (done) -> 

            cache = new TileCache

                type: 'GeoTiff'
                path: '/path/to/tiles'

            cache.tiles['ID'] = 'TILE'

            cache.loadTile 'ID', (err, tile) -> 

                tile.should.equal 'TILE'
                test done