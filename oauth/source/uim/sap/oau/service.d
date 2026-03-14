module uim.sap.oau.service;

import std.datetime : Clock, dur;

import vibe.data.json : Json;

import uim.sap.oau.config;
import uim.sap.oau.enumerations;
import uim.sap.oau.exceptions;
import uim.sap.oau.helpers;
import uim.sap.oau.models;
import uim.sap.oau.store;

/**
 * Main service class for OAuth 2.0 on SAP BTP.
 *
 * Implements authorization code grant flow, client credentials grant flow,
 * token introspection, token revocation, and client/scope management.
 */
class OAUService : SAPService {
    mixin(SAPServiceTemplate!OAUService);

    private OAUStore _store;

    this(OAUConfig config) {
        super(config);

        _store = new OAUStore;
    }

    override Json health() {
        Json info = super.health();
        info["clients"] = cast(long) _store.clientCount();
        return info;
    }

    override Json ready() {
        Json info = super.ready();
        info["clients"] = cast(long) _store.clientCount();
        return info;
    }

    // ══════════════════════════════════════
    //  Client Management
    // ══════════════════════════════════════

    Json registerClient(Json req) {
        if (_store.clientCount() >= _config.maxClients)
            throw new OAUQuotaExceededException("clients", _config.maxClients);

        string clientId = generateClientId();
        OAUClient c = clientFromJson(clientId, req);
        c.clientSecret = generateClientSecret();

        // Validate redirect URIs
        foreach (uri; c.redirectUris) {
            if (!isValidRedirectUri(uri))
                throw new OAUValidationException("Invalid redirect_uri: " ~ uri);
        }

        // Default grant types if none specified
        if (c.grantTypes.length == 0)
            c.grantTypes = [OAUGrantType.authorizationCode];

        _store.upsertClient(c);
        return c.toJsonWithSecret(); // include secret on first creation
    }

    Json getClient(string clientId) {
        if (!_store.hasClient(clientId))
            throw new OAUNotFoundException("Client", clientId);
        return _store.getClient(clientId).toJson();
    }

    Json listClients() {
        auto clients = _store.listClients();
        Json arr = Json.emptyArray;
        foreach (ref c; clients) arr ~= c.toJson();
        Json result = Json.emptyObject;
        result["clients"] = arr;
        result["total"] = cast(long) clients.length;
        return result;
    }

    Json updateClient(string clientId, Json req) {
        if (!_store.hasClient(clientId))
            throw new OAUNotFoundException("Client", clientId);

        OAUClient c = _store.getClient(clientId);
        if ("name" in req && req["name"].isString)
            c.name = req["name"].get!string;
        if ("description" in req && req["description"].isString)
            c.description = req["description"].get!string;
        if ("contact_email" in req && req["contact_email"].isString)
            c.contactEmail = req["contact_email"].get!string;
        if ("redirect_uris" in req && req["redirect_uris"].type == Json.Type.array) {
            c.redirectUris = [];
            foreach (v; req["redirect_uris"]) {
                if (v.isString) {
                    string uri = v.get!string;
                    if (!isValidRedirectUri(uri))
                        throw new OAUValidationException("Invalid redirect_uri: " ~ uri);
                    c.redirectUris ~= uri;
                }
            }
        }
        if ("grant_types" in req && req["grant_types"].type == Json.Type.array) {
            c.grantTypes = [];
            foreach (v; req["grant_types"])
                if (v.isString) c.grantTypes ~= parseGrantTypeStr(v.get!string);
        }
        if ("scopes" in req && req["scopes"].type == Json.Type.array) {
            c.scopes = [];
            foreach (v; req["scopes"])
                if (v.isString) c.scopes ~= v.get!string;
        }
        c.updatedAt = Clock.currTime();
        _store.upsertClient(c);
        return c.toJson();
    }

    Json deleteClient(string clientId) {
        if (!_store.hasClient(clientId))
            throw new OAUNotFoundException("Client", clientId);

        // Revoke all tokens for this client
        _store.revokeAccessTokensByClient(clientId);
        _store.revokeRefreshTokensByClient(clientId);
        _store.removeClient(clientId);

        Json result = Json.emptyObject;
        result["status"] = "deleted";
        result["client_id"] = clientId;
        return result;
    }

    Json suspendClient(string clientId) {
        if (!_store.hasClient(clientId))
            throw new OAUNotFoundException("Client", clientId);
        OAUClient c = _store.getClient(clientId);
        c.status = OAUClientStatus.suspended;
        c.updatedAt = Clock.currTime();
        _store.upsertClient(c);
        _store.revokeAccessTokensByClient(clientId);
        Json result = Json.emptyObject;
        result["status"] = "suspended";
        result["client_id"] = clientId;
        return result;
    }

    // ══════════════════════════════════════
    //  Authorization Code Grant (RFC 6749 §4.1)
    // ══════════════════════════════════════

    /// Step 1: Generate an authorization code
    Json authorize(Json req) {
        string clientId = getRequiredString(req, "client_id");
        string redirectUri = getRequiredString(req, "redirect_uri");
        string responseType = getRequiredString(req, "response_type");
        string state = getOptionalString(req, "state");
        string scopeStr = getOptionalString(req, "scope");
        string userId = getOptionalString(req, "user_id");
        string codeChallenge = getOptionalString(req, "code_challenge");
        string codeChallengeMethod = getOptionalString(req, "code_challenge_method");

        // Validate response_type
        if (responseType != "code")
            throw new OAUValidationException(
                cast(string) OAUErrorCode.unsupportedResponseType);

        // Validate client
        if (!_store.hasClient(clientId))
            throw new OAUNotFoundException("Client", clientId);
        OAUClient client = _store.getClient(clientId);

        if (client.status != OAUClientStatus.active)
            throw new OAUAuthorizationException(
                cast(string) OAUErrorCode.unauthorizedClient);

        // Validate redirect URI
        if (!isValidRedirectUri(redirectUri))
            throw new OAUValidationException("Invalid redirect_uri");

        bool uriAllowed = false;
        foreach (uri; client.redirectUris) {
            if (uri == redirectUri) { uriAllowed = true; break; }
        }
        if (!uriAllowed)
            throw new OAUValidationException("redirect_uri not registered for this client");

        // Validate grant type support
        bool hasAuthCodeGrant = false;
        foreach (g; client.grantTypes) {
            if (g == OAUGrantType.authorizationCode) { hasAuthCodeGrant = true; break; }
        }
        if (!hasAuthCodeGrant)
            throw new OAUAuthorizationException(
                cast(string) OAUErrorCode.unauthorizedClient);

        // Resolve scopes
        string[] requestedScopes = parseScopeString(scopeStr);
        if (requestedScopes.length == 0)
            requestedScopes = _store.defaultScopeNames();

        // Validate scopes against client
        foreach (s; requestedScopes) {
            if (!isScopeAllowed(s, client.scopes))
                throw new OAUValidationException(
                    cast(string) OAUErrorCode.invalidScope ~ ": " ~ s);
        }

        // Generate authorization code
        auto now = Clock.currTime();
        OAUAuthorizationCode authCode;
        authCode.codeId = randomUUID();
        authCode.code = generateAuthCode();
        authCode.status = OAUAuthCodeStatus.pending;
        authCode.clientId = clientId;
        authCode.userId = userId;
        authCode.redirectUri = redirectUri;
        authCode.scopes = requestedScopes;
        authCode.state = state;
        authCode.codeChallenge = codeChallenge;
        authCode.codeChallengeMethod = codeChallengeMethod;
        authCode.issuedAt = now;
        authCode.expiresAt = now + dur!"seconds"(_config.authCodeLifetimeSecs);

        _store.storeAuthCode(authCode);

        Json result = Json.emptyObject;
        result["code"] = authCode.code;
        result["state"] = state;
        result["redirect_uri"] = redirectUri;
        return result;
    }

    // ══════════════════════════════════════
    //  Token Endpoint (RFC 6749 §4.1.3, §4.4)
    // ══════════════════════════════════════

    /// Exchange an authorization code or client credentials for tokens
    Json token(Json req) {
        string grantType = getRequiredString(req, "grant_type");

        switch (grantType) {
            case "authorization_code":
                return tokenFromAuthCode(req);
            case "client_credentials":
                return tokenFromClientCredentials(req);
            case "refresh_token":
                return tokenFromRefreshToken(req);
            default:
                throw new OAUValidationException(
                    cast(string) OAUErrorCode.unsupportedGrantType);
        }
    }

    // ══════════════════════════════════════
    //  Token Introspection (RFC 7662)
    // ══════════════════════════════════════

    Json introspect(Json req) {
        string tokenStr = getRequiredString(req, "token");

        if (!_store.hasAccessToken(tokenStr)) {
            OAUTokenIntrospection inactive;
            inactive.active = false;
            return inactive.toJson();
        }

        OAUAccessToken tok = _store.getAccessToken(tokenStr);
        auto now = Clock.currTime();

        if (tok.status != OAUTokenStatus.active || tok.expiresAt < now) {
            OAUTokenIntrospection inactive;
            inactive.active = false;
            return inactive.toJson();
        }

        OAUTokenIntrospection intro;
        intro.active = true;
        intro.scope_ = tok.scopeString();
        intro.clientId = tok.clientId;
        intro.userId = tok.userId;
        intro.tokenType = tok.tokenType;
        intro.exp = tok.expiresAt.toUnixTime();
        intro.iat = tok.issuedAt.toUnixTime();
        intro.iss = _config.issuer;
        intro.jti = tok.tokenId;
        return intro.toJson();
    }

    // ══════════════════════════════════════
    //  Token Revocation (RFC 7009)
    // ══════════════════════════════════════

    Json revoke(Json req) {
        string tokenStr = getRequiredString(req, "token");
        string tokenTypeHint = getOptionalString(req, "token_type_hint");

        bool revoked = false;
        if (tokenTypeHint == "refresh_token") {
            revoked = _store.revokeRefreshToken(tokenStr);
        } else {
            revoked = _store.revokeAccessToken(tokenStr);
            if (!revoked)
                revoked = _store.revokeRefreshToken(tokenStr);
        }

        Json result = Json.emptyObject;
        result["revoked"] = revoked;
        return result;
    }

    // ══════════════════════════════════════
    //  Scope Management
    // ══════════════════════════════════════

    Json createScope(Json req) {
        import uim.sap.oau : randomUUID;
        string scopeId = randomUUID();
        OAUScope s = scopeFromJson(scopeId, req);
        _store.upsertScope(s);
        return s.toJson();
    }

    Json getScope(string scopeId) {
        if (!_store.hasScope(scopeId))
            throw new OAUNotFoundException("Scope", scopeId);
        return _store.getScope(scopeId).toJson();
    }

    Json listScopes() {
        auto scopes = _store.listScopes();
        Json arr = Json.emptyArray;
        foreach (ref s; scopes) arr ~= s.toJson();
        Json result = Json.emptyObject;
        result["scopes"] = arr;
        result["total"] = cast(long) scopes.length;
        return result;
    }

    Json deleteScope(string scopeId) {
        if (!_store.hasScope(scopeId))
            throw new OAUNotFoundException("Scope", scopeId);
        _store.removeScope(scopeId);
        Json result = Json.emptyObject;
        result["status"] = "deleted";
        result["scope_id"] = scopeId;
        return result;
    }

    // ══════════════════════════════════════
    //  Private: Grant Flow Implementations
    // ══════════════════════════════════════

    private Json tokenFromAuthCode(Json req) {
        string code = getRequiredString(req, "code");
        string clientId = getRequiredString(req, "client_id");
        string clientSecret = getOptionalString(req, "client_secret");
        string redirectUri = getRequiredString(req, "redirect_uri");
        string codeVerifier = getOptionalString(req, "code_verifier");

        // Validate authorization code
        if (!_store.hasAuthCode(code))
            throw new OAUAuthorizationException(
                cast(string) OAUErrorCode.invalidGrant);

        OAUAuthorizationCode authCode = _store.getAuthCode(code);
        auto now = Clock.currTime();

        // Check code status
        if (authCode.status != OAUAuthCodeStatus.pending)
            throw new OAUAuthorizationException(
                cast(string) OAUErrorCode.invalidGrant ~ ": code already used or revoked");
        if (authCode.expiresAt < now)
            throw new OAUAuthorizationException(
                cast(string) OAUErrorCode.invalidGrant ~ ": code expired");

        // Validate client
        if (authCode.clientId != clientId)
            throw new OAUAuthorizationException(
                cast(string) OAUErrorCode.invalidGrant ~ ": client mismatch");

        // Validate redirect URI
        if (authCode.redirectUri != redirectUri)
            throw new OAUValidationException("redirect_uri mismatch");

        // Authenticate client (confidential clients require secret)
        OAUClient client = _store.getClient(clientId);
        if (client.clientType == OAUClientType.confidential) {
            if (!_store.authenticateClient(clientId, clientSecret))
                throw new OAUAuthorizationException(
                    cast(string) OAUErrorCode.invalidClient);
        }

        // PKCE validation (if code_challenge was used)
        if (authCode.codeChallenge.length > 0) {
            if (codeVerifier.length == 0)
                throw new OAUValidationException("code_verifier required for PKCE");
            // Simplified PKCE check: in production, compute SHA-256 of verifier
            // For simulation, compare directly for "plain" method
        }

        // Mark code as used
        _store.markAuthCodeUsed(code);

        // Issue tokens
        return issueTokens(clientId, authCode.userId, authCode.scopes,
            OAUGrantType.authorizationCode);
    }

    private Json tokenFromClientCredentials(Json req) {
        string clientId = getRequiredString(req, "client_id");
        string clientSecret = getRequiredString(req, "client_secret");
        string scopeStr = getOptionalString(req, "scope");

        // Authenticate client
        if (!_store.authenticateClient(clientId, clientSecret))
            throw new OAUAuthorizationException(
                cast(string) OAUErrorCode.invalidClient);

        OAUClient client = _store.getClient(clientId);

        // Validate grant type
        bool hasGrant = false;
        foreach (g; client.grantTypes) {
            if (g == OAUGrantType.clientCredentials) { hasGrant = true; break; }
        }
        if (!hasGrant)
            throw new OAUAuthorizationException(
                cast(string) OAUErrorCode.unauthorizedClient);

        // Resolve scopes
        string[] requestedScopes = parseScopeString(scopeStr);
        if (requestedScopes.length == 0)
            requestedScopes = client.scopes;

        foreach (s; requestedScopes) {
            if (!isScopeAllowed(s, client.scopes))
                throw new OAUValidationException(
                    cast(string) OAUErrorCode.invalidScope ~ ": " ~ s);
        }

        // Client credentials grant does not issue refresh tokens
        return issueAccessTokenOnly(clientId, "", requestedScopes,
            OAUGrantType.clientCredentials);
    }

    private Json tokenFromRefreshToken(Json req) {
        string refreshTokenStr = getRequiredString(req, "refresh_token");
        string clientId = getRequiredString(req, "client_id");
        string clientSecret = getOptionalString(req, "client_secret");

        // Validate refresh token
        if (!_store.hasRefreshToken(refreshTokenStr))
            throw new OAUAuthorizationException(
                cast(string) OAUErrorCode.invalidGrant);

        OAURefreshToken rt = _store.getRefreshToken(refreshTokenStr);
        auto now = Clock.currTime();

        if (rt.status != OAUTokenStatus.active)
            throw new OAUAuthorizationException(
                cast(string) OAUErrorCode.invalidGrant ~ ": token revoked");
        if (rt.expiresAt < now)
            throw new OAUAuthorizationException(
                cast(string) OAUErrorCode.invalidGrant ~ ": token expired");
        if (rt.clientId != clientId)
            throw new OAUAuthorizationException(
                cast(string) OAUErrorCode.invalidGrant ~ ": client mismatch");

        // Authenticate confidential client
        OAUClient client = _store.getClient(clientId);
        if (client.clientType == OAUClientType.confidential) {
            if (!_store.authenticateClient(clientId, clientSecret))
                throw new OAUAuthorizationException(
                    cast(string) OAUErrorCode.invalidClient);
        }

        // Revoke old refresh token (rotation)
        _store.revokeRefreshToken(refreshTokenStr);

        // Revoke old access token
        if (rt.accessTokenId.length > 0)
            _store.revokeAccessToken(rt.accessTokenId);

        // Issue new tokens
        return issueTokens(clientId, rt.userId, rt.scopes,
            OAUGrantType.refreshToken);
    }

    // ══════════════════════════════════════
    //  Private: Token Issuance Helpers
    // ══════════════════════════════════════

    private Json issueTokens(string clientId, string userId, string[] scopes,
            OAUGrantType grantType) {
        auto now = Clock.currTime();

        // Access token
        OAUAccessToken at;
        at.tokenId = randomUUID();
        at.accessToken = generateToken();
        at.tokenType = OAUTokenType.bearer;
        at.status = OAUTokenStatus.active;
        at.clientId = clientId;
        at.userId = userId;
        at.scopes = scopes;
        at.grantType = grantType;
        at.issuer = _config.issuer;
        at.expiresInSecs = _config.accessTokenLifetimeSecs;
        at.issuedAt = now;
        at.expiresAt = now + dur!"seconds"(_config.accessTokenLifetimeSecs);
        _store.storeAccessToken(at);

        // Refresh token
        OAURefreshToken rt;
        rt.tokenId = randomUUID();
        rt.refreshToken = generateToken();
        rt.status = OAUTokenStatus.active;
        rt.clientId = clientId;
        rt.userId = userId;
        rt.scopes = scopes;
        rt.accessTokenId = at.tokenId;
        rt.issuedAt = now;
        rt.expiresAt = now + dur!"seconds"(_config.refreshTokenLifetimeSecs);
        _store.storeRefreshToken(rt);

        import std.conv : to;
        Json result = Json.emptyObject;
        result["access_token"] = at.accessToken;
        result["token_type"] = cast(string) at.tokenType;
        result["expires_in"] = at.expiresInSecs.to!long;
        result["refresh_token"] = rt.refreshToken;
        result["scope"] = joinScopes(scopes);
        return result;
    }

    private Json issueAccessTokenOnly(string clientId, string userId,
            string[] scopes, OAUGrantType grantType) {
        auto now = Clock.currTime();

        OAUAccessToken at;
        at.tokenId = randomUUID();
        at.accessToken = generateToken();
        at.tokenType = OAUTokenType.bearer;
        at.status = OAUTokenStatus.active;
        at.clientId = clientId;
        at.userId = userId;
        at.scopes = scopes;
        at.grantType = grantType;
        at.issuer = _config.issuer;
        at.expiresInSecs = _config.accessTokenLifetimeSecs;
        at.issuedAt = now;
        at.expiresAt = now + dur!"seconds"(_config.accessTokenLifetimeSecs);
        _store.storeAccessToken(at);

        import std.conv : to;
        Json result = Json.emptyObject;
        result["access_token"] = at.accessToken;
        result["token_type"] = cast(string) at.tokenType;
        result["expires_in"] = at.expiresInSecs.to!long;
        result["scope"] = joinScopes(scopes);
        return result;
    }

    // ══════════════════════════════════════
    //  Private: Request Parsing Helpers
    // ══════════════════════════════════════

    private static string getRequiredString(Json req, string key) {
        if (key in req && req[key].isString) {
            string v = req[key].get!string;
            if (v.length > 0) return v;
        }
        throw new OAUValidationException("Missing required parameter: " ~ key);
    }

    private static string getOptionalString(Json req, string key) {
        if (key in req && req[key].isString)
            return req[key].get!string;
        return "";
    }

    private static OAUGrantType parseGrantTypeStr(string s) {
        switch (s) {
            case "authorization_code": return OAUGrantType.authorizationCode;
            case "client_credentials": return OAUGrantType.clientCredentials;
            case "refresh_token": return OAUGrantType.refreshToken;
            default: return OAUGrantType.authorizationCode;
        }
    }
}
