module uim.sap.oau.models.refreshtoken;

import std.datetime : Clock, SysTime;

import vibe.data.json : Json;

import uim.sap.oau.enumerations;

@safe:

/// OAuth 2.0 refresh token
struct OAURefreshToken {
    string tokenId;
    string refreshToken;
    OAUTokenStatus status = OAUTokenStatus.active;
    string clientId;
    string userId;
    string[] scopes;
    string accessTokenId;    // linked access token
    SysTime issuedAt;
    SysTime expiresAt;

    Json toJson() const {
        Json j = Json.emptyObject;
        j["token_id"] = tokenId;
        j["refresh_token"] = refreshToken;
        j["status"] = cast(string) status;
        j["client_id"] = clientId;
        j["user_id"] = userId;

        Json sc = Json.emptyArray;
        foreach (s; scopes) sc ~= Json(s);
        j["scopes"] = sc;

        j["access_token_id"] = accessTokenId;
        j["issued_at"] = issuedAt.toISOExtString();
        j["expires_at"] = expiresAt.toISOExtString();
        return j;
    }
}
