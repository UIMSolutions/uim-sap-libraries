module uim.sap.service.classes.service;

import core.sync.mutex : Mutex;
import uim.sap.service;

mixin(ShowModule!());

@safe:

class SAPService : ISAPService {
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

  this(ISAPConfig config) {
    config.validate();
    _config = config;
    this.initialize();
  }

  bool initialize(Json[] initData) {
    // Initialization logic for the object
    return true;
  }
  
  bool initialize(Json[string] initData = null) {
    // Initialization logic for the store

    return true;
  }

  protected ISAPConfig _config;
  ISAPConfig config() {
    return _config;
  }

  void config(ISAPConfig cfg) {
    _config = cfg;
  }

  Json health() {
    Json healthInfo = Json.emptyObject;
    healthInfo["ok"] = true;
    healthInfo["status"] = "UP";
    healthInfo["service"] = _config.serviceName;
    healthInfo["version"] = _config.serviceVersion;
    return healthInfo;
  }

  Json ready() {
    Json readyInfo = Json.emptyObject;
    readyInfo["ready"] = true;
    readyInfo["status"] = "READY";
    readyInfo["timestamp"] = Clock.currTime().toISOExtString();

    return readyInfo;
  }

}
