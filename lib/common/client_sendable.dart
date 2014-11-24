part of dart_force_common_lib;

class ClientSendable implements Sendable, DataChangeable {
  
  Messenger messenger;
 
  var _profileInfo; 
  
  MessagesConstructHelper _messagesConstructHelper = new MessagesConstructHelper();
  
  void initProfileInfo(profileInfo) {
    _messagesConstructHelper.initProfileInfo(profileInfo);
    send('profileInfo', {});
  }
  
  // send it to the server
  void send(request, data) {
    this._send(_messagesConstructHelper.send(request, data));
  }
  
  // broadcast it directly to all the clients
  void broadcast(request, data) {
    this._send(_messagesConstructHelper.broadcast(request, data));
  }
  
  // send to a specific socket with an id
  void sendTo(id, request, data) {
     this._send(_messagesConstructHelper.sendTo(id, request, data));
  }
  
  // send to a profile with specific values
  void sendToProfile(key, value, request, data) {
    this._send(_messagesConstructHelper.sendToProfile(key, value, request, data));
  }
  
  // DB SENDABLE METHODS
  void subscribe(collection) {
    this._send(_messagesConstructHelper.subscribe(collection));
  }
  
  void add(collection, key, value, {id}) {
    this._send(_messagesConstructHelper.add(collection, key, value));
  }
  
  void update(collection, key, value, {id}) {
      this._send(_messagesConstructHelper.update(collection, key, value));
  }
  
  void remove(collection, key, {id}) {
      this._send(_messagesConstructHelper.remove(collection, key));
  }
  
  void set(collection, key, value, {id}) {
      this._send(_messagesConstructHelper.set(collection, key, value));
  }
  
  void _send(sendingPackage) {
    messenger.send(sendingPackage);
  }

}