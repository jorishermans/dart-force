part of force.server;

class ServerSendable implements Sendable, DataChangeable {

    final Logger log = new Logger('Sendable');
  
    Map<String, ForceSocket> forceSockets = new Map<String, ForceSocket>();
    Map<String, dynamic> profiles = new Map<String, dynamic>();
    
    MessagesConstructHelper _messagesConstructHelper = new MessagesConstructHelper();
      
    void send(request, data) {
      printAmountOfConnections();
      
      var sendingPackage = _messagesConstructHelper.send(request, data);
      sendPackage(sendingPackage);
    }
  
    void broadcast(request, data) {
        printAmountOfConnections();
        
        var sendingPackage = _messagesConstructHelper.broadcast(request, data);
        sendPackage(sendingPackage);
    }
    
    void sendTo(id, request, data) {
      log.info("*** send to $id");
      
      var sendingPackage = _messagesConstructHelper.send(request, data);
      _sendPackageToId(id, sendingPackage);
    }
  
    void sendToProfile(key, value, request, data) {
      List<String> ids = new List<String>();
      profiles.forEach((String id, profile_data) {
        if (profile_data[key] == value) {
          ids.add(id);
        }
      });
      if (ids.isNotEmpty) {
        for (String id in ids) {
          sendTo(id, request, data);
        }
      }
    }
  
    // DATA PROTOCOL
    void add(collection, key, data, {id}) {
        var sendingPackage = _messagesConstructHelper.add(collection, key, data);
        _sendPackageToId(id, sendingPackage);
    }
    
    void set(collection, data, {id}) {
        var sendingPackage = _messagesConstructHelper.set(collection, data);
        _sendPackageToId(id, sendingPackage);
    }
    
    void update(collection, key, data, {id}) {
        var sendingPackage = _messagesConstructHelper.update(collection, key, data);
        _sendPackageToId(id, sendingPackage);
    }
    
    void remove(collection, key, {id}) {
        var sendingPackage = _messagesConstructHelper.remove(collection, key);
        _sendPackageToId(id, sendingPackage);
    }
    
    // OVERALL METHODS
    void sendPackage(sendingPackage) {
      forceSockets.forEach((String key, ForceSocket ws) {
              log.info("sending package ... to $key");
              ws.add(JSON.encode(sendingPackage));
            });
    }
    
    void _sendPackageToId(id, sendingPackage) {
      ForceSocket ws = forceSockets[id];
            if (ws != null) {
              ws.add(JSON.encode(sendingPackage));
            }
    }
  
  void printAmountOfConnections() {
    int size = this.forceSockets.length;
    log.info("*** total amount of sockets: $size");
  }

}