ng = angular.module 'viewport', [], ($provide) -> 


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


ng.directive 'threeFirstPerson', ($log, firstPersonService) -> 
    
    restrict: 'E'

    compile: (elem, attrs) -> 

        firstPersonService.camera.position.x = parseInt attrs.modelPositionX || 0
        firstPersonService.camera.position.y = parseInt attrs.modelPositionY || 0
        firstPersonService.camera.position.z = parseInt attrs.modelPositionZ || 0



ng.directive 'threeViewport', ($log, sceneService, actorService, firstPersonService, animateService) -> 

    restrict: 'E'

    compile: (elem, attrs) -> 

        sceneService.init elem, attrs
        actorService.init elem, attrs
        firstPersonService.init elem, attrs
        animateService.init elem, attrs

        animateService.loop()
