/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*) 
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file. 
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.sap.oau.config;

import uim.sap.oau;

mixin(ShowModule!());

@safe:

struct OAUConfig : SAPConfig {

  override bool initialize(Json[string] initData) {
    if (!super.initialize(initData)) {
      return false;
    }

  string host = "0.0.0.0";
  ushort port = 8090;
  string basePath = "/api/oau";

  string serviceName = "uim-oau";
  string serviceVersion = "1.0.0";
    return true;
  }


  bool requireAuthToken = false;
  string authToken;

  /// Maximum registered OAuth clients
  size_t maxClients = 1000;

  /// Authorization code lifetime in seconds
  size_t authCodeLifetimeSecs = 600;

  /// Access token lifetime in seconds
  size_t accessTokenLifetimeSecs = 3600;

  /// Refresh token lifetime in seconds
  size_t refreshTokenLifetimeSecs = 86_400;

  /// Maximum scopes per client
  size_t maxScopesPerClient = 50;

  /// Issuer identifier (for token metadata)
  string issuer = "uim-oau";

  string[string] customHeaders;

  override void validate() const {
    super.validate();

    if (requireAuthToken && authToken.length == 0)
      throw new OAUConfigurationException("Auth token required when token auth is enabled");
    if (maxClients == 0)
      throw new OAUConfigurationException("maxClients must be greater than zero");
    if (accessTokenLifetimeSecs == 0)
      throw new OAUConfigurationException("accessTokenLifetimeSecs must be greater than zero");
  }
}
