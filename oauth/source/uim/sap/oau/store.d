module uim.sap.oau.store;

import core.sync.mutex : Mutex;

import vibe.data.json : Json;

import uim.sap.oau.enumerations;
import uim.sap.oau.helpers;
import uim.sap.oau.models;

/**
 * Thread-safe in-memory store for OAuth 2.0 data.
 *
 * Manages: clients, access tokens, refresh tokens,
 * authorization codes, and scopes.
 */
class OAUStore : SAPStore {
    private {
        OAUClient[string] _clients;              // key: clientId
        OAUAccessToken[string] _accessTokens;     // key: accessToken value
        OAURefreshToken[string] _refreshTokens;   // key: refreshToken value
        OAUAuthorizationCode[string] _authCodes;  // key: code value
        OAUScope[string] _scopes;                 // key: scopeId
        Mutex _mutex;
    }

    this() {
        _mutex = new Mutex;
    }

    // ──────────────────────────────────────
    //  Clients
    // ──────────────────────────────────────

    OAUClient upsertClient(OAUClient c) {
        synchronized (_mutex) {
            _clients[c.clientId] = c;
            return c;
        }
    }

    OAUClient getClient(string clientId) {
        synchronized (_mutex) {
            if (auto p = clientId in _clients)
                return *p;
            return OAUClient.init;
        }
    }

    bool hasClient(string clientId) {
        synchronized (_mutex) {
            return (clientId in _clients) !is null;
        }
    }

    OAUClient[] listClients() {
        synchronized (_mutex) {
            return _clients.values;
        }
    }

    bool removeClient(string clientId) {
        synchronized (_mutex) {
            if (clientId in _clients) {
                _clients.remove(clientId);
                return true;
            }
            return false;
        }
    }

    size_t clientCount() {
        synchronized (_mutex) {
            return _clients.length;
        }
    }

    /// Authenticate a client by client_id and client_secret
    bool authenticateClient(string clientId, string clientSecret) {
        synchronized (_mutex) {
            if (auto p = clientId in _clients) {
                return p.clientSecret == clientSecret
                    && p.status == OAUClientStatus.active;
            }
            return false;
        }
    }

    // ──────────────────────────────────────
    //  Access Tokens
    // ──────────────────────────────────────

    OAUAccessToken storeAccessToken(OAUAccessToken tok) {
        synchronized (_mutex) {
            _accessTokens[tok.accessToken] = tok;
            return tok;
        }
    }

    OAUAccessToken getAccessToken(string token) {
        synchronized (_mutex) {
            if (auto p = token in _accessTokens)
                return *p;
            return OAUAccessToken.init;
        }
    }

    bool hasAccessToken(string token) {
        synchronized (_mutex) {
            return (token in _accessTokens) !is null;
        }
    }

    bool revokeAccessToken(string token) {
        synchronized (_mutex) {
            if (auto p = token in _accessTokens) {
                p.status = OAUTokenStatus.revoked;
                return true;
            }
            return false;
        }
    }

    /// Revoke all access tokens for a client
    size_t revokeAccessTokensByClient(string clientId) {
        synchronized (_mutex) {
            size_t count = 0;
            foreach (ref tok; _accessTokens) {
                if (tok.clientId == clientId && tok.status == OAUTokenStatus.active) {
                    tok.status = OAUTokenStatus.revoked;
                    count++;
                }
            }
            return count;
        }
    }

    // ──────────────────────────────────────
    //  Refresh Tokens
    // ──────────────────────────────────────

    OAURefreshToken storeRefreshToken(OAURefreshToken tok) {
        synchronized (_mutex) {
            _refreshTokens[tok.refreshToken] = tok;
            return tok;
        }
    }

    OAURefreshToken getRefreshToken(string token) {
        synchronized (_mutex) {
            if (auto p = token in _refreshTokens)
                return *p;
            return OAURefreshToken.init;
        }
    }

    bool hasRefreshToken(string token) {
        synchronized (_mutex) {
            return (token in _refreshTokens) !is null;
        }
    }

    bool revokeRefreshToken(string token) {
        synchronized (_mutex) {
            if (auto p = token in _refreshTokens) {
                p.status = OAUTokenStatus.revoked;
                return true;
            }
            return false;
        }
    }

    /// Revoke all refresh tokens for a client
    size_t revokeRefreshTokensByClient(string clientId) {
        synchronized (_mutex) {
            size_t count = 0;
            foreach (ref tok; _refreshTokens) {
                if (tok.clientId == clientId && tok.status == OAUTokenStatus.active) {
                    tok.status = OAUTokenStatus.revoked;
                    count++;
                }
            }
            return count;
        }
    }

    // ──────────────────────────────────────
    //  Authorization Codes
    // ──────────────────────────────────────

    OAUAuthorizationCode storeAuthCode(OAUAuthorizationCode code) {
        synchronized (_mutex) {
            _authCodes[code.code] = code;
            return code;
        }
    }

    OAUAuthorizationCode getAuthCode(string code) {
        synchronized (_mutex) {
            if (auto p = code in _authCodes)
                return *p;
            return OAUAuthorizationCode.init;
        }
    }

    bool hasAuthCode(string code) {
        synchronized (_mutex) {
            return (code in _authCodes) !is null;
        }
    }

    bool markAuthCodeUsed(string code) {
        synchronized (_mutex) {
            if (auto p = code in _authCodes) {
                p.status = OAUAuthCodeStatus.used;
                return true;
            }
            return false;
        }
    }

    bool revokeAuthCode(string code) {
        synchronized (_mutex) {
            if (auto p = code in _authCodes) {
                p.status = OAUAuthCodeStatus.revoked;
                return true;
            }
            return false;
        }
    }

    // ──────────────────────────────────────
    //  Scopes
    // ──────────────────────────────────────

    OAUScope upsertScope(OAUScope s) {
        synchronized (_mutex) {
            _scopes[s.scopeId] = s;
            return s;
        }
    }

    OAUScope getScope(string scopeId) {
        synchronized (_mutex) {
            if (auto p = scopeId in _scopes)
                return *p;
            return OAUScope.init;
        }
    }

    OAUScope getScopeByName(string name) {
        synchronized (_mutex) {
            foreach (ref s; _scopes) {
                if (s.name == name) return s;
            }
            return OAUScope.init;
        }
    }

    bool hasScope(string scopeId) {
        synchronized (_mutex) {
            return (scopeId in _scopes) !is null;
        }
    }

    OAUScope[] listScopes() {
        synchronized (_mutex) {
            return _scopes.values;
        }
    }

    bool removeScope(string scopeId) {
        synchronized (_mutex) {
            if (scopeId in _scopes) {
                _scopes.remove(scopeId);
                return true;
            }
            return false;
        }
    }

    /// Return default scopes
    string[] defaultScopeNames() {
        synchronized (_mutex) {
            string[] result;
            foreach (ref s; _scopes) {
                if (s.isDefault) result ~= s.name;
            }
            return result;
        }
    }
}
