/// Authentication handlers for SAP OData services.
///
/// Supports Basic authentication and SAP-specific session handling.
module sap.odata.auth;

import sap.odata.client;
import sap.odata.types;

/// Authentication strategy interface.
interface IAuthStrategy
{
    /// Apply authentication to the client.
    void authenticate(SAPHttpClient client);

    /// Re-authenticate (e.g. refresh token).
    void reauthenticate(SAPHttpClient client);
}

/// HTTP Basic authentication strategy.
class BasicAuthStrategy : IAuthStrategy
{
    private string _username;
    private string _password;

    this(string username, string password)
    {
        _username = username;
        _password = password;
    }

    void authenticate(SAPHttpClient client)
    {
        client.setBasicAuth(_username, _password);
        client.fetchCsrfToken();
    }

    void reauthenticate(SAPHttpClient client)
    {
        client.fetchCsrfToken();
    }
}

/// API Key / Bearer token authentication strategy.
class BearerAuthStrategy : IAuthStrategy
{
    private string _token;

    this(string token)
    {
        _token = token;
    }

    void authenticate(SAPHttpClient client)
    {
        client.setCustomHeader("Authorization", "Bearer " ~ _token);
        client.fetchCsrfToken();
    }

    void reauthenticate(SAPHttpClient client)
    {
        client.fetchCsrfToken();
    }

    /// Update the token (e.g. after refresh).
    void updateToken(string newToken)
    {
        _token = newToken;
    }
}

/// SAP Client Certificate authentication (headers only, TLS configured externally).
class ClientCertAuthStrategy : IAuthStrategy
{
    void authenticate(SAPHttpClient client)
    {
        // TLS client certs are handled at the transport layer.
        // Just fetch the CSRF token.
        client.fetchCsrfToken();
    }

    void reauthenticate(SAPHttpClient client)
    {
        client.fetchCsrfToken();
    }
}
