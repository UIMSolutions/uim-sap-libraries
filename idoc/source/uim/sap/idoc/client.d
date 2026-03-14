/**
 * IDOC client
 *
 * Copyright: Copyright © 2018-2026, Ozan Nurettin Süel
 * License: Apache-2.0
 * Authors: Ozan Nurettin Süel
 */
module uim.sap.idoc.client;

import uim.sap.idoc;

@safe:

class IDocClient {
  private IDocConfig _config;

  this(IDocConfig config) {
    super(config);
  }

  bool testConnection() {
    try {
      auto response = requestJSON(HTTPMethod.GET, _config.serviceUrl() ~ "/ping");
      return response.success;
    } catch (Exception) {
      return false;
    }
  }

  IDocResponse submit(IDocSubmitRequest request) {
    if (request.control.idocType.length == 0) {
      throw new IDocRequestException("IDOC type cannot be empty");
    }

    if (request.control.messageType.length == 0) {
      throw new IDocRequestException("Message type cannot be empty");
    }

    auto response = requestJSON(
      HTTPMethod.POST,
      _config.serviceUrl() ~ "/inbound",
      request.toJson()
    );

    if ("documentNumber" in response.data && response.data["documentNumber"].isString) {
      response.documentNumber = response.data["documentNumber"].get!string;
    }

    if ("status" in response.data && response.data["status"].isString) {
      response.status = response.data["status"].get!string;
    }

    return response;
  }

  IDocResponse submit(
    string idocType,
    string messageType,
    Json segments,
    string senderPort = "",
    string receiverPort = "",
    bool testRun = false
  ) {
    IDocSubmitRequest request;
    request.control.idocType = idocType;
    request.control.messageType = messageType;
    request.control.senderPort = senderPort;
    request.control.receiverPort = receiverPort;
    request.segments = segments;
    request.testRun = testRun;

    return submit(request);
  }

  IDocResponse getStatus(string documentNumber) {
    if (documentNumber.length == 0) {
      throw new IDocRequestException("Document number cannot be empty");
    }

    auto url = _config.serviceUrl() ~ "/status/" ~ urlEncode(documentNumber);
    auto response = requestJSON(HTTPMethod.GET, url);

    response.documentNumber = documentNumber;
    if ("status" in response.data && response.data["status"].isString) {
      response.status = response.data["status"].get!string;
    }

    return response;
  }

  private IDocResponse requestJSON(HTTPMethod method, string url, Json body = Json.emptyObject) {
    uint attempts = 0;

    while (attempts <= _config.maxRetries) {
      try {
        IDocResponse response;
        response.timestamp = Clock.currTime();

        requestHTTP(url,
          (scope req) {
          req.method = method;
          req.headers["Accept"] = "application/json";

          applyAuth(req);
          applySAPHeaders(req);

          foreach (key, value; _config.customHeaders) {
            req.headers[key] = value;
          }

          if (method == HTTPMethod.POST || method == HTTPMethod.PUT || method == HTTPMethod.PATCH) {
            req.headers["Content-Type"] = "application/json";
            req.writeJsonBody(body);
          }
        },
          (scope res) {
          response.statusCode = res.statusCode;
          response.success = res.statusCode >= 200 && res.statusCode < 300;

          try {
            response.data = res.readJson();
          } catch (Exception) {
            response.data = Json.emptyObject;
          }

          if (!response.success) {
            if ("error" in response.data && response.data["error"].isString) {
              response.errorMessage = response.data["error"].get!string;
            } else {
              response.errorMessage = format(
                "IDOC request failed with status code %d",
                response.statusCode
              );
            }
          }
        }
        );

        if (!response.success) {
          throw new IDocRequestException(response.errorMessage, response.statusCode);
        }

        return response;
      } catch (IDocRequestException e) {
        throw e;
      } catch (Exception e) {
        attempts++;
        if (attempts > _config.maxRetries) {
          throw new IDocConnectionException(
            format("IDOC request failed after %d retries: %s", attempts, e.msg)
          );
        }
      }
    }

    throw new IDocConnectionException("IDOC request failed with unknown error");
  }

  private void applyAuth(HTTPClientRequest req) {
    final switch (_config.authType) {
    case IDocAuthType.None:
      break;
    case IDocAuthType.Basic:
      auto creds = _config.username ~ ":" ~ _config.password;
      auto token = Base64.encode(cast(const(ubyte)[])creds).idup;
      req.headers["Authorization"] = "Basic " ~ token;
      break;
    case IDocAuthType.Bearer:
      req.headers["Authorization"] = "Bearer " ~ _config.bearerToken;
      break;
    }
  }

  private void applySAPHeaders(HTTPClientRequest req) {
    if (_config.sapClient.length > 0) {
      req.headers["sap-client"] = _config.sapClient;
    }

    if (_config.sapLanguage.length > 0) {
      req.headers["sap-language"] = _config.sapLanguage;
    }
  }
}
