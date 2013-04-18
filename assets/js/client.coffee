ng = angular.module 'client', ['viewport', 'socket', 'topology']

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


ClientController = ($log, actorService, socketService, topologyService) ->

    socketService.register

        label: 'me', (err, config) -> 

            $log.info 'register config', config

    topologyService.register

        long: '18.49963'
        lat: '-34.36157'
        alt: '100', (err, config) -> 

            $log.info 'topology config', config
                
    #
    # create wireframe reference plane 
    #

    geometry = new THREE.PlaneGeometry 2000, 2000, 40, 40
    material = new THREE.MeshBasicMaterial color: 0x000000, wireframe: true

    # 
    # North +z
    # West  +x
    # South -z
    # East  -x
    # Up    +y
    # Down  -y
    #

    #
    # plane was generated on XY with 0:0 at -X+Y
    # rotate 90 degrees about X to set the plane onto ZX
    # rotate 90 degrees about Y to set 0:0 to +X+Z as NorthWest corner
    # 

    matrix = new THREE.Matrix4
    geometry.applyMatrix matrix.makeRotationX( Math.PI / 2 )
    geometry.applyMatrix matrix.makeRotationY( Math.PI / 2 )

    #
    # raise corner at 0:0 to confirm NORTH WEST
    #

    geometry.vertices[0].y = 100


    actorService.add

        _id: 'topology'
        object: new THREE.Mesh geometry, material

        
