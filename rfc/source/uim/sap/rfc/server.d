module uim.sap.rfc.server;

import std.array : split;
import std.conv : to;
import std.string : startsWith;

import vibe.data.json : Json;
import vibe.core.core : runApplication;
import vibe.http.common : HTTPMethod;
import vibe.http.server : HTTPServerRequest, HTTPServerResponse, HTTPServerSettings, listenHTTP;

import uim.sap.rms.exceptions;
import uim.sap.rms.models;
import uim.sap.rms.service;

class RMSServer {
  private RMSService _service;

  this(RMSService service) {
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
    foreach (key, value; _service.config.customHeaders) {
      res.headers[key] = value;
    }

    auto basePath = _service.config.basePath;
    auto path = req.path;
    if (!path.startsWith(basePath)) {
      respondError(res, "Not found", 404);
      return;
    }

    auto subPath = path[basePath.length .. $];
    if (subPath.length == 0)
      subPath = "/";

    if (subPath == "/health" && req.method == HTTPMethod.GET) {
      res.writeJsonBody(_service.health(), 200);
      return;
    }

    if (subPath == "/ready" && req.method == HTTPMethod.GET) {
      res.writeJsonBody(_service.ready(), 200);
      return;
    }

    try {
      validateManagementAuth(req);
      routeApi(req, res, subPath);
    } catch (RMSAuthorizationException e) {
      respondError(res, e.msg, 401);
    } catch (RMSNotFoundException e) {
      respondError(res, e.msg, 404);
    } catch (RMSValidationException e) {
      respondError(res, e.msg, 422);
    } catch (RMSException e) {
      respondError(res, e.msg, 500);
    } catch (Exception e) {
      respondError(res, e.msg, 500);
    }
  }

  private void routeApi(HTTPServerRequest req, HTTPServerResponse res, string subPath) {
    auto segments = normalizedSegments(subPath);
    auto tenant = tenantFromHeaders(req);

    if (
      segments.length == 2 && segments[0] == "v1" &&
      segments[1] == "team-categories" && req.method == HTTPMethod.GET
      ) {
      res.writeJsonBody(_service.sapDeliveredCategories(), 200);
      return;
    }

    if (
      segments.length == 2 && segments[0] == "v1" &&
      segments[1] == "team-types" && req.method == HTTPMethod.GET
      ) {
      res.writeJsonBody(_service.listTeamTypes(tenant), 200);
      return;
    }
    if (
      segments.length == 3 && segments[0] == "v1" &&
      segments[1] == "team-types" && req.method == HTTPMethod.PUT
      ) {
      res.writeJsonBody(_service.upsertTeamType(tenant, segments[2], req.json), 200);
      return;
    }
    if (
      segments.length == 3 && segments[0] == "v1" &&
      segments[1] == "team-types" && req.method == HTTPMethod.DELETE
      ) {
      res.writeJsonBody(_service.deleteTeamType(tenant, segments[2]), 200);
      return;
    }

    if (segments.length == 2 && segments[0] == "v1" && segments[1] == "functions" && req.method == HTTPMethod
      .GET) {
      res.writeJsonBody(_service.listFunctions(tenant), 200);
      return;
    }
    if (segments.length == 3 && segments[0] == "v1" && segments[1] == "functions" && req.method == HTTPMethod
      .PUT) {
      res.writeJsonBody(_service.upsertFunction(tenant, segments[2], req.json), 200);
      return;
    }
    if (
      segments.length == 3 && segments[0] == "v1" &&
      segments[1] == "functions" && req.method == HTTPMethod.DELETE
      ) {
      res.writeJsonBody(_service.deleteFunction(tenant, segments[2]), 200);
      return;
    }

    if (segments.length == 2 && segments[0] == "v1" && segments[1] == "teams" && req.method == HTTPMethod
      .GET) {
      res.writeJsonBody(_service.listTeams(tenant), 200);
      return;
    }
    if (segments.length == 2 && segments[0] == "v1" && segments[1] == "teams" && req.method == HTTPMethod
      .POST) {
      res.writeJsonBody(_service.createTeam(tenant, req.json), 201);
      return;
    }
    if (segments.length == 3 && segments[0] == "v1" && segments[1] == "teams" && req.method == HTTPMethod
      .GET) {
      res.writeJsonBody(_service.getTeam(tenant, segments[2]), 200);
      return;
    }
    if (segments.length == 3 && segments[0] == "v1" && segments[1] == "teams" && req.method == HTTPMethod
      .PUT) {
      res.writeJsonBody(_service.updateTeam(tenant, segments[2], req.json), 200);
      return;
    }
    if (segments.length == 3 && segments[0] == "v1" && segments[1] == "teams" && req.method == HTTPMethod
      .DELETE) {
      res.writeJsonBody(_service.deleteTeam(tenant, segments[2]), 200);
      return;
    }
    if (
      segments.length == 4 && segments[0] == "v1" &&
      segments[1] == "teams" && segments[3] == "copy" &&
      req.method == HTTPMethod.POST
      ) {
      res.writeJsonBody(_service.copyTeam(tenant, segments[2], req.json), 201);
      return;
    }

    if (segments.length == 2 && segments[0] == "v1" && segments[1] == "rules" && req.method == HTTPMethod
      .GET) {
      res.writeJsonBody(_service.listRules(tenant), 200);
      return;
    }
    if (segments.length == 2 && segments[0] == "v1" && segments[1] == "rules" && req.method == HTTPMethod
      .POST) {
      res.writeJsonBody(_service.createRule(tenant, req.json), 201);
      return;
    }
    if (segments.length == 3 && segments[0] == "v1" && segments[1] == "rules" && req.method == HTTPMethod
      .GET) {
      res.writeJsonBody(_service.getRule(tenant, segments[2]), 200);
      return;
    }
    if (segments.length == 3 && segments[0] == "v1" && segments[1] == "rules" && req.method == HTTPMethod
      .PUT) {
      res.writeJsonBody(_service.updateRule(tenant, segments[2], req.json), 200);
      return;
    }
    if (segments.length == 3 && segments[0] == "v1" && segments[1] == "rules" && req.method == HTTPMethod
      .DELETE) {
      res.writeJsonBody(_service.deleteRule(tenant, segments[2]), 200);
      return;
    }

    if (
      segments.length == 2 && segments[0] == "v1" &&
      segments[1] == "determine" && req.method == HTTPMethod.POST
      ) {
      res.writeJsonBody(_service.determine(tenant, req.json), 200);
      return;
    }

    if (segments.length == 2 && segments[0] == "v1" && segments[1] == "logs" && req.method == HTTPMethod
      .GET) {
      size_t limit = 100;
      auto rawLimit = req.query.get("limit", "100");
      try {
        auto parsed = to!long(rawLimit);
        if (parsed > 0) {
          limit = cast(size_t)parsed;
        }
      } catch (Exception) {
      }
      res.writeJsonBody(_service.listLogs(tenant, limit), 200);
      return;
    }

    if (segments.length == 2 && segments[0] == "v1" && segments[1] == "export" && req.method == HTTPMethod
      .GET) {
      res.writeJsonBody(_service.exportData(tenant), 200);
      return;
    }

    respondError(res, "Not found", 404);
  }

  private TenantContext tenantFromHeaders(HTTPServerRequest req) {
    TenantContext tenant;
    tenant.tenantId = req.headers.get("X-Tenant-ID", _service.config.defaultTenant);
    tenant.spaceId = req.headers.get("X-Space-ID", _service.config.defaultSpace);
    return tenant;
  }

  private void validateManagementAuth(HTTPServerRequest req) {
    if (!_service.config.requireManagementAuth) {
      return;
    }

    if (!("Authorization" in req.headers)) {
      throw new RMSAuthorizationException("Missing Authorization header");
    }

    auto expected = "Bearer " ~ _service.config.managementAuthToken;
    if (req.headers["Authorization"] != expected) {
      throw new RMSAuthorizationException("Invalid management token");
    }
  }

  private string[] normalizedSegments(string subPath) {
    auto clean = subPath;
    if (clean.length > 0 && clean[0] == '/')
      clean = clean[1 .. $];
    if (clean.length > 0 && clean[$ - 1] == '/')
      clean = clean[0 .. $ - 1];
    if (clean.length == 0)
      return [];
    return clean.split("/");
  }

  private void respondError(HTTPServerResponse res, string message, int statusCode) {
    Json payload = Json.emptyObject;
    payload["success"] = false;
    payload["message"] = message;
    payload["status_code"] = statusCode;
    res.writeJsonBody(payload, statusCode);
  }
}
