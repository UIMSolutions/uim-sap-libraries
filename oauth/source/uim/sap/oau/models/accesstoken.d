module uim.sap.oau.models.accesstoken;

import std.datetime : Clock, SysTime;

import vibe.data.json : Json;

import uim.sap.oau.enumerations;

@safe:

/// OAuth 2.0 access token
struct OAUAccessToken {
    string tokenId;
    string accessToken;
    OAUTokenType tokenType = OAUTokenType.bearer;
    OAUTokenStatus status = OAUTokenStatus.active;
    string clientId;
    string userId;           // empty for client_credentials grant
    string[] scopes;
    OAUGrantType grantType;
    string issuer;
    size_t expiresInSecs;
    SysTime issuedAt;
    SysTime expiresAt;

    Json toJson() const {
        Json j = Json.emptyObject;
        j["access_token"] = accessToken;
        j["token_type"] = cast(string) tokenType;

        import std.conv : to;
        j["expires_in"] = expiresInSecs.to!long;

        Json sc = Json.emptyArray;
        foreach (s; scopes) sc ~= Json(s);
        j["scope"] = scopeString();
        return j;
    }

    Json toDetailJson() const {
        Json j = toJson();
        j["token_id"] = tokenId;
        j["client_id"] = clientId;
        j["user_id"] = userId;
        j["grant_type"] = cast(string) grantType;
        j["issuer"] = issuer;
        j["status"] = cast(string) status;
        j["issued_at"] = issuedAt.toISOExtString();
        j["expires_at"] = expiresAt.toISOExtString();
        return j;
    }

    string scopeString() const {
        import std.array : join;
        return scopes.join(" ");
    }
}
