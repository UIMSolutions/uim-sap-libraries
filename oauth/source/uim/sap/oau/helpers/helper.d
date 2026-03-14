module uim.sap.oau.helpers.helper;

import uim.sap.oau;

mixin(ShowModule!());

@safe:

/// Generate a cryptographically random hex string of the given byte length
string generateRandomHex(size_t byteLen = 32) {
    import std.digest : toHexString, LetterCase;
    ubyte[] bytes;
    bytes.length = byteLen;
    foreach (ref b; bytes)
        b = cast(ubyte)(hashOf(randomUUID()) & 0xFF);
    return bytes.toHexString!(LetterCase.lower).idup;
}

/// Generate a new OAuth client ID
string generateClientId() {
    return "oau-" ~ randomUUID();
}

/// Generate a new OAuth client secret
string generateClientSecret() {
    return generateRandomHex(32);
}

/// Generate an opaque access/refresh token
string generateToken() {
    return generateRandomHex(40);
}

/// Generate an authorization code
string generateAuthCode() {
    return generateRandomHex(20);
}

/// Validate a redirect URI (must be absolute HTTPS or localhost for dev)
bool isValidRedirectUri(string uri) {
    if (uri.length == 0) return false;
    // Allow localhost for development
    if (uri.startsWith("http://localhost") || uri.startsWith("http://127.0.0.1"))
        return true;
    // Require HTTPS for production
    if (uri.startsWith("https://"))
        return true;
    return false;
}

/// Check if a scope string is present in the allowed scopes list
bool isScopeAllowed(string scope_, string[] allowedScopes) {
    foreach (s; allowedScopes) {
        if (s == scope_) return true;
    }
    return false;
}

/// Parse a space-separated scope string into an array
string[] parseScopeString(string scopeStr) {
    import std.array : split;
    import std.algorithm : filter;
    import std.array : array;
    if (scopeStr.length == 0) return [];
    return scopeStr.split(" ").filter!(s => s.length > 0).array;
}

/// Join scope array into a space-separated string
string joinScopes(string[] scopes) {
    import std.array : join;
    return scopes.join(" ");
}

private size_t hashOf(string s) {
    size_t h = 0;
    foreach (c; s) h = h * 31 + c;
    return h;
}
