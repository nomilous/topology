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
            firstPerson.clock = new THREE.Clock()


ControlService = ($log, firstPersonService, animateService) -> 


    #
    # TODO: fix mouse rotation (jitter when move/keypresses are active) 
    #       probably caused by the lookat position being actual place... #1

    service = 

        #
        # default multiplier: pointer move of pixel rotates camera 1 degree
        # 

        rotationMultiplier: 1 / Math.PI / 180

        upVector: new THREE.Vector3 0, 1, 0
        lookVector: new THREE.Vector3 0, 0, -1
        yawMatrix: new THREE.Matrix4
        pitchMatrix: new THREE.Matrix4
        pitchAxis: new THREE.Vector3
        motion: 
            speed: 10
            straightward: 0
            sideward: 0

        init: (elem, attrs) -> 

            document.addEventListener('mousemove', service.onMouseMove, false);
            document.addEventListener('keydown', service.onKeyDown, false);
            document.addEventListener('keyup', service.onKeyUp, false);

            #
            # scale the multiplier with sensitivity
            #

            mouseSensitivity = attrs.mouseSensitivity || 1
            service.rotationMultiplier *= mouseSensitivity;
            if attrs.mouseUpLock
                service.mouseUpLock == 'true'
            else
                service.mouseUpLock = true
            service.orient 0, 0


            animateService.on 'before:animate', -> 
                
                service.move()


            #
            # TODO: 
            #
            # - allow locking the up vector 
            # 
            #   -- to the +y (for normal mouselook behaviour)
            # 
            #   -- to the '''current''' zenith to enable a self 
            #      correcting spherical traversal of the surface
            # 


        orient: (yawRadians, pitchRadians) ->

            if service.mouseUpLock
                
                #
                # prevent lookAt vector from approaching zenith/nadir
                #
                #     the length of the cross product of two 
                #     vectors approaches zero the nearer they
                #     are to parallel 
                #      
                #     used here to lessen the inbound pitch delta
                #     
                #     it does tend to cause a 'stickyness' at the 
                #     extreems
                # 

                length = service.lookVector.clone().cross(service.upVector).length()
                pitchRadians *= length if length < 0.2
 

            #
            # yaw: rotate the lookVector about the upVector
            #

            service.yawMatrix.makeRotationAxis service.upVector.normalize(), -yawRadians
            service.lookVector.applyMatrix4 service.yawMatrix

            #
            # pitch: rotate lookVector and upVector about their 
            # cross product (ie. the vector perpendicular to them both)
            #

            service.pitchMatrix.makeRotationAxis(
                service.pitchAxis.crossVectors(
                    service.upVector, 
                    service.lookVector
                ).normalize(),
                pitchRadians
            )
            service.lookVector.applyMatrix4 service.pitchMatrix

            unless service.mouseUpLock

                #
                # apply updated look and upVectors
                #

                service.upVector.applyMatrix4 service.pitchMatrix

                firstPersonService.camera.up.x = service.upVector.x
                firstPersonService.camera.up.y = service.upVector.y
                firstPersonService.camera.up.z = service.upVector.z

            #1
            # 
            # (had me flummoxed) seems that 3's lookAt is literally 
            # a place and not a normalized direction vector, so this 
            # adds lookAt direction vector to position and uses that 
            # to update camera.lookat
            # 

            lookAt = service.lookVector.clone()
            lookAt.add firstPersonService.camera.position
            firstPersonService.camera.lookAt lookAt


        isStationary: -> 

            return service.motion.straightward == 0 and service.motion.sideward == 0

        move: ->

            return if service.isStationary()

            forward = service.lookVector.clone()
            forward.multiplyScalar service.motion.straightward

            sideward = service.pitchAxis.clone()
            sideward.multiplyScalar service.motion.sideward

            firstPersonService.camera.position.x += forward.x + sideward.x
            firstPersonService.camera.position.y += forward.y + sideward.y
            firstPersonService.camera.position.z += forward.z + sideward.z


        onMouseMove: (event) -> 

            return unless pointerLocked
            dx = event.movementX || event.mozMovementX || event.webkitMovementX || 0
            dy = event.movementY || event.mozMovementY || event.webkitMovementY || 0
            pitchRadians = dy * service.rotationMultiplier
            yawRadians   = dx * service.rotationMultiplier
            service.orient yawRadians, pitchRadians
            
        onKeyDown: (event) ->

            return unless pointerLocked
            # console.log 'press', event.keyCode
            switch event.keyCode
                when 87, 38 # w, uparrow
                    service.motion.straightward = service.motion.speed
                when 83, 40 # s, downarrow
                    service.motion.straightward = -service.motion.speed
                when 65, 37 # a, leftarrow
                    service.motion.sideward = service.motion.speed
                when 68, 39 # d, rightarrow
                    service.motion.sideward = -service.motion.speed

        onKeyUp: (event) ->

            return unless pointerLocked
            #console.log 'release', event.keyCode
            switch event.keyCode
                when 87, 38
                    service.motion.straightward = 0
                when 83, 40 
                    service.motion.straightward = 0
                when 65, 37 # a, leftarrow
                    service.motion.sideward = 0
                when 68, 39 # d, rightarrow
                    service.motion.sideward = 0


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

        # firstPersonService.camera.position.x = vertex.x
        # firstPersonService.camera.position.y = vertex.y
        # firstPersonService.camera.position.z = vertex.z



ng.directive 'threeViewport', ($log, sceneService, actorService, firstPersonService, controlService, animateService) -> 

    restrict: 'E'

    compile: (elem, attrs) -> 

        sceneService.init elem, attrs
        actorService.init elem, attrs
        firstPersonService.init elem, attrs
        controlService.init elem, attrs
        animateService.init elem, attrs

        animateService.loop()
