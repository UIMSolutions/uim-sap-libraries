module uim.sap.oau.models.introspection;

import vibe.data.json : Json;

import uim.sap.oau.enumerations;

@safe:

/// OAuth 2.0 token introspection response (RFC 7662)
struct OAUTokenIntrospection {
    bool active;
    string scope_;
    string clientId;
    string userId;
    OAUTokenType tokenType = OAUTokenType.bearer;
    long exp;                // expiration unix timestamp
    long iat;                // issued-at unix timestamp
    string iss;              // issuer
    string jti;              // token identifier

    Json toJson() const {
        Json j = Json.emptyObject;
        j["active"] = active;
        if (active) {
            j["scope"] = scope_;
            j["client_id"] = clientId;
            if (userId.length > 0)
                j["username"] = userId;
            j["token_type"] = cast(string) tokenType;
            j["exp"] = exp;
            j["iat"] = iat;
            j["iss"] = iss;
            j["jti"] = jti;
        }
        return j;
    }
}
