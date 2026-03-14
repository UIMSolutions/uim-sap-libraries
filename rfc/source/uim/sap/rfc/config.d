/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*) 
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file. 
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.sap.rfc.config;

import core.time : Duration, seconds;
import std.string : format, startsWith;

import uim.sap.rfc.exceptions;

enum RFCAuthType {
  None,
  Basic,
  Bearer
}

struct RFCConfig : SAPConfig {
  string baseUrl;
  string endpointPath = "/sap/bc/rfc";

  ushort port = 443;
  bool useSSL = true;
  bool verifySSL = true;

  RFCAuthType authType = RFCAuthType.None;
  string username;
  string password;
  string bearerToken;

  string sapClient;
  string sapLanguage = "EN";

  Duration timeout = 30.seconds;
  uint maxRetries = 2;

  string[string] customHeaders;

  override void validate() const {
    super.validate();

    if (baseUrl.length == 0) {
      throw new RFCConfigurationException("Base URL cannot be empty");
    }

    if (authType == RFCAuthType.Basic) {
      if (username.length == 0 || password.length == 0) {
        throw new RFCConfigurationException(
          "Username and password are required for Basic authentication");
      }
    }

    if (authType == RFCAuthType.Bearer && bearerToken.length == 0) {
      throw new RFCConfigurationException(
        "Bearer token is required for Bearer authentication");
    }
  }

  string fullBaseUrl() const {
    if (baseUrl.startsWith("http://") || baseUrl.startsWith("https://")) {
      return stripTrailingSlash(baseUrl);
    }

    auto protocol = useSSL ? "https" : "http";
    if ((useSSL && port == 443) || (!useSSL && port == 80)) {
      return format("%s://%s", protocol, stripTrailingSlash(baseUrl));
    }
    return format("%s://%s:%d", protocol, stripTrailingSlash(baseUrl), port);
  }

  string serviceUrl() const {
    auto path = (endpointPath.length == 0 ? "/sap/bc/rfc" : endpointPath).dup;
    if (!path.startsWith("/")) {
      path = "/" ~ path;
    }
    return stripTrailingSlash(fullBaseUrl()) ~ path;
  }

  static RFCConfig createBasic(
    string baseUrl,
    string username,
    string password,
    string sapClient = ""
  ) {
    RFCConfig cfg;
    cfg.baseUrl = baseUrl;
    cfg.username = username;
    cfg.password = password;
    cfg.sapClient = sapClient;
    cfg.authType = RFCAuthType.Basic;
    return cfg;
  }

  static RFCConfig createBearer(
    string baseUrl,
    string token,
    string sapClient = ""
  ) {
    RFCConfig cfg;
    cfg.baseUrl = baseUrl;
    cfg.bearerToken = token;
    cfg.sapClient = sapClient;
    cfg.authType = RFCAuthType.Bearer;
    return cfg;
  }

  private static string stripTrailingSlash(string url) {
    auto result = url;
    while (result.length > 0 && result[$ - 1] == '/') {
      result = result[0 .. $ - 1];
    }
    return result;
  }
}
