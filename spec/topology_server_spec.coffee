require('nez').realize 'TopologyServer', (TopologyServer, test, context) -> 

    context 'startAt()', (it) ->

        startMock = (socket) -> 

            topo = new TopologyServer

                app: {}
                sockets: on: (event, callback) -> 

                    if event == 'connection'

                        #
                        # receive subscribe to 'connection'
                        # call the subscriber with mockSocket
                        # to simulate immediate connection
                        #

                        callback socket

        mockProtocolStartAt =

            emit: ->
            on: (event, callback) -> 

                if event == 'topology:start_at'

                    #
                    # receive subscribe to 'topology:start_at'
                    # send immediate mock payload to subscriber
                    #

                    callback 

                        long: '18.49963'
                        lat: '-34.36157'
                        alt: '100'
                


        it 'is called from protocol with payload and socket', (done) ->

            swap = TopologyServer.prototype.startAt

            TopologyServer.prototype.startAt = (args) -> 

                TopologyServer.prototype.startAt = swap

                args.payload.should.eql

                    long: '18.49963'
                    lat: '-34.36157'
                    alt: '100'

                args.socket.should.eql mockProtocolStartAt

                test done


            startMock mockProtocolStartAt


        it 'calculates which tile the client is on', (done) -> 

            swap = TopologyServer.prototype.loadTile

            TopologyServer.prototype.loadTile = (tileID) -> 

                TopologyServer.prototype.loadTile = swap

                tileID.should.equal 'S34E018'
                test done

            startMock mockProtocolStartAt

