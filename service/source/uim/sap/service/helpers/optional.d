module uim.sap.service.helpers.optional;

import uim.sap.service;

mixin(ShowModule!());

@safe:

bool optionalBoolean(Json data, string key, bool fallback) {
  if (!(key in data) || data[key].isNull)
    return fallback;

  requiredBooleanType(data, key);
  return data[key].get!bool;
}

string optionalString(Json data, string key, string fallback) {
  if (!(key in data) || data[key].isNull)
    return fallback;

  requiredStringType(data, key);
  return data[key].get!string;
}

Json optionalObject(Json data, string key, Json fallback = Json.emptyObject) {
  if (!(key in data) || data[key].isNull) {
    return fallback;
  }

  requiredObjectType(data, key);
  return data[key];
}
