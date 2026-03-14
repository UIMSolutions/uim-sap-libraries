module uim.sap.oau.models.authcode;

import std.datetime : Clock, SysTime;

import vibe.data.json : Json;

import uim.sap.oau.enumerations;

@safe:

/// OAuth 2.0 authorization code
struct OAUAuthorizationCode {
    string codeId;
    string code;
    OAUAuthCodeStatus status = OAUAuthCodeStatus.pending;
    string clientId;
    string userId;
    string redirectUri;
    string[] scopes;
    string state;            // CSRF protection
    string codeChallenge;    // PKCE
    string codeChallengeMethod; // PKCE: S256 or plain
    SysTime issuedAt;
    SysTime expiresAt;

    Json toJson() const {
        Json j = Json.emptyObject;
        j["code_id"] = codeId;
        j["code"] = code;
        j["status"] = cast(string) status;
        j["client_id"] = clientId;
        j["user_id"] = userId;
        j["redirect_uri"] = redirectUri;

        Json sc = Json.emptyArray;
        foreach (s; scopes) sc ~= Json(s);
        j["scopes"] = sc;

        j["state"] = state;
        j["issued_at"] = issuedAt.toISOExtString();
        j["expires_at"] = expiresAt.toISOExtString();
        return j;
    }
}
