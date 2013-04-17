ng = angular.module 'viewport', [], ($provide) -> 


SceneService = ($log) -> 

    scene = _scene =

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

    service = _service = 

        init: (elem, attrs) -> 

        add: (actor) -> 

            sceneService.add actor.object
            actors[actor._id] = actor

        get: (id) -> 

            return actors[id]


FirstPersonService = ($log, sceneService) -> 

    firstPerson = _firstPerson =

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

            firstPerson.camera.position.y = 20

            firstPerson.controls = new THREE.FirstPersonControls( firstPerson.camera, elem[0] );

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

    animate = _animate = 

        init: (elem, attrs) -> 

        update: -> 

        animate: (updateFn) -> 

            animate.update = updateFn if updateFn

        loop: -> 

            animate.update()
            firstPersonService.controls.update firstPersonService.clock.getDelta()
            requestAnimationFrame animate.loop
            sceneService.renderer.render sceneService.scene, firstPersonService.camera
            


ng.factory 'sceneService',       SceneService
ng.factory 'actorService',       ActorService
ng.factory 'firstPersonService', FirstPersonService
ng.factory 'animateService',     AnimateService


ng.directive 'threeViewport', ($log, sceneService, actorService, firstPersonService, animateService) -> 

    restrict: 'E'

    compile: (elem, attrs) -> 

        $log.info 'compile threeViewport'

        sceneService.init elem, attrs
        actorService.init elem, attrs
        firstPersonService.init elem, attrs
        animateService.init elem, attrs

        animateService.loop()
