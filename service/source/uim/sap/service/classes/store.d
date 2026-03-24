module uim.sap.service.classes.store;

import core.sync.mutex : Mutex;
import uim.sap.service;

mixin(ShowModule!());

@safe:

class SAPStore {
  this() {
    initialize();
  }

  this(Json initData) {
    if (initData.isArray) {
      initialize(initData.toArray);
    }
    if (initData.isObject) {
      initialize(initData.toMap);
    }
  }

  this(Json[] initData) {
    initialize(initData);
  }

  this(Json[string] initData) {
    initialize(initData);
  }

  bool initialize(Json[] initData) {
    // Initialization logic for the object
    return true;
  }
  
  bool initialize(Json[string] initData = null) {
    // Initialization logic for the store
    return true;
  }
}
