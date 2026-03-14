/****************************************************************************************************************
* Copyright: © 2018-2026 Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*) 
* License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file. 
* Authors: Ozan Nurettin Süel (aka UI-Manufaktur UG *R.I.P*)
*****************************************************************************************************************/
module uim.sap.rfc.client;

import std.string : format;
import std.base64 : Base64;
import std.datetime : Clock;

import vibe.http.client : requestHTTP, HTTPClientRequest;
import vibe.http.common : HTTPMethod;
import vibe.data.json : Json;

import uim.sap.rfc.config;
import uim.sap.rfc.models;
import uim.sap.rfc.exceptions;

class RFCClient {
    private RFCConfig _config;

    this(RFCConfig config) {
        config.validate();
        _config = config;
    }

    @property const(RFCConfig) config() const {
        return _config;
    }

    bool testConnection() {
        try {
            auto response = ping();
            return response.success;
        } catch (Exception) {
            return false;
        }
    }

    RFCResponse ping() {
        RFCRequest request;
        request.functionName = "RFC_PING";
        request.parameters = Json.emptyObject;
        return invoke(request);
    }

    RFCResponse invoke(
        string functionName,
        Json parameters = Json.emptyObject,
        string destination = ""
    ) {
        RFCRequest request;
        request.functionName = functionName;
        request.parameters = parameters;
        request.destination = destination;

        return invoke(request);
    }

    RFCResponse invoke(RFCRequest request) {
        if (request.functionName.length == 0) {
            throw new RFCInvocationException("RFC function name cannot be empty");
        }

        auto url = format("%s/%s", _config.serviceUrl(), request.functionName);

        uint attempts = 0;
        while (attempts <= _config.maxRetries) {
            try {
                RFCResponse response;
                response.timestamp = Clock.currTime();

                requestHTTP(url,
                    (scope req) {
                        req.method = HTTPMethod.POST;
                        req.headers["Content-Type"] = "application/json";
                        req.headers["Accept"] = "application/json";

                        applyAuth(req);
                        applySAPHeaders(req);

                        foreach (key, value; _config.customHeaders) {
                            req.headers[key] = value;
                        }

                        req.writeJsonBody(request.toJson());
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
                                    "RFC invocation failed with status code %d",
                                    res.statusCode
                                );
                            }
                        }
                    }
                );

                if (!response.success) {
                    throw new RFCInvocationException(response.errorMessage, response.statusCode);
                }

                return response;
            } catch (RFCInvocationException e) {
                throw e;
            } catch (Exception e) {
                attempts++;
                if (attempts > _config.maxRetries) {
                    throw new RFCConnectionException(
                        format("RFC request failed after %d retries: %s", attempts, e.msg)
                    );
                }
            }
        }

        throw new RFCConnectionException("RFC request failed with unknown error");
    }

    private void applyAuth(HTTPClientRequest req) {
        final switch (_config.authType) {
            case RFCAuthType.None:
                break;
            case RFCAuthType.Basic:
                auto creds = _config.username ~ ":" ~ _config.password;
                auto token = Base64.encode(cast(const(ubyte)[])creds);
                req.headers["Authorization"] = "Basic " ~ token;
                break;
            case RFCAuthType.Bearer:
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
