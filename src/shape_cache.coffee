ShapeFile = require('node-shapelib-partial').ShapeFile

class ShapeCache

    constructor: (properties) -> 

        for prop of properties

            @[prop] = properties[prop]

        throw 'missing path' unless @path

        @shapeFiles = {}
        @shapes = {}


    loadShapes: (id, callback) ->

        if @shapes[id]

            console.log 'cached shapes "%s"', id
            callback null, @shapes[id]
            return

        console.log 'load shapes "%s" from file', id

        file = @path + '/' + id

        @shapeFiles[id] = new ShapeFile

        @shapeFiles[id].open file, (error, shapes) => 

            if error

                callback error
                return

            @shapes[id] = shapes
            callback null, shapes


module.exports = ShapeCache
