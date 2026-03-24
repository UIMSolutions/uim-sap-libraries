module uim.sap.service.helpers.set;

import uim.sap.service;

mixin(ShowModule!());

@safe:

Json set(Json json, string key, Json value) {
  json[key] = value;
  return json;
}

Json set(Json json, string key, string value) {
  json[key] = value;
  return json;
}

Json set(Json json, string key, int value) {
  json[key] = value;
  return json;
}

Json set(Json json, string key, long value) {
  json[key] = value;
  return json;
}

Json set(Json json, string key, double value) {
  json[key] = value;
  return json;
}

Json set(Json json, string key, float value) {
  json[key] = value;
  return json;
}

Json set(Json json, string key, bool value) {
  json[key] = value;
  return json;
}

Json set(Json json, string key, UUID value) {
  json[key] = value.toString();
  return json;
}

Json set(T)(Json json, string key, T[] values) {
  Json jArray = Json.emptyArray;
  foreach (v; values) {
    jArray ~= v.toJson;
  }
  json[key] = jArray;
  return json;
}

unittest {
  Json j1 = Json.emptyObject
    .set("key1", "value1");

  assert(j1["key1"] == "value1");

  Json j2 = Json.emptyObject
    .set("key1", "value1")
    .set("key2", "value2");

  assert(j2["key1"] == "value1");
  assert(j2["key2"] == "value2");
}
