module uim.sap.service.helpers.required;

import uim.sap.service;

mixin(ShowModule!());

@safe:

UUID requiredUUID(Json request, string key) {
  requiredKey(request, key);
  requiredStringType(request, key);

  auto value = request[key].get!string;
  if (value.length == 0 || !value.isUUID) {
    throw new SAPValidationException(key ~ " must be a valid UUID");
  }

  return UUID(value);
}

/**
  * Validates that the specified key exists in the JSON object and is a non-empty string.
  * Returns the string value if valid, otherwise throws SAPValidationException.
  */
string requiredString(Json data, string key) {
  requiredKey(data, key);
  requiredStringType(data, key);

  auto value = data[key].get!string;
  if (value.length == 0) {
    throw new SAPValidationException(key ~ " cannot be empty");
  }

  return value;
}

void requiredBooleanType(Json data, string key) {
  if (!data[key].isBoolean) {
    throw new SAPValidationException(key ~ " must be a boolean");
  }
}

void requiredStringType(Json data, string key) {
  if (!data[key].isString) {
    throw new SAPValidationException(key ~ " must be string");
  }
}

void requiredArrayType(Json data, string key) {
  if (!data[key].isArray) {
    throw new SAPValidationException(key ~ " must be array");
  }
}

void requiredObjectType(Json data, string key) {
  if (!data[key].isObject) {
    throw new SAPValidationException(key ~ " must be object");
  }
}

void requiredKey(Json data, string key) {
  if (!(key in data)) {
    throw new SAPValidationException(key ~ " is required");
  }
}
