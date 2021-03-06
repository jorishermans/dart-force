part of force.server;

/**
* Holds all interactions with the cargo instances on the server!
*/
class CargoHolderServer implements CargoHolder {
  
  Map<String, CargoBase> _cargos = new Map<String, CargoBase>();
  Map<String, List<String>> _subscribers = new Map<String, List<String>>();
  
  Map<String, Map> _parameters = new Map<String, Map>();

  DataChangeable dataChangeable;
  
  var _uuid = new Uuid();
  
  CargoHolderServer(this.dataChangeable);
  
  void publish(String collection, CargoBase cargoBase) {
    _cargos[collection] = cargoBase;
    
    cargoBase.onAll((de) {
      // inform all subscribers for this change!
      if (de.type==DataType.CHANGED) {
        //before that 
        _sendTo(collection, de.key, de.data);
      } else {
        _removePush(collection, de.key, de.data);
      }
    });
  }
  
  void _sendTo(collection, key, data) {
    // inform all subscribers for this change!
    List ids = _subscribers[collection];
    
    if (ids != null) {
      for (var id in ids) {
        Map params = _parameters["${collection}_${id}"];
        
        bool sendIt = (data is Map ? containsByOverlay(data, params) : true);
        if (sendIt) {
          this._sendToId(collection, key, data, id);
        }
      }
    }
  }
  
  void _sendToId(collection, key, data, id) {
       dataChangeable.update(collection, key, data, id: id);
  }
  
  void _removePush(collection, key, data) {
      // inform all subscribers for this change!
      List ids = _subscribers[collection];
     
      for (var id in ids) {
        Map params = _parameters["${collection}_${id}"];
        if (containsByOverlay(data, params)) {
            dataChangeable.remove(collection, key, id: id);
        }
      } 
    }
  
  bool subscribe(String collection, params, Options options, String id) {
    bool colExist = exist(collection);
    if (colExist) { 
      List ids = new List();
      if (_subscribers[collection] != null) {
        ids = _subscribers[collection];
      }
      ids.add(id);
      // send data if necessary
      _subscribers[collection] = ids;
      _parameters["${collection}_${id}"] = params;
      
      // send the collection to the clients
      _cargos[collection].export(params: params, options: options).then((Map values) {
        // if revert send it revert to the client
        if (options.revert) values = revertMap(values);
        
        values.forEach((key, value) => _sendToId(collection, key, value, id));
      });
    }
    return colExist;
  }
  
  bool exist(String collection) {
    return _cargos[collection]!=null;
  }
  
  bool add(String collection, key, data) {
    bool colExist = exist(collection);
    if (colExist) { 
      _cargos[collection].add(key, data);
    }
    return colExist;
  }
  
  bool update(String collection, key, data) {
      bool colExist = exist(collection);
      if (colExist) { 
        _cargos[collection].setItem(key, data);
      }
      return colExist;
  }
  
  bool remove(String collection, key) {
      bool colExist = exist(collection);
      if (colExist) { 
         _cargos[collection].removeItem(key);
      }
      return colExist;
    }
  
  bool set(String collection, data) {
    bool colExist = exist(collection);
    if (colExist) { 
       _cargos[collection].setItem(_uuid.v4(), data);
    }
    return colExist;
  }
  
  generateKey(key) {
    return key;
  }
  
}