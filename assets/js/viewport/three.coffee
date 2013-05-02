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

            scene.scene.fog = new THREE.FogExp2 0x251d15, 0.0015

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

ControlService = ($log) -> 

    service = 

        init: (elem, attrs) -> 

            document.addEventListener('mousemove', service.onMouseMove, false);
            document.addEventListener('keydown', service.onKeyDown, false);
            document.addEventListener('keyup', service.onKeyUp, false);

        onMouseMove: (event) -> 

            return unless pointerLocked
            dx = event.movementX || event.mozMovementX || event.webkitMovementX || 0
            dy = event.movementY || event.mozMovementY || event.webkitMovementY || 0
            console.log dx, dy
            
        onKeyDown: (event) ->

            return unless pointerLocked
            console.log 'press', event.keyCode

        onKeyUp: (event) ->

            return unless pointerLocked
            console.log 'release', event.keyCode


FirstPersonService = ($log, sceneService, controlService) -> 

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

            #firstPersonService.controls.update firstPersonService.clock.getDelta()
            requestAnimationFrame animate.loop
            sceneService.renderer.render sceneService.scene, firstPersonService.camera

            for callback in events['after:animate']

                callback()
            

ng.factory 'sceneService',       SceneService
ng.factory 'actorService',       ActorService
ng.factory 'firstPersonService', FirstPersonService
ng.factory 'controlService',     ControlService
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



ng.directive 'threeViewport', ($log, sceneService, actorService, firstPersonService, controlService, animateService) -> 

    restrict: 'E'

    compile: (elem, attrs) -> 

        sceneService.init elem, attrs
        actorService.init elem, attrs
        firstPersonService.init elem, attrs
        controlService.init elem, attrs
        animateService.init elem, attrs

        animateService.loop()
