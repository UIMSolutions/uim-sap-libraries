/// SAP OData types and data structures.
///
/// Defines the core value types, entity representations, and error
/// structures used throughout the SAP OData client library.
module sap.odata.types;

import std.datetime : SysTime;
import std.json;
import std.conv : to;
import std.typecons : Nullable, nullable;

/// A single OData property value — wraps possible JSON types.
struct ODataValue
{
    private JSONValue _inner;

    this(JSONValue v)
    {
        _inner = v;
    }

    /// Construct from common D types.
    this(string v) { _inner = JSONValue(v); }
    this(long v) { _inner = JSONValue(v); }
    this(double v) { _inner = JSONValue(v); }
    this(bool v) { _inner = JSONValue(v); }

    /// Null value.
    static ODataValue nil()
    {
        ODataValue v;
        v._inner = JSONValue(null);
        return v;
    }

    JSONValue json() const { return _inner; }

    bool isNull() const { return _inner.isNull; }

    string str() const { return _inner.str; }
    long integer() const { return _inner.integer; }
    double floating() const { return _inner.floating; }
    bool boolean() const
    {
        return _inner.type == JSONType.true_;
    }

    string toString() const
    {
        if (_inner.isNull) return "null";
        if (_inner.type == JSONType.string) return _inner.str;
        return _inner.toString();
    }
}

/// An OData entity — essentially a named property bag.
struct ODataEntity
{
    /// Entity set name (e.g. "BusinessPartnerSet").
    string entitySet;

    /// Key-value properties.
    ODataValue[string] properties;

    /// Navigation property links (deferred or inline expanded).
    ODataEntity[][string] navigationProperties;

    /// Metadata URI (__metadata.uri).
    string metadataUri;

    /// Entity type from __metadata.type.
    string entityType;

    /// Entity ETag for optimistic concurrency.
    string etag;

    /// Convenience accessors.
    ODataValue opIndex(string key) const
    {
        return properties[key];
    }

    void opIndexAssign(ODataValue val, string key)
    {
        properties[key] = val;
    }

    /// Check if a property exists.
    bool hasProperty(string key) const
    {
        return (key in properties) !is null;
    }

    /// Convert entity to a JSON payload for write operations.
    JSONValue toJson() const
    {
        JSONValue[string] obj;
        foreach (k, v; properties)
        {
            obj[k] = v.json;
        }
        return JSONValue(obj);
    }

    /// Get property as string, or a default.
    string get(string key, string defaultVal = "") const
    {
        if (auto p = key in properties)
            return p.isNull ? defaultVal : p.str;
        return defaultVal;
    }
}

/// Represents an OData result set (collection of entities).
struct ODataResultSet
{
    ODataEntity[] entities;

    /// Inline count ($inlinecount=allpages).
    Nullable!long inlineCount;

    /// __next link for server-driven paging.
    string nextLink;

    /// Whether there are more pages.
    bool hasMore() const { return nextLink.length > 0; }
}

/// OData error detail from SAP gateway.
struct ODataError
{
    string code;
    string message;
    string severity;       // "error", "warning", "info"
    string target;
    ODataErrorDetail[] details;
    string rawBody;        // full response body for debugging
}

struct ODataErrorDetail
{
    string code;
    string message;
    string severity;
    string target;
}

/// Exception thrown on OData errors.
class ODataException : Exception
{
    ODataError error;
    int statusCode;

    this(ODataError err, int status, string file = __FILE__, size_t line = __LINE__)
    {
        super(err.message, file, line);
        this.error = err;
        this.statusCode = status;
    }
}

/// SAP-specific connection parameters.
struct SAPConnectionParams
{
    /// Base URL of the SAP system (e.g. "https://sap-host:443").
    string baseUrl;

    /// SAP client number (sap-client parameter).
    string sapClient;

    /// SAP language key (sap-language parameter, e.g. "EN").
    string sapLanguage = "EN";

    /// OData service path (e.g. "/sap/opu/odata/sap/API_BUSINESS_PARTNER").
    string servicePath;

    /// Full service URL.
    string serviceUrl() const
    {
        string url = baseUrl;
        if (url.length > 0 && url[$ - 1] == '/')
            url = url[0 .. $ - 1];
        string path = servicePath;
        if (path.length > 0 && path[0] != '/')
            path = "/" ~ path;
        return url ~ path;
    }
}

/// Supported OData versions in SAP.
enum ODataVersion
{
    v2,
    v4,
}

/// HTTP method.
enum HttpMethod
{
    GET,
    POST,
    PUT,
    PATCH,
    DELETE,
    MERGE,  // SAP-specific for partial updates in OData v2
}

/// Batch changeset operation.
struct ChangeSetOperation
{
    HttpMethod method;
    string path;
    JSONValue payload;
    string contentId;
}

/// Batch request groups.
struct BatchRequest
{
    struct Retrieval
    {
        string path;
    }

    Retrieval[] retrievals;
    ChangeSetOperation[][] changeSets;
}
