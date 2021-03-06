part of force.common;

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
  
  /// put the data raw in a map, make the map only available as a getter
  Map<String, dynamic> _raw = new Map<String, dynamic>();
  Map<String, dynamic> get data => _raw;
  
  /// Follow changes in view collection
  DataChangeListener _cargoDataChange;
  onChange(DataChangeListener cargoDataChange) => this._cargoDataChange = cargoDataChange;
  
  ViewCollection(this._collection, this.cargo, this.options, this._changeable, {this.deserialize}) {
   this.cargo.onAll((DataEvent de) {
     if (de.type==DataType.CHANGED) {
         var data = de.data;
         if (data is Map && deserialize != null) {
             data = deserialize(data);
         }
            
         _all = _addNewValue(_all, de.key, new EncapsulatedValue(de.key, data));
         _raw = _addNewValue(_raw, de.key, data);
         if (_cargoDataChange!=null) _cargoDataChange(new DataEvent(de.key, data, de.type));
     }
     if (de.type==DataType.REMOVED) {
         _all.remove(de.key);
         _raw.remove(de.key);
         if (_cargoDataChange!=null) _cargoDataChange(de);
     }
   }); 
  }
  
  Map _addNewValue(Map values, key, data) {
    // check on the limit option and limit the map
    if (options != null && options.hasLimit() && !values.containsKey(key)) {
       if (options.limit == values.length) {
          var removableKey;
          if(options.revert) {
            removableKey = values.keys.elementAt(values.keys.length-1);
          } else {
            removableKey = values.keys.elementAt(0);
          }
          values.remove(removableKey);
       }
    }
    // if we need to revert our results 
    if (options != null && options.revert && !values.containsKey(key)) {
        Map tempMap = new Map();
        
        tempMap[key] = data;
        tempMap.addAll(values);
        
        values = tempMap;
    } else {
      values[key] = data;
    }
    return values;
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