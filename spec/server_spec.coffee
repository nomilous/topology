require('nez').realize 'Server', (Server, test, context) -> 

    context 'in CONTEXT', (does) ->

        does 'an EXPECTATION', (done) ->

            test done
