module uim.sap.oau.enumerations;

import uim.sap.oau;

mixin(ShowModule!());

@safe:

/// OAuth 2.0 grant types
enum OAUGrantType : string {
    authorizationCode = "authorization_code",
    clientCredentials = "client_credentials",
    refreshToken = "refresh_token",
}

/// OAuth 2.0 response types
enum OAUResponseType : string {
    code = "code",
}

/// OAuth 2.0 token types
enum OAUTokenType : string {
    bearer = "Bearer",
}

/// OAuth 2.0 client types (RFC 6749 Section 2.1)
enum OAUClientType : string {
    confidential = "confidential",
    public_ = "public",
}

/// OAuth 2.0 client status
enum OAUClientStatus : string {
    active = "active",
    suspended = "suspended",
    revoked = "revoked",
}

/// OAuth 2.0 token status
enum OAUTokenStatus : string {
    active = "active",
    expired = "expired",
    revoked = "revoked",
}

/// OAuth 2.0 authorization code status
enum OAUAuthCodeStatus : string {
    pending = "pending",
    used = "used",
    expired = "expired",
    revoked = "revoked",
}

/// OAuth 2.0 error codes (RFC 6749 Section 4.1.2.1 / 5.2)
enum OAUErrorCode : string {
    invalidRequest = "invalid_request",
    unauthorizedClient = "unauthorized_client",
    accessDenied = "access_denied",
    unsupportedResponseType = "unsupported_response_type",
    invalidScope = "invalid_scope",
    serverError = "server_error",
    temporarilyUnavailable = "temporarily_unavailable",
    invalidClient = "invalid_client",
    invalidGrant = "invalid_grant",
    unsupportedGrantType = "unsupported_grant_type",
}
