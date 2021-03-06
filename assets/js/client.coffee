ng = angular.module 'client', ['viewport', 'socket', 'topology', 'shape']

ng.config ($routeProvider) -> 

    $routeProvider.when '/',

        controller: ClientController
        templateUrl: 'client.html'

    $routeProvider.otherwise 

        redirectTo: '/'


ng.directive 'infoPanel', ($log, firstPersonService, animateService) -> 
    
    restrict: 'E'

    compile: (elem, attrs) -> 

        position = firstPersonService.camera.position

        animateService.on 'after:animate', -> 

            elem[0].innerHTML = """

                x: #{Math.round(position.x * 100) / 100} <br />
                y: #{Math.round(position.y * 100) / 100} <br />
                z: #{Math.round(position.z * 100) / 100} <br />

            """


ClientController = ($log, actorService, socketService, topologyService, shapeService, firstPersonService) ->

    socketService.register

        label: 'me', (err, config) -> 

            $log.info 'register config', config

    #
    # viewport vector unit as 1 meter
    #
    # 
    # North +z
    # West  +x
    # South -z
    # East  -x
    # Up    +y
    # Down  -y
    #

    topologyService.register {

        #
        # active grid of elevation samples 
        # as 360 x 360 square with firstperson
        # at center
        #

        width: 360 

        #
        # first person position on geoid
        # 
        # topology register response will contain 
        # the 360 x 360 samples that surround this
        # position
        #

        long: firstPersonService.longitude
        lat: firstPersonService.latitude


        #
        # first person altitude above geoid (not above ground level)
        # 

        alt: firstPersonService.altitude


    }, (err, config) -> 

        $log.info 'topology config', config
                


    shapeService.register {

        id: 'ne_50m_land'

    }, (error, shapeData) ->

        return if error

        for i in [0..shapeData.count - 1]

            material = new THREE.LineBasicMaterial color: 0x777777, linewidth: 1
            geometry = new THREE.Geometry

            vertices = shapeData.shapes[i].vertices

            for j in [0..vertices.length - 1]

                longitude = vertices[j][0]
                latitude  = vertices[j][1]
                altitude  = 0

                geometry.vertices.push topologyService.transform longitude, latitude, altitude

            line = new THREE.Line geometry, material
            
            actorService.add

                _id: 'ne_50m_land:' + i
                object: line

        return

    #
    # create wireframe reference plane 
    #

    # geometry = new THREE.PlaneGeometry 2000, 2000, 40, 40
    # material = new THREE.MeshBasicMaterial color: 0x000000, wireframe: true


    #
    # plane was generated on XY with 0:0 at -X+Y
    # rotate 90 degrees about X to set the plane onto ZX
    # rotate 90 degrees about Y to set 0:0 to +X+Z as NorthWest corner
    # 

    # matrix = new THREE.Matrix4
    # geometry.applyMatrix matrix.makeRotationX( Math.PI / 2 )
    # geometry.applyMatrix matrix.makeRotationY( Math.PI / 2 )

    #
    # raise corner at 0:0 to confirm NORTH WEST
    #

    # geometry.vertices[0].y = 100


    # actorService.add

    #     _id: 'topology'
    #     object: new THREE.Mesh geometry, material

        
