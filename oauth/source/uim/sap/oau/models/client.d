module uim.sap.oau.models.client;

import std.datetime : Clock, SysTime;

import vibe.data.json : Json;

import uim.sap.oau.enumerations;

@safe:

/// OAuth 2.0 client registration
struct OAUClient {
    string clientId;
    string clientSecret;
    string name;
    string description;
    OAUClientType clientType = OAUClientType.confidential;
    OAUClientStatus status = OAUClientStatus.active;
    string[] redirectUris;
    OAUGrantType[] grantTypes;
    string[] scopes;
    string contactEmail;
    string[string] metadata;
    SysTime createdAt;
    SysTime updatedAt;

    Json toJson() const {
        Json j = Json.emptyObject;
        j["client_id"] = clientId;
        // Never expose client_secret in normal responses
        j["name"] = name;
        j["description"] = description;
        j["client_type"] = cast(string) clientType;
        j["status"] = cast(string) status;

        Json uris = Json.emptyArray;
        foreach (u; redirectUris) uris ~= Json(u);
        j["redirect_uris"] = uris;

        Json grants = Json.emptyArray;
        foreach (g; grantTypes) grants ~= Json(cast(string) g);
        j["grant_types"] = grants;

        Json sc = Json.emptyArray;
        foreach (s; scopes) sc ~= Json(s);
        j["scopes"] = sc;

        j["contact_email"] = contactEmail;

        if (metadata.length > 0) {
            Json m = Json.emptyObject;
            foreach (k, v; metadata) m[k] = v;
            j["metadata"] = m;
        }
        j["created_at"] = createdAt.toISOExtString();
        j["updated_at"] = updatedAt.toISOExtString();
        return j;
    }

    Json toJsonWithSecret() const {
        Json j = toJson();
        j["client_secret"] = clientSecret;
        return j;
    }
}

OAUClient clientFromJson(string clientId, Json req) {
    OAUClient c;
    c.clientId = clientId;
    c.createdAt = Clock.currTime();
    c.updatedAt = c.createdAt;

    if ("name" in req && req["name"].isString)
        c.name = req["name"].get!string;
    else
        c.name = clientId;
    if ("description" in req && req["description"].isString)
        c.description = req["description"].get!string;
    if ("client_type" in req && req["client_type"].isString)
        c.clientType = parseClientType(req["client_type"].get!string);
    if ("contact_email" in req && req["contact_email"].isString)
        c.contactEmail = req["contact_email"].get!string;

    if ("redirect_uris" in req && req["redirect_uris"].type == Json.Type.array) {
        foreach (v; req["redirect_uris"])
            if (v.isString) c.redirectUris ~= v.get!string;
    }
    if ("grant_types" in req && req["grant_types"].type == Json.Type.array) {
        foreach (v; req["grant_types"])
            if (v.isString) c.grantTypes ~= parseGrantType(v.get!string);
    }
    if ("scopes" in req && req["scopes"].type == Json.Type.array) {
        foreach (v; req["scopes"])
            if (v.isString) c.scopes ~= v.get!string;
    }
    if ("metadata" in req && req["metadata"].type == Json.Type.object) {
        foreach (string k, v; req["metadata"])
            if (v.isString) c.metadata[k] = v.get!string;
    }
    return c;
}

private OAUClientType parseClientType(string s) {
    switch (s) {
        case "public": return OAUClientType.public_;
        case "confidential": return OAUClientType.confidential;
        default: return OAUClientType.confidential;
    }
}

private OAUGrantType parseGrantType(string s) {
    switch (s) {
        case "authorization_code": return OAUGrantType.authorizationCode;
        case "client_credentials": return OAUGrantType.clientCredentials;
        case "refresh_token": return OAUGrantType.refreshToken;
        default: return OAUGrantType.authorizationCode;
    }
}
