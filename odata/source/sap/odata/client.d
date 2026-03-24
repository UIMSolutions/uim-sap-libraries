/// Low-level HTTP client layer for SAP OData communication.
///
/// Handles CSRF token management, SAP-specific headers,
/// cookie persistence, and TLS configuration via vibe.d HTTP.
module sap.odata.client;

import std.algorithm : canFind;
import std.conv : to;
import std.json;
import std.string : strip, indexOf, toLower, startsWith;
import std.array : appender;
import std.exception : enforce;

import vibe.http.client;
import vibe.inet.url : URL;
import vibe.stream.operations : readAllUTF8;
import vibe.core.log;

import sap.odata.types;
import sap.odata.errors;

/// HTTP response wrapper.
struct HttpResponse
{
    int statusCode;
    string statusPhrase;
    string body;
    string[string] headers;
    string etag;
    string csrfToken;
    string[][string] cookies;
}

/// SAP HTTP client that manages sessions, CSRF tokens, and SAP-specific headers.
class SAPHttpClient
{
    private
    {
        SAPConnectionParams _params;
        string _csrfToken;
        string[][string] _cookies;
        string _username;
        string _password;
        bool _tlsValidation = true;
        ODataVersion _odataVersion = ODataVersion.v2;
        string[string] _customHeaders;
    }

    /// Construct a client for the given SAP connection.
    this(SAPConnectionParams params)
    {
        _params = params;
    }

    /// Set HTTP Basic authentication credentials.
    void setBasicAuth(string username, string password)
    {
        _username = username;
        _password = password;
    }

    /// Enable/disable TLS certificate validation.
    void setTlsValidation(bool enabled)
    {
        _tlsValidation = enabled;
    }

    /// Set OData version.
    void setODataVersion(ODataVersion ver)
    {
        _odataVersion = ver;
    }

    /// Add a custom header sent with every request.
    void setCustomHeader(string name, string value)
    {
        _customHeaders[name] = value;
    }

    /// Remove a custom header.
    void removeCustomHeader(string name)
    {
        _customHeaders.remove(name);
    }

    /// Current connection parameters.
    const(SAPConnectionParams) params() const { return _params; }

    /// Fetch a fresh CSRF token from the server.
    /// SAP requires X-CSRF-Token: Fetch on GET, returns the token in response.
    void fetchCsrfToken()
    {
        auto resp = request(HttpMethod.GET, "", null, true);
        if (resp.csrfToken.length > 0)
            _csrfToken = resp.csrfToken;
    }

    /// Perform an HTTP request.
    HttpResponse request(
        HttpMethod method,
        string path,
        JSONValue* payload = null,
        bool csrfFetch = false,
    )
    {
        string fullUrl = buildUrl(path);

        HttpResponse result;

        requestHTTP(fullUrl,
            (scope req)
            {
                // Set HTTP method.
                final switch (method)
                {
                    case HttpMethod.GET:    req.method = HTTPMethod.GET; break;
                    case HttpMethod.POST:   req.method = HTTPMethod.POST; break;
                    case HttpMethod.PUT:    req.method = HTTPMethod.PUT; break;
                    case HttpMethod.PATCH:  req.method = HTTPMethod.PATCH; break;
                    case HttpMethod.DELETE: req.method = HTTPMethod.DELETE; break;
                    case HttpMethod.MERGE:
                        req.method = HTTPMethod.POST;
                        req.headers["X-HTTP-Method-Override"] = "MERGE";
                        break;
                }

                // Basic auth.
                if (_username.length > 0)
                {
                    import std.base64 : Base64;
                    auto credentials = Base64.encode(
                        cast(const(ubyte)[])(_username ~ ":" ~ _password)
                    );
                    req.headers["Authorization"] = "Basic " ~ cast(string) credentials;
                }

                // SAP-specific parameters.
                if (_params.sapClient.length > 0)
                    req.headers["sap-client"] = _params.sapClient;
                if (_params.sapLanguage.length > 0)
                    req.headers["sap-language"] = _params.sapLanguage;

                // OData version headers.
                if (_odataVersion == ODataVersion.v2)
                {
                    req.headers["Accept"] = "application/json";
                    req.headers["Content-Type"] = "application/json";
                    req.headers["DataServiceVersion"] = "2.0";
                    req.headers["MaxDataServiceVersion"] = "2.0";
                }
                else
                {
                    req.headers["Accept"] = "application/json;odata.metadata=minimal";
                    req.headers["Content-Type"] = "application/json;odata.metadata=minimal";
                    req.headers["OData-Version"] = "4.0";
                    req.headers["OData-MaxVersion"] = "4.0";
                }

                // CSRF token handling.
                if (csrfFetch)
                {
                    req.headers["X-CSRF-Token"] = "Fetch";
                }
                else if (_csrfToken.length > 0 &&
                    method != HttpMethod.GET)
                {
                    req.headers["X-CSRF-Token"] = _csrfToken;
                }

                // Send cookies.
                applyCookies(req);

                // Custom headers.
                foreach (k, v; _customHeaders)
                    req.headers[k] = v;

                // Request body.
                if (payload !is null &&
                    method != HttpMethod.GET && method != HttpMethod.DELETE)
                {
                    auto bodyStr = (*payload).toString();
                    req.writeBody(cast(const(ubyte)[]) bodyStr);
                }
            },
            (scope res)
            {
                result.statusCode = res.statusCode;
                result.statusPhrase = getStatusPhrase(res.statusCode);

                // Read response body.
                result.body = res.bodyReader.readAllUTF8(false);

                // Capture headers via byKeyValue range.
                foreach (entry; res.headers.byKeyValue)
                {
                    auto k = entry[0].toLower;
                    auto v = cast(string) entry[1];
                    result.headers[k] = v;

                    if (k == "x-csrf-token")
                        result.csrfToken = v;
                    if (k == "etag")
                        result.etag = v;
                }

                // Capture set-cookie headers.
                foreach (entry; res.headers.byKeyValue)
                {
                    auto k = entry[0].toLower;
                    if (k == "set-cookie")
                    {
                        auto cookieStr = cast(string) entry[1];
                        auto eqIdx = cookieStr.indexOf('=');
                        if (eqIdx > 0)
                        {
                            auto name = cookieStr[0 .. eqIdx].strip;
                            auto rest = cookieStr[eqIdx + 1 .. $];
                            auto semiIdx = rest.indexOf(';');
                            auto val = semiIdx > 0 ? rest[0 .. semiIdx].strip : rest.strip;
                            _cookies[name] = [val];
                        }
                    }
                }
            }
        );

        // Update CSRF token if we got a new one.
        if (result.csrfToken.length > 0)
            _csrfToken = result.csrfToken;

        // Handle 403 with token expiry — retry once.
        if (result.statusCode == 403 && !csrfFetch)
        {
            logInfo("CSRF token expired, re-fetching...");
            fetchCsrfToken();
            return request(method, path, payload, false);
        }

        return result;
    }

    /// Build full URL from a relative path.
    private string buildUrl(string path)
    {
        string base = _params.serviceUrl();
        if (path.length == 0)
            return base;

        if (path.startsWith("http://") || path.startsWith("https://"))
            return path;

        if (base[$ - 1] != '/' && path[0] != '/')
            return base ~ "/" ~ path;
        if (base[$ - 1] == '/' && path[0] == '/')
            return base ~ path[1 .. $];
        return base ~ path;
    }

    /// Apply stored cookies to a request.
    private void applyCookies(scope HTTPClientRequest req)
    {
        auto buf = appender!string;
        bool first = true;
        foreach (name, values; _cookies)
        {
            foreach (v; values)
            {
                if (!first) buf.put("; ");
                buf.put(name);
                buf.put("=");
                buf.put(v);
                first = false;
            }
        }
        if (buf.data.length > 0)
            req.headers["Cookie"] = buf.data;
    }

    private string getStatusPhrase(int code)
    {
        switch (code)
        {
            case 200: return "OK";
            case 201: return "Created";
            case 204: return "No Content";
            case 400: return "Bad Request";
            case 401: return "Unauthorized";
            case 403: return "Forbidden";
            case 404: return "Not Found";
            case 405: return "Method Not Allowed";
            case 409: return "Conflict";
            case 500: return "Internal Server Error";
            default: return "HTTP " ~ code.to!string;
        }
    }
}
