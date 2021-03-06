// Generated by CoffeeScript 1.4.0
var TopologyServer;

TopologyServer = (function() {

  function TopologyServer(properties) {
    var prop,
      _this = this;
    for (prop in properties) {
      this[prop] = properties[prop];
    }
    if (!this.app) {
      throw 'missing app';
    }
    if (!this.sockets) {
      throw 'missing sockets';
    }
    if (!this.cache) {
      throw 'missing cache';
    }
    this.sockets.on('connection', function(socket) {
      socket.on('person:register', function(person) {
        person.key = 'KEY';
        return socket.emit('person:register:ok', person);
      });
      return socket.on('topology:register', function(payload) {
        return _this.startAt({
          socket: socket,
          payload: payload
        }, function(err, config) {
          return socket.emit('topology:register:ack', config);
        });
      });
    });
  }

  TopologyServer.prototype.startAt = function(params, callback) {
    var lat, latDir, latVal, long, longDir, longVal, tileID;
    if (!params.socket) {
      throw 'missing socket';
    }
    if (!params.payload) {
      throw 'missing payload';
    }
    lat = params.payload.lat;
    long = params.payload.long;
    if (lat < 0) {
      latVal = Math.floor(-lat);
      latDir = 'S';
    } else {
      latVal = Math.ceil(lat);
      latDir = 'N';
    }
    if (long < 0) {
      longVal = Math.ceil(-long);
      longDir = 'W';
    } else {
      longVal = Math.floor(long);
      longDir = 'E';
    }
    if (latVal < 10) {
      latVal = '0' + latVal;
    }
    if (longVal < 10) {
      longVal = '00' + longVal;
    } else if (longVal < 100) {
      longVal = '0' + longVal;
    }
    tileID = latDir + latVal + longDir + longVal;
    return this.loadTile(tileID, function(err, tile) {
      if (err) {
        callback(err);
        return;
      }
      return callback(null, {
        pixelScale: tile.pixelScale
      });
    });
  };

  TopologyServer.prototype.loadTile = function(id, callback) {
    console.log('TODO: multiple concurrent clients on requesting the same uncached tile cause a simultanoues load from disk');
    return this.cache.loadTile(id, callback);
  };

  return TopologyServer;

})();

module.exports = TopologyServer;
