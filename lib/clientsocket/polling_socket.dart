part of force.client;

class PollingSocket extends Socket {
  Duration _heartbeat = new Duration(milliseconds: 2000);
  
  String _url;
  bool _alreadyConnected = false;
  
  String _uuid;
  
  int count = 0;
  
  PollingSocket(this._url, heartbeat_ms) : super._() {
    _connectController = new StreamController<ConnectEvent>();
    _disconnectController = new StreamController<ConnectEvent>();
    _messageController = new StreamController<SocketEvent>();
    
    _heartbeat = new Duration(milliseconds : heartbeat_ms);
    
    print('polling socket is created');
  }
  
  void connect() {
    HttpRequest.getString('http://$_url/uuid/').then(procces_id).catchError((error) {
      print('no support for long polling ... available on the server');
    });
  }
  
  void procces_id(String value) {
    var json = JSON.decode(value);
    
    print(json);
    
    _uuid = json["id"];
    
    new Timer(_heartbeat, polling);
  }
  
  void polling() {
    count++;
    print('polling to ... http://$_url/polling/?pid=$_uuid&count=$count');
    HttpRequest.getString('http://$_url/polling/?pid=$_uuid&count=$count').then(processString).catchError((error) {
      print('no support for long polling at this moment ... problems with the server???');
    });
  }
  
  void processString(String values) {
    print('process return from polling ...$values');
    var messages = JSON.decode(values);
    if (!_alreadyConnected) {
      _connectController.add(new ConnectEvent());
      _alreadyConnected = true;
    }
    if (messages!=null) {
      for (var value in messages) {
        print('individual value -> $value');
        _messageController.add(new SocketEvent(value));
      }
    }
    new Timer(_heartbeat, polling);
  }
  
  void send(data) {
    if (_uuid!=null) {
      var package = JSON.encode({
                     "pid" : _uuid,
                     "data" : data
      });
      print('sending data to the post http://$_url/polling/');
      var httpRequest = new HttpRequest();
      httpRequest.open('POST', 'http://$_url/polling/');
      httpRequest.setRequestHeader('Content-type', 
      'application/x-www-form-urlencoded');
      httpRequest.onLoadEnd.listen((e) => loadEnd(httpRequest));
      httpRequest.send(package);
    }
  }
  
  void loadEnd(HttpRequest request) {
    if (request.status != 200) {
      print('Uh oh, there was an error of ${request.status}');
    } else {
      print('Data has been posted');
    }
  }
  
  bool isOpen() => true;
}