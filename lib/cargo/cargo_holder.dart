part of force.common;

/**
* Holds all interactions with the cargo instances, abstraction for the implementations on the server and on the client
*/
abstract class CargoHolder {
  
  Map<String, CargoBase> _cargos = new Map<String, CargoBase>();

  DataChangeable dataChangeable;
  
  CargoHolder(this.dataChangeable);
  
  void publish(String collection, CargoBase cargoBase);
  
  bool subscribe(String collection, params, Options options, String id);
  
  bool exist(String collection);
  
  bool add(String collection, key, data);
  
  bool update(String collection, key, data);
  
  bool set(String collection, data);
  
  bool remove(String collection, key);
  
}