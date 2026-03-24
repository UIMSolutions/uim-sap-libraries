/// High-level SAP OData service API.
///
/// Provides CRUD operations, function imports, batch requests,
/// metadata access, and server-driven paging — all through a
/// clean, typed interface on top of the HTTP client layer.
module sap.odata.service;

import std.json;
import std.conv : to;
import std.string : strip, indexOf;
import std.typecons : Nullable, nullable;
import std.exception : enforce;

import sap.odata.types;
import sap.odata.client;
import sap.odata.query;
import sap.odata.parser;
import sap.odata.errors;
import sap.odata.metadata;
import sap.odata.auth;
import sap.odata.batch;

/// Main entry point for interacting with a SAP OData service.
class SAPODataService
{
    private
    {
        SAPHttpClient _client;
        IAuthStrategy _auth;
        ODataVersion _version;
        Nullable!ServiceMetadata _metadata;
    }

    /// Create a new service instance.
    this(SAPConnectionParams params, IAuthStrategy auth = null, ODataVersion ver = ODataVersion.v2)
    {
        _client = new SAPHttpClient(params);
        _version = ver;
        _client.setODataVersion(ver);

        if (auth !is null)
        {
            _auth = auth;
            _auth.authenticate(_client);
        }
    }

    /// Access the underlying HTTP client for advanced use.
    SAPHttpClient httpClient() { return _client; }

    /// Connection parameters.
    const(SAPConnectionParams) params() const { return _client.params; }

    // ──────────────────────────────────────────────
    //  Metadata
    // ──────────────────────────────────────────────

    /// Fetch and parse the $metadata document.
    ServiceMetadata fetchMetadata()
    {
        _client.setCustomHeader("Accept", "application/xml");
        scope(exit) _client.setCustomHeader("Accept", "application/json");

        auto resp = _client.request(HttpMethod.GET, "$metadata");
        throwOnError(resp);

        _metadata = parseMetadata(resp.body).nullable;
        return _metadata.get;
    }

    /// Get cached metadata (fetches if not yet loaded).
    ServiceMetadata getMetadata()
    {
        if (_metadata.isNull)
            return fetchMetadata();
        return _metadata.get;
    }

    // ──────────────────────────────────────────────
    //  READ operations
    // ──────────────────────────────────────────────

    /// Execute a query and return a result set.
    ODataResultSet query(ODataQuery q)
    {
        auto path = q.build();
        auto resp = _client.request(HttpMethod.GET, path);
        throwOnError(resp);

        if (_version == ODataVersion.v4)
            return parseResultSetV4(resp.body, q.getEntitySet());
        return parseResultSet(resp.body, q.getEntitySet());
    }

    /// Read a collection of entities from an entity set.
    ODataResultSet list(
        string entitySet,
        string[] selectFields = null,
        string filterExpr = "",
        long top = -1,
        long skip = -1,
    )
    {
        auto q = ODataQuery.entitySet(entitySet);
        if (selectFields !is null && selectFields.length > 0)
            q = q.select(selectFields);
        if (filterExpr.length > 0)
            q = q.filter(filterExpr);
        if (top >= 0)
            q = q.top(top);
        if (skip >= 0)
            q = q.skip(skip);
        return query(q);
    }

    /// Read a single entity by key.
    ODataEntity read(string entitySet, string key)
    {
        auto q = ODataQuery.entitySet(entitySet).key(key);
        auto path = q.build();
        auto resp = _client.request(HttpMethod.GET, path);
        throwOnError(resp);

        if (_version == ODataVersion.v4)
            return parseEntityV4(parseJSON(resp.body), entitySet);
        return parseSingleEntity(resp.body, entitySet);
    }

    /// Read a single entity by composite key.
    ODataEntity readByKeys(string entitySet, string[string] keys)
    {
        auto q = ODataQuery.entitySet(entitySet).keys(keys);
        return read(entitySet, q.build()[entitySet.length .. $]);
    }

    /// Get entity count.
    long count(string entitySet, string filterExpr = "")
    {
        auto q = ODataQuery.entitySet(entitySet);
        if (filterExpr.length > 0)
            q = q.filter(filterExpr);
        auto path = q.buildCount();
        auto resp = _client.request(HttpMethod.GET, path);
        throwOnError(resp);
        return parseCount(resp.body.strip);
    }

    /// Fetch all pages of a query result.
    ODataEntity[] queryAll(ODataQuery q)
    {
        ODataEntity[] all;
        auto rs = query(q);
        all ~= rs.entities;

        while (rs.hasMore)
        {
            auto resp = _client.request(HttpMethod.GET, rs.nextLink);
            throwOnError(resp);
            rs = (_version == ODataVersion.v4)
                ? parseResultSetV4(resp.body, q.getEntitySet())
                : parseResultSet(resp.body, q.getEntitySet());
            all ~= rs.entities;
        }

        return all;
    }

    // ──────────────────────────────────────────────
    //  WRITE operations
    // ──────────────────────────────────────────────

    /// Create a new entity (POST).
    ODataEntity create(string entitySet, JSONValue payload)
    {
        auto resp = _client.request(HttpMethod.POST, entitySet, &payload);
        throwOnError(resp);

        if (resp.statusCode == 201 && resp.body.length > 0)
        {
            if (_version == ODataVersion.v4)
                return parseEntityV4(parseJSON(resp.body), entitySet);
            return parseSingleEntity(resp.body, entitySet);
        }

        return ODataEntity.init;
    }

    /// Create an entity from an ODataEntity struct.
    ODataEntity create(string entitySet, ref const ODataEntity entity)
    {
        auto payload = entity.toJson();
        return create(entitySet, payload);
    }

    /// Update an entity (PUT — full replacement).
    void update(string entitySet, string key, JSONValue payload)
    {
        auto path = entitySet ~ "(" ~ key ~ ")";
        auto resp = _client.request(HttpMethod.PUT, path, &payload);
        throwOnError(resp);
    }

    /// Partial update (MERGE for OData v2, PATCH for v4).
    void patch(string entitySet, string key, JSONValue payload)
    {
        auto path = entitySet ~ "(" ~ key ~ ")";
        auto method = (_version == ODataVersion.v2) ? HttpMethod.MERGE : HttpMethod.PATCH;
        auto resp = _client.request(method, path, &payload);
        throwOnError(resp);
    }

    /// Delete an entity.
    void remove(string entitySet, string key)
    {
        auto path = entitySet ~ "(" ~ key ~ ")";
        auto resp = _client.request(HttpMethod.DELETE, path);
        throwOnError(resp);
    }

    // ──────────────────────────────────────────────
    //  Function Imports
    // ──────────────────────────────────────────────

    /// Call a function import (GET-based).
    ODataResultSet callFunction(string functionName, string[string] params = null)
    {
        auto path = functionName;
        if (params.length > 0)
        {
            import std.array : appender, join;
            import std.uri : encodeComponent;

            auto qp = appender!(string[]);
            foreach (k, v; params)
                qp.put(k ~ "=" ~ encodeComponent(v));
            path ~= "?" ~ qp.data.join("&");
        }

        auto resp = _client.request(HttpMethod.GET, path);
        throwOnError(resp);

        if (resp.body.length > 0)
        {
            if (_version == ODataVersion.v4)
                return parseResultSetV4(resp.body);
            return parseResultSet(resp.body);
        }

        return ODataResultSet.init;
    }

    /// Call a function import (POST-based).
    ODataResultSet callAction(string actionName, JSONValue payload = JSONValue.init)
    {
        auto payloadPtr = (payload.type != JSONType.null_) ? &payload : null;
        auto resp = _client.request(HttpMethod.POST, actionName, payloadPtr);
        throwOnError(resp);

        if (resp.body.length > 0)
        {
            if (_version == ODataVersion.v4)
                return parseResultSetV4(resp.body);
            return parseResultSet(resp.body);
        }

        return ODataResultSet.init;
    }

    // ──────────────────────────────────────────────
    //  Batch requests
    // ──────────────────────────────────────────────

    /// Execute a batch request.
    BatchPartResponse[] executeBatch(ref BatchRequest batchReq)
    {
        auto batchBody = buildBatchBody(batchReq, _client.params.serviceUrl);

        _client.setCustomHeader("Content-Type",
            "multipart/mixed; boundary=" ~ batchBody.boundary);
        scope(exit) _client.setCustomHeader("Content-Type", "application/json");

        auto payload = JSONValue(batchBody.content);
        auto resp = _client.request(HttpMethod.POST, "$batch", &payload);

        // Extract boundary from response Content-Type.
        string respBoundary;
        if (auto ct = "content-type" in resp.headers)
        {
            auto bIdx = (*ct).indexOf("boundary=");
            if (bIdx >= 0)
                respBoundary = (*ct)[bIdx + 9 .. $].strip;
        }

        if (respBoundary.length > 0)
            return parseBatchResponse(resp.body, respBoundary);

        return [];
    }

    // ──────────────────────────────────────────────
    //  Navigation properties
    // ──────────────────────────────────────────────

    /// Read a navigation property of an entity.
    ODataResultSet readNavigationProperty(
        string entitySet,
        string key,
        string navProperty,
    )
    {
        auto path = entitySet ~ "(" ~ key ~ ")/" ~ navProperty;
        auto resp = _client.request(HttpMethod.GET, path);
        throwOnError(resp);

        if (_version == ODataVersion.v4)
            return parseResultSetV4(resp.body, navProperty);
        return parseResultSet(resp.body, navProperty);
    }

    /// Create a linked entity via a navigation property (deep insert).
    ODataEntity createViaNavigation(
        string entitySet,
        string key,
        string navProperty,
        JSONValue payload,
    )
    {
        auto path = entitySet ~ "(" ~ key ~ ")/" ~ navProperty;
        auto resp = _client.request(HttpMethod.POST, path, &payload);
        throwOnError(resp);

        if (resp.statusCode == 201 && resp.body.length > 0)
        {
            if (_version == ODataVersion.v4)
                return parseEntityV4(parseJSON(resp.body), navProperty);
            return parseSingleEntity(resp.body, navProperty);
        }

        return ODataEntity.init;
    }

    // ──────────────────────────────────────────────
    //  Error handling
    // ──────────────────────────────────────────────

    private void throwOnError(ref const HttpResponse resp)
    {
        if (resp.statusCode >= 200 && resp.statusCode < 300)
            return;

        auto err = parseODataError(resp.body);
        throw new ODataException(err, resp.statusCode);
    }
}

// ──────────────────────────────────────────────
//  Convenience factory functions
// ──────────────────────────────────────────────

/// Create a service with Basic authentication.
SAPODataService createSAPService(
    string baseUrl,
    string servicePath,
    string username,
    string password,
    string sapClient = "",
    string sapLanguage = "EN",
    ODataVersion ver = ODataVersion.v2,
)
{
    SAPConnectionParams params;
    params.baseUrl = baseUrl;
    params.servicePath = servicePath;
    params.sapClient = sapClient;
    params.sapLanguage = sapLanguage;

    auto auth = new BasicAuthStrategy(username, password);
    return new SAPODataService(params, auth, ver);
}
