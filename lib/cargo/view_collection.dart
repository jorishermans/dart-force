part of dart_force_common_lib;

/** transform json objects into real objects by the user 
 * until better ways in dart this will be the way to transform our data
 **/
typedef Object deserializeData(Map json);

/**
* Is a memory wrapper arround cargo, so we can add this to our view!
* Ideal class to use it in Angular or Polymer.
*/
class ViewCollection extends Object with IterableMixin<EncapsulatedValue> {
  
  CargoBase cargo;
  DataChangeable _changeable;
  String _collection;
  
  Options options;
  
  deserializeData deserialize;
  
  Map<String, EncapsulatedValue> _all = new Map<String, EncapsulatedValue>();
  
  ViewCollection(this._collection, this.cargo, this.options, this._changeable, {this.deserialize}) {
   this.cargo.onAll((DataEvent de) {
     if (de.type==DataType.CHANGED) {
       var data = de.data;
       if (data is Map && deserialize != null) {
         data = deserialize(data);
       }
       
       _addNewValue(de.key, data);
     }
     if (de.type==DataType.REMOVED) {
       _all.remove(de.key);
     }
   }); 
  }
  
  void _addNewValue(key, data) {
    if (options != null && options.hasLimit() && !_all.containsKey(key)) {
       if (options.limit == _all.length) {
          var removableKey;
          if(options.revert) {
            removableKey = _all.keys.elementAt(_all.keys.length-1);
          } else {
            removableKey = _all.keys.elementAt(0);
          }
          _all.remove(removableKey);
       }
    }
    if (options != null && options.revert && !_all.containsKey(key)) {
        Map<String, EncapsulatedValue> tempMap = new Map<String, EncapsulatedValue>();
        
        tempMap[key] = new EncapsulatedValue(key, data);
        tempMap.addAll(_all);
        
        _all = tempMap;
    } else {
      _all[key] = new EncapsulatedValue(key, data);
    }
  }
  
  void update(key, value) {
   this.cargo.setItem(key, value);
   this._changeable.update(_collection, key, value);
  }
  
  void remove(id) {
    this.cargo.removeItem(id);
    this._changeable.remove(_collection, id);
  }
  
  void set(value) {
    this._changeable.set(_collection, value);
  }
  
  Iterator get iterator => _all.values.iterator;
  
}

class EncapsulatedValue {
  String key;
  var value;
  
  EncapsulatedValue(this.key, this.value);
}