ng = angular.module 'viewport', ['topology'] 

SceneService = ($log) -> 

    scene = 

        scene: new THREE.Scene()

        init: (elem, attrs) -> 

            #
            # set renderer type from directive
            # 
            # <three-viewport renderer-type="CanvasRenderer" /> 
            #

            type = attrs.rendererType || 'CanvasRenderer'
            scene.renderer = new THREE[type]()
            scene.renderer.setSize elem[0].clientWidth, elem[0].clientHeight

            elem[0].appendChild scene.renderer.domElement


        add: (object) ->

             scene.scene.add object


ActorService = ($log, sceneService) -> 

    actors = {}

    service =

        init: (elem, attrs) -> 

        add: (actor) -> 

            sceneService.add actor.object
            actors[actor._id] = actor

        get: (id) -> 

            return actors[id]


FirstPersonService = ($log, sceneService) -> 

    firstPerson = 

        init: (elem, attrs) -> 

            #
            # TODO: different cams have different construction args
            #

            type   = attrs.cameraType  || 'PerspectiveCamera'
            fov    = parseInt attrs.fieldOfView || 75
            aspect = elem[0].clientWidth / elem[0].clientHeight
            near   = parseInt attrs.nearClip    || 1
            far    = parseInt attrs.farClip     || 100000

            firstPerson.camera = new THREE[type] fov, aspect, near, far

            #
            # camera orientation defaults to looking into +x 
            #

            #firstPerson.controls = new THREE.FirstPersonControls( firstPerson.camera, elem[0] );
            firstPerson.controls = new THREE.FirstPersonControls( firstPerson.camera );

            #
            # TODO: followinf configurables as attrs in the <three-viewport> directive
            #

            firstPerson.controls.movementSpeed = 100;
            firstPerson.controls.lookSpeed = 0.125;
            firstPerson.controls.lookVertical = true;
            firstPerson.controls.constrainVertical = false;
            firstPerson.controls.verticalMin = 1.1;
            firstPerson.controls.verticalMax = 2.2;

            firstPerson.clock = new THREE.Clock()



AnimateService = ($log, sceneService, firstPersonService) -> 

    events =

        'before:animate': []
        'after:animate': []
    

    animate = 

        init: (elem, attrs) -> 

        on: (event, callback) -> 

            try
                events[event].push callback

            catch error
                $log.error 'AnimateService.on("%s"): NO SUCH EVENT', event

        loop: -> 

            for callback in events['before:animate']

                callback()

            firstPersonService.controls.update firstPersonService.clock.getDelta()
            requestAnimationFrame animate.loop
            sceneService.renderer.render sceneService.scene, firstPersonService.camera

            for callback in events['after:animate']

                callback()
            

ng.factory 'sceneService',       SceneService
ng.factory 'actorService',       ActorService
ng.factory 'firstPersonService', FirstPersonService
ng.factory 'animateService',     AnimateService


ng.directive 'threeFirstPerson', ($log, firstPersonService, topologyService) -> 
    
    restrict: 'E'

    compile: (elem, attrs) -> 

        firstPersonService.longitude = parseFloat attrs.longitude
        firstPersonService.latitude  = parseFloat attrs.latitude
        firstPersonService.altitude  = parseFloat attrs.altitude

        vertex = topologyService.transform firstPersonService.longitude, 
            firstPersonService.latitude, firstPersonService.altitude

        firstPersonService.camera.position.x = vertex.x
        firstPersonService.camera.position.y = vertex.y
        firstPersonService.camera.position.z = vertex.z



ng.directive 'threeViewport', ($log, sceneService, actorService, firstPersonService, animateService) -> 

    restrict: 'E'

    compile: (elem, attrs) -> 

        sceneService.init elem, attrs
        actorService.init elem, attrs
        firstPersonService.init elem, attrs
        animateService.init elem, attrs

        animateService.loop()
