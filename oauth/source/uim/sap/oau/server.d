module uim.sap.oau.server;

import std.array : split;
import std.string : startsWith;

import vibe.data.json : Json;
import vibe.http.common : HTTPMethod;
import vibe.http.server : HTTPServerRequest, HTTPServerResponse, HTTPServerSettings, listenHTTP;

import uim.sap.oau.exceptions;
import uim.sap.oau.service;

/**
 * HTTP server for OAuth 2.0 on SAP BTP.
 *
 * Routes:
 *   GET  /health
 *   GET  /ready
 *
 *   OAuth Endpoints:
 *     POST /oauth/authorize        — Authorization code request
 *     POST /oauth/token            — Token exchange / client credentials
 *     POST /oauth/introspect       — Token introspection (RFC 7662)
 *     POST /oauth/revoke           — Token revocation (RFC 7009)
 *
 *   Client Management:
 *     GET    /v1/clients            — List clients
 *     POST   /v1/clients            — Register client
 *     GET    /v1/clients/{id}       — Get client
 *     PUT    /v1/clients/{id}       — Update client
 *     DELETE /v1/clients/{id}       — Delete client
 *     POST   /v1/clients/{id}/suspend — Suspend client
 *
 *   Scope Management:
 *     GET    /v1/scopes             — List scopes
 *     POST   /v1/scopes             — Create scope
 *     GET    /v1/scopes/{id}        — Get scope
 *     DELETE /v1/scopes/{id}        — Delete scope
 */
class OAUServer {
    private OAUService _service;

    this(OAUService service) {
        _service = service;
    }

    void run() {
        auto settings = new HTTPServerSettings;
        settings.port = _service.config.port;
        settings.bindAddresses = [_service.config.host];
        listenHTTP(settings, &handleRequest);
        runApplication();
    }

    private void handleRequest(HTTPServerRequest req, HTTPServerResponse res) {
        foreach (key, value; _service.config.customHeaders)
            res.headers[key] = value;

        auto basePath = _service.config.basePath;
        auto path = req.path;

        if (!path.startsWith(basePath)) {
            respondError(res, "Not found", 404);
            return;
        }

        auto subPath = path[basePath.length .. $];
        if (subPath.length == 0)
            subPath = "/";

        // Health / ready (no auth required)
        if (subPath == "/health" && req.method == HTTPMethod.GET) {
            res.writeJsonBody(_service.health(), 200);
            return;
        }
        if (subPath == "/ready" && req.method == HTTPMethod.GET) {
            res.writeJsonBody(_service.ready(), 200);
            return;
        }

        try {
            auto segments = normalizedSegments(subPath);

            // ── OAuth Protocol Endpoints ──
            if (segments.length >= 1 && segments[0] == "oauth") {
                routeOAuth(req, res, segments[1 .. $]);
                return;
            }

            // ── Management Endpoints (require admin auth) ──
            validateAuth(req);

            if (segments.length >= 2 && segments[0] == "v1" && segments[1] == "clients") {
                routeClients(req, res, segments[2 .. $]);
                return;
            }
            if (segments.length >= 2 && segments[0] == "v1" && segments[1] == "scopes") {
                routeScopes(req, res, segments[2 .. $]);
                return;
            }

            respondError(res, "Not found", 404);
        } catch (OAUAuthorizationException e) {
            respondError(res, e.msg, 401);
        } catch (OAUConflictException e) {
            respondError(res, e.msg, 409);
        } catch (OAUNotFoundException e) {
            respondError(res, e.msg, 404);
        } catch (OAUValidationException e) {
            respondError(res, e.msg, 400);
        } catch (OAUQuotaExceededException e) {
            respondError(res, e.msg, 429);
        } catch (OAUConfigurationException e) {
            respondError(res, e.msg, 500);
        } catch (OAUException e) {
            respondError(res, e.msg, 500);
        } catch (Exception e) {
            respondError(res, "Internal server error", 500);
        }
    }

    // ──────────────────────────────────────
    //  OAuth Protocol Routes
    // ──────────────────────────────────────

    private void routeOAuth(HTTPServerRequest req, HTTPServerResponse res, string[] rest) {
        if (rest.length != 1 || req.method != HTTPMethod.POST) {
            respondError(res, "Not found", 404);
            return;
        }

        Json body_ = parseBody(req);

        switch (rest[0]) {
            case "authorize":
                res.writeJsonBody(_service.authorize(body_), 200);
                return;
            case "token":
                res.writeJsonBody(_service.token(body_), 200);
                return;
            case "introspect":
                res.writeJsonBody(_service.introspect(body_), 200);
                return;
            case "revoke":
                res.writeJsonBody(_service.revoke(body_), 200);
                return;
            default:
                respondError(res, "Not found", 404);
                return;
        }
    }

    // ──────────────────────────────────────
    //  Client Management Routes
    // ──────────────────────────────────────

    private void routeClients(HTTPServerRequest req, HTTPServerResponse res, string[] rest) {
        // GET|POST /v1/clients
        if (rest.length == 0) {
            if (req.method == HTTPMethod.GET) {
                res.writeJsonBody(_service.listClients(), 200);
                return;
            }
            if (req.method == HTTPMethod.POST) {
                Json body_ = parseBody(req);
                res.writeJsonBody(_service.registerClient(body_), 201);
                return;
            }
            respondError(res, "Method not allowed", 405);
            return;
        }

        string clientId = rest[0];

        // POST /v1/clients/{id}/suspend
        if (rest.length == 2 && rest[1] == "suspend" && req.method == HTTPMethod.POST) {
            res.writeJsonBody(_service.suspendClient(clientId), 200);
            return;
        }

        // GET|PUT|DELETE /v1/clients/{id}
        if (rest.length == 1) {
            if (req.method == HTTPMethod.GET) {
                res.writeJsonBody(_service.getClient(clientId), 200);
                return;
            }
            if (req.method == HTTPMethod.PUT) {
                Json body_ = parseBody(req);
                res.writeJsonBody(_service.updateClient(clientId, body_), 200);
                return;
            }
            if (req.method == HTTPMethod.DELETE) {
                res.writeJsonBody(_service.deleteClient(clientId), 200);
                return;
            }
            respondError(res, "Method not allowed", 405);
            return;
        }

        respondError(res, "Not found", 404);
    }

    // ──────────────────────────────────────
    //  Scope Management Routes
    // ──────────────────────────────────────

    private void routeScopes(HTTPServerRequest req, HTTPServerResponse res, string[] rest) {
        // GET|POST /v1/scopes
        if (rest.length == 0) {
            if (req.method == HTTPMethod.GET) {
                res.writeJsonBody(_service.listScopes(), 200);
                return;
            }
            if (req.method == HTTPMethod.POST) {
                Json body_ = parseBody(req);
                res.writeJsonBody(_service.createScope(body_), 201);
                return;
            }
            respondError(res, "Method not allowed", 405);
            return;
        }

        string scopeId = rest[0];

        // GET|DELETE /v1/scopes/{id}
        if (rest.length == 1) {
            if (req.method == HTTPMethod.GET) {
                res.writeJsonBody(_service.getScope(scopeId), 200);
                return;
            }
            if (req.method == HTTPMethod.DELETE) {
                res.writeJsonBody(_service.deleteScope(scopeId), 200);
                return;
            }
            respondError(res, "Method not allowed", 405);
            return;
        }

        respondError(res, "Not found", 404);
    }

    // ──────────────────────────────────────
    //  Helpers
    // ──────────────────────────────────────

    private void validateAuth(HTTPServerRequest req) {
        if (!_service.config.requireAuthToken)
            return;
        auto authHeader = req.headers.get("Authorization", "");
        if (!authHeader.startsWith("Bearer "))
            throw new OAUAuthorizationException("Missing bearer token");
        auto token = authHeader[7 .. $];
        if (token != _service.config.authToken)
            throw new OAUAuthorizationException("Invalid bearer token");
    }

    private static string[] normalizedSegments(string path) {
        import std.algorithm : filter;
        import std.array : array;
        return path.split("/").filter!(s => s.length > 0).array;
    }

    private static Json parseBody(HTTPServerRequest req) {
        try {
            return req.readJson();
        } catch (Exception) {
            return Json.emptyObject;
        }
    }

    private static void respondError(HTTPServerResponse res, string message, int code) {
        Json j = Json.emptyObject;
        j["error"] = message;
        j["code"] = code;
        res.writeJsonBody(j, code);
    }
}
