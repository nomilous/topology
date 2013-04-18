ng = angular.module 'client', ['viewport', 'socket', 'topology']

ng.config ($routeProvider) -> 

    $routeProvider.when '/',

        controller: ClientController
        templateUrl: 'client.html'

    $routeProvider.otherwise 

        redirectTo: '/'


ClientController = ($log, actorService, socketService, topologyService) ->

    $log.info 'init ClientController'

    socketService.register

        label: 'me', (err, payload) -> 

            topologyService.init

                long: '18.49963'
                lat: '-34.36157'
                alt: '100'
                
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

    geometry.vertices[0].y = 100  # 
    console.log geometry.vertices[0]


    actorService.add

        _id: 'topology'
        object: new THREE.Mesh geometry, material

        
