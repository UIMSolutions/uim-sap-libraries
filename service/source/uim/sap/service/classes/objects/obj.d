module uim.sap.service.classes.objects.obj;

import uim.sap.service;
import std.datetime.systime;
mixin(ShowModule!());

@safe:

class SAPObject {
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
    // Initialization logic for the object

    if (initData.hasKey("created_at")) {
      createdAt = SysTime.fromISOExtString(initData["created_at"].getString);
    }   
    if (initData.hasKey("updated_at")) {
      updatedAt = SysTime.fromISOExtString(initData["updated_at"].getString);
    }
    return true;
  }

  // #region createdAt
  protected SysTime _createdAt;
  SysTime createdAt() {
    return _createdAt;
  }
  void createdAt(SysTime time) {
    _createdAt = time;
  }
  /// 
  unittest {
    auto obj = new SAPObject();

    auto now = Clock.currTime;
    obj.createdAt(now);
    assert(obj.createdAt == now);
  }
  // #endregion createdAt

  // #region updatedAt
  protected SysTime _updatedAt;
  SysTime updatedAt() {
    return _updatedAt;
  }
  void updatedAt(SysTime time) {
    _updatedAt = time;
  }
  /// 
  unittest {
    auto obj = new SAPObject();
    auto now = Clock.currTime;
    obj.updatedAt(now);
    assert(obj.updatedAt == now);
  }
  // #endregion updatedAt

  Json toJson() {
    Json info = Json.emptyObject;
    // Add tenant-specific fields to the JSON object
    info["created_at"] = createdAt.toISOExtString();
    info["updated_at"] = updatedAt.toISOExtString();

    return info;
  }
}
