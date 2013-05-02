var pointerLocked = false;
var pointerLock = function(instructionId) {
    var instruction = document.getElementById( instructionId );
    var havePointerLock = 
        'pointerLockElement' in document || 
        'mozPointerLockElement' in document || 
        'webkitPointerLockElement' in document;
    if( ! havePointerLock ) {
        instruction.innerHTML = 'this browser does not support pointer lock';
        return;
    }

    //
    // TODO: not always body
    //

    var element = document.body;

    var pointerlockchange = function( event ) {

        //
        // TODO: callbacks on lock toggle, not global variable
        //

        if( document.pointerLockElement === element || 
            document.mozPointerLockElement === element || 
            document.webkitPointerLockElement === element ) {
            instruction.style.display = 'none';
            pointerLocked = true;
        } else {
            instruction.style.display = '-webkit-box';
            instruction.style.display = '-moz-box';
            instruction.style.display = 'box';
            pointerLocked = false;
        }
    };
    var pointerlockerror = function( event ) {};
    document.addEventListener('pointerlockchange', pointerlockchange, false);
    document.addEventListener('mozpointerlockchange', pointerlockchange, false);
    document.addEventListener('webkitpointerlockchange', pointerlockchange, false);
    document.addEventListener('pointerlockerror', pointerlockerror, false);
    document.addEventListener('mozpointerlockerror', pointerlockerror, false);
    document.addEventListener('webkitpointerlockerror', pointerlockerror, false);
    instruction.addEventListener( 'click', function ( event ) { 
        element.requestPointerLock = 
            element.requestPointerLock || 
            element.mozRequestPointerLock || 
            element.webkitRequestPointerLock;
        if( /Firefox/i.test( navigator.userAgent ) ) {
            var fullscreenchange = function( event ) {
                if( document.fullscreenElement === element || 
                    document.mozFullscreenElement === element || 
                    document.mozFullScreenElement === element ) {
                    document.removeEventListener('fullscreenchange', fullscreenchange);
                    document.removeEventListener('mozfullscreenchange', fullscreenchange);
                    element.requestPointerLock();
                }
            }
            document.addEventListener('fullscreenchange', fullscreenchange, false);
            document.addEventListener('mozfullscreenchange', fullscreenchange, false);
            element.requestFullscreen = 
                element.requestFullscreen || 
                element.mozRequestFullscreen || 
                element.webkitRequestFullscreen;
            element.requestFullscreen();
        } else {
            element.requestPointerLock();
        }
    }, false );
};
