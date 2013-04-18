#
# Partial Tiff implementation with GeoTif extensions
# 

fs = require 'fs'

class GeoTiff

    constructor: (@filename) -> 

    loadFile: (@callback) -> 

        fs.readFile @filename, (err, @buffer) =>

            if err
                callback err
                return

            #
            # byte order specified as utf8 encoded string
            # at bytes 0..1 of the file
            # 

            byteOrder = @buffer.toString('utf8', 0, 2)

            if byteOrder == 'II'

                #
                # little endian
                #
                # shortFn and longFn as the buffer functions
                # to read the types (per LE of BE endian-ness)
                # 

                @shortFn  = 'readUInt16LE'
                @longFn   = 'readUInt32LE'
                @doubleFn = 'readDoubleLE'

            else if byteOrder == 'MM'

                #
                # big endian
                #

                @shortFn = 'readUInt16BE'
                @longFn  = 'readUInt32BE'
                @doubleFn = 'readDoubleBE'

            else 

                @callback 'NOT TIFF'
                return

            #
            # bytes 2..3 as short should = 42 or it's not a tif
            #

            unless @buffer[@shortFn](2) == 42

                @callback 'NOT TIFF'
                return


            #
            # First IFD (Image File Directory) offset
            # at long at bytes 4..7
            #

            offset = @buffer[@longFn](4)

            @decodeRaster @loadIFD offset

    loadIFD: (offset) -> 

        IFD = {}

        #
        # count of records in the IFD
        # 

        count = @buffer[@shortFn] offset
        offset += 2

        for seq in [0..count-1]

            #
            # IFD record offset 
            # each IFD record is 12 bytes
            #

            IFDoffset = offset + seq * 12

            tag = @buffer[@shortFn] IFDoffset
            IFDoffset += 2

            type = @buffer[@shortFn] IFDoffset
            IFDoffset += 2

            valuesCount = @buffer[@longFn] IFDoffset
            IFDoffset += 4

            valuesOffset = @buffer[@longFn] IFDoffset

            record = 

                tag: tag
                type: type
                valuesCount: valuesCount
                valuesOffset: valuesOffset

            switch tag

                when 256

                    IFD.width = @getRecord record

                when 257

                    IFD.length = @getRecord record

                when 258

                    IFD.bitsPerSample = @getRecord record

                when 259

                    IFD.compressed = @getRecord record

                    if IFD.compressed != 1

                        @callback 'COMPRESSION NOT SUPPORTED'
                        return

                when 262

                    IFD.photometric = @getRecord record

                    #
                    # 0 - white is ZERO
                    # 1 - black is ZERO
                    # 

                when 269

                    IFD.name = @getRecord record

                when 270

                    IFD.description = @getRecord record

                when 273

                    IFD.stripOffsets = @getRecord record

                when 277

                    IFD.samplesPerPixel = @getRecord record

                when 278

                    IFD.rowsPerStrip = @getRecord record

                when 279

                    IFD.stripByteCounts = @getRecord record

                when 282

                    IFD.xResolution = @getRecord record

                when 283

                    IFD.yResolution = @getRecord record

                when 284

                    IFD.planarConfig = @getRecord record

                    #
                    # 1 - pixels as chunky 
                    # 2 - pixels as planar
                    # 
                    # um...? not relevant - GeoTiff is greyscale
                    # 

                when 296

                    IFD.resolutionUnit = @getRecord record

                    #
                    # 1 - no absolute unit
                    # 2 - inch [default]
                    # 3 - centimeter
                    # 

                when 305

                    IFD.software = @getRecord record

                when 306

                    IFD.timestamp = @getRecord record

                

                when 339

                    IFD.sampleFormat = @getRecord record

                    #
                    # how to interpret each data sampl in pixel
                    # 
                    # 1 - unsigned integer data
                    # 2 - two’s complement signed integer data
                    # 3 - IEEE floating point data
                    # 4 - undefined data format
                    # 


                #
                # GetTIFF specific etensions
                #

                when 33550 

                    #
                    # Pixel Scale Reference
                    # ---------------------
                    # 
                    # [ScaleX, ScaleY, ScaleZ]
                    # 
                    # This tag may be used to specify the size of raster pixel spacing in the
                    # model space units, when the raster space can be embedded in the model
                    # space coordinate system without rotation
                    # 
                    # eg. pixelScale: [ 0.0002777777777777778, 0.0002777777777777778, 0 ]
                    # 
                    #     each pixel spans 0.00027 degrees 
                    #     
                    #     (degrees being the model space units)
                    # 


                    IFD.modelPixelScale = @getRecord record


                when 33922

                    # 
                    # Geographical Location Reference
                    # -------------------------------
                    #
                    # [I,J,K,  X,Y,Z]
                    # 
                    # Raster point pixel to modelspace map 
                    # 
                    # eg. geoReference: [ 0, 0, 0, 18.365694444444447, -33.89736111111111, 0 ]
                    #
                    #     top left pixel at that gps location 
                    # 

                    IFD.modelGeoReference = @getRecord record


                when 34735

                    #
                    # GeoKeyDirectoryTag:
                    # Tag = 34735 (87AF.H)
                    # Type = SHORT (2-byte unsigned short)
                    # N = variable, >= 4
                    # Alias: ProjectionInfoTag, CoordSystemInfoTag
                    # Owner: SPOT Image, Inc.
                    # 

                    continue

                
                when 34736

                    #
                    # GeoDoubleParamsTag:
                    # Tag = 34736 (87BO.H)
                    # Type = DOUBLE (IEEE Double precision)
                    # N = variable
                    # Owner: SPOT Image, Inc.
                    # 

                    continue


                when 34737

                    #
                    # GeoAsciiParamsTag:
                    # Tag = 34737 (87B1.H)
                    # Type = ASCII
                    # Owner: SPOT Image, Inc.
                    # N = variable
                    # 

                    continue


        #
        # TIFF can contain multiple pages/rasters
        # 
        # 4 bytes following this IFD recordset is 
        # the long offset of the next IFD recordset
        # 
        # not supporting multipage decode 
        #

        return IFD


    getRecord: (record) -> 

        #
        # to save space, the record is stored in the offset itself
        # if it can fit into the 4 bytes available there
        # 
        # wether or not it fits depends on the type and the 
        # count of records
        # 

        switch record.type

            when 2

                #
                # ascii
                #

                start = record.valuesOffset
                end   = record.valuesOffset + record.valuesCount - 1

                return @buffer.toString( 'utf8', start, end )

            when 3

                #
                # short 
                #

                return record.valuesOffset if record.valuesCount <= 1

                values = []
                for seq in [0..record.valuesCount - 1]
                    values.push @buffer[@shortFn] record.valuesOffset + seq * 2
                return values

            when 4

                #
                # long
                #

                return record.valuesOffset if record.valuesCount <= 1

                values = []
                for seq in [0..record.valuesCount - 1]
                    values.push @buffer[@longFn] record.valuesOffset + seq * 4
                
                return values if values.length > 1
                return values[0]

            when 5

                #
                # rational
                #
                # 2 longs (numerator/denominator)
                # 

                values = []
                for seq in [0..record.valuesCount - 1]

                    numerator   =  @buffer[@longFn] record.valuesOffset + seq * 4
                    denominator =  @buffer[@longFn] record.valuesOffset + seq * 4 + 4
                    values.push numerator/denominator

                return values if values.length > 1
                return values[0]

            when 12

                #
                # double 
                # 

                values = []
                for seq in [0..record.valuesCount - 1]
                    values.push @buffer[@doubleFn] record.valuesOffset + seq * 8
                
                return values if values.length > 1
                return values[0]


        return


    decodeRaster: (IFD) -> 

        # console.log 'decode raster defined in IFD:', IFD

        tile = 

            raster: []
            pixelScale: IFD.modelPixelScale
            geoReference: IFD.modelGeoReference



        #
        # not very efficient making arrays to control FOR loops
        # anyway...
        #

        stripSeq = [0..IFD.stripOffsets.length - 1]
        rowSeq   = [0..IFD.rowsPerStrip - 1]
        colSeq   = [0..IFD.width - 1]
        bytes    = IFD.bitsPerSample / 8

        try 

            for strip in stripSeq 

                offset     = IFD.stripOffsets[strip]
                end        = IFD.stripByteCounts[strip] + offset

                for i in rowSeq

                    #
                    # last strip may have fewer rows, only way to prevent
                    # overshooting is the strip byte length... (eek)
                    #

                    continue if offset >= end

                    row = []

                    for j in colSeq

                        continue if offset >= end  # eek again.

                        value = @buffer[@shortFn] offset
                        offset += bytes
                        row.push value

                    tile.raster.push row

        catch error

            @callback error
            return

        @callback null, tile



module.exports = GeoTiff
