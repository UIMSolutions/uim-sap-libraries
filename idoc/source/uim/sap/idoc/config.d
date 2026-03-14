/**
 * Configuration for IDOC client
 *
 * Copyright: Copyright © 2018-2026, Ozan Nurettin Süel
 * License: Apache-2.0
 * Authors: Ozan Nurettin Süel
 */
module uim.sap.idoc.config;

import core.time : Duration, seconds;
import uim.sap.idoc;

@safe:

enum IDocAuthType {
  None,
  Basic,
  Bearer
}

struct IDocConfig : SAPConfig {
  string baseUrl;
  string endpointPath = "/sap/idoc";

  ushort port = 443;
  bool useSSL = true;
  bool verifySSL = true;

  IDocAuthType authType = IDocAuthType.None;
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
      throw new IDocConfigurationException("Base URL cannot be empty");
    }

    if (authType == IDocAuthType.Basic) {
      if (username.length == 0 || password.length == 0) {
        throw new IDocConfigurationException(
          "Username and password are required for Basic authentication"
        );
      }
    }

    if (authType == IDocAuthType.Bearer && bearerToken.length == 0) {
      throw new IDocConfigurationException(
        "Bearer token is required for Bearer authentication"
      );
    }
  }

  string fullBaseUrl() const {
    if (baseUrl.startsWith("http://") || baseUrl.startsWith("https://")) {
      return stripTrailingSlash(baseUrl).idup;
    }

    auto protocol = useSSL ? "https" : "http";
    if ((useSSL && port == 443) || (!useSSL && port == 80)) {
      return format("%s://%s", protocol, stripTrailingSlash(baseUrl));
    }

    return format("%s://%s:%d", protocol, stripTrailingSlash(baseUrl), port);
  }

  string serviceUrl() const {
    auto path = (endpointPath.length == 0 ? "/sap/idoc" : endpointPath).idup;
    if (!path.startsWith("/")) {
      path = "/" ~ path;
    }
    return (stripTrailingSlash(fullBaseUrl()) ~ path).idup;
  }

  static IDocConfig createBasic(
    string baseUrl,
    string username,
    string password,
    string sapClient = ""
  ) {
    IDocConfig cfg;
    cfg.baseUrl = baseUrl;
    cfg.username = username;
    cfg.password = password;
    cfg.sapClient = sapClient;
    cfg.authType = IDocAuthType.Basic;
    return cfg;
  }

  static IDocConfig createBearer(
    string baseUrl,
    string bearerToken,
    string sapClient = ""
  ) {
    IDocConfig cfg;
    cfg.baseUrl = baseUrl;
    cfg.bearerToken = bearerToken;
    cfg.sapClient = sapClient;
    cfg.authType = IDocAuthType.Bearer;
    return cfg;
  }

  private static string stripTrailingSlash(string input) {
    auto result = input;
    while (result.length > 0 && result[$ - 1] == '/') {
      result = result[0 .. $ - 1];
    }
    return result.idup;
  }
}
