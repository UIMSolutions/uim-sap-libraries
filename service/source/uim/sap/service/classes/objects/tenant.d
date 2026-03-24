module uim.sap.service.classes.objects.tenant;

import uim.sap.service;

mixin(ShowModule!());

@safe:

class SAPTenantObject : SAPObject {
  mixin(SAPObjectTemplate!SAPTenantObject);

  override bool initialize(Json[string] initData = null) {
    if (!super.initialize(initData)) {
      return false;
    }

    if (initData.hasKey("tenant_id")) {
      _tenantId = UUID(initData["tenant_id"].getString);
    }

    return true;
  }

  override Json toJson() {
    Json info = super.toJson();
    // Add tenant-specific fields to the JSON object
    info["tenantId"] = _tenantId.toString();
    return info;  
  }
  ///
  unittest {
    SAPTenantObject obj = new SAPTenantObject();
    obj.tenantId = randomUUID();
    Json json = obj.toJson();
    assert(json["tenantId"].get!string == obj.tenantId.toString());
  }

  // #region tenantId
  protected UUID _tenantId;
  UUID tenantId() const {
    return _tenantId;
  }
  void tenantId(UUID id) {
    _tenantId = id;
  }
  ///
  unittest {
    SAPTenantObject obj = new SAPTenantObject();
    UUID id = randomUUID();
    obj.tenantId = id;
    assert(obj.tenantId == id);
  }
  // #endregion tenantId
}