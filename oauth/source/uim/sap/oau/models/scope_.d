module uim.sap.oau.models.scope_;

import std.datetime : Clock, SysTime;

import vibe.data.json : Json;

@safe:

/// OAuth 2.0 scope definition
struct OAUScope {
    string scopeId;
    string name;             // e.g. "read", "write", "admin"
    string description;
    bool isDefault;          // auto-granted when no scope is requested
    SysTime createdAt;
    SysTime updatedAt;

    Json toJson() const {
        Json j = Json.emptyObject;
        j["scope_id"] = scopeId;
        j["name"] = name;
        j["description"] = description;
        j["is_default"] = isDefault;
        j["created_at"] = createdAt.toISOExtString();
        j["updated_at"] = updatedAt.toISOExtString();
        return j;
    }
}

OAUScope scopeFromJson(string scopeId, Json req) {
    OAUScope s;
    s.scopeId = scopeId;
    s.createdAt = Clock.currTime();
    s.updatedAt = s.createdAt;

    if ("name" in req && req["name"].isString)
        s.name = req["name"].get!string;
    else
        s.name = scopeId;
    if ("description" in req && req["description"].isString)
        s.description = req["description"].get!string;
    if ("is_default" in req && req["is_default"].type == Json.Type.bool_)
        s.isDefault = req["is_default"].get!bool;
    return s;
}
