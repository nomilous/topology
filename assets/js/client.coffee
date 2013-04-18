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
    # plane was generated on XY, rotate to XZ
    #

    matrix = new THREE.Matrix4
    geometry.applyMatrix matrix.makeRotationX( - Math.PI / 2 )


    actorService.add

        _id: 'topology'
        object: new THREE.Mesh geometry, material
