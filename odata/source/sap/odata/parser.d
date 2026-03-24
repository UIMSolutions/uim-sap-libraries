/// JSON response parser for SAP OData v2 and v4 responses.
///
/// Handles the "d" envelope used in OData v2, __metadata,
/// __deferred navigation properties, __next paging, and __count.
module sap.odata.parser;

import std.json;
import std.conv : to;
import std.string : startsWith, indexOf;
import std.typecons : Nullable, nullable;

import sap.odata.types;

/// Parse a single entity from JSON (OData v2 format).
ODataEntity parseEntity(JSONValue json, string entitySet = "")
{
    ODataEntity entity;
    entity.entitySet = entitySet;

    if (json.type != JSONType.object)
        return entity;

    auto obj = json.objectNoRef;

    // Extract __metadata.
    if (auto meta = "__metadata" in obj)
    {
        if (auto uri = "uri" in *meta)
            entity.metadataUri = uri.str;
        if (auto etype = "type" in *meta)
            entity.entityType = etype.str;
        if (auto et = "etag" in *meta)
            entity.etag = et.str;
    }

    // Parse properties and navigation properties.
    foreach (key, value; obj)
    {
        if (key == "__metadata")
            continue;

        if (value.type == JSONType.object)
        {
            // Check if it's a deferred navigation property.
            if (auto deferred = "__deferred" in value)
            {
                // Skip deferred links; they're just URI references.
                continue;
            }

            // Check if it's an inline-expanded single nav property.
            if ("__metadata" in value || "results" in value)
            {
                if (auto results = "results" in value)
                {
                    // Collection navigation property.
                    ODataEntity[] navEntities;
                    foreach (item; results.array)
                        navEntities ~= parseEntity(item);
                    entity.navigationProperties[key] = navEntities;
                }
                else
                {
                    // Single navigation property.
                    entity.navigationProperties[key] = [parseEntity(value)];
                }
                continue;
            }

            // Regular complex property.
            entity.properties[key] = ODataValue(value);
        }
        else
        {
            entity.properties[key] = ODataValue(value);
        }
    }

    return entity;
}

/// Parse an entity collection from JSON (OData v2 format).
/// Expected structure: { "d": { "results": [...], "__count": "N", "__next": "..." } }
ODataResultSet parseResultSet(string responseBody, string entitySet = "")
{
    ODataResultSet rs;

    if (responseBody.length == 0)
        return rs;

    auto json = parseJSON(responseBody);
    JSONValue data;

    // OData v2: unwrap "d" envelope.
    if (auto d = "d" in json)
        data = *d;
    else
        data = json;

    // Check if it's a collection or single entity.
    if (auto results = "results" in data)
    {
        // Collection.
        foreach (item; results.array)
            rs.entities ~= parseEntity(item, entitySet);

        // Inline count.
        if (auto count = "__count" in data)
        {
            try
                rs.inlineCount = nullable(count.str.to!long);
            catch (Exception)
            {
                if (count.type == JSONType.integer)
                    rs.inlineCount = nullable(count.integer);
            }
        }

        // Next link for paging.
        if (auto next = "__next" in data)
            rs.nextLink = next.str;
    }
    else
    {
        // Single entity (wrapped in "d").
        rs.entities ~= parseEntity(data, entitySet);
    }

    return rs;
}

/// Parse a single-entity response from JSON.
ODataEntity parseSingleEntity(string responseBody, string entitySet = "")
{
    if (responseBody.length == 0)
        return ODataEntity.init;

    auto json = parseJSON(responseBody);

    // OData v2: unwrap "d" envelope.
    if (auto d = "d" in json)
        return parseEntity(*d, entitySet);

    return parseEntity(json, entitySet);
}

/// Parse an OData v4 response.
ODataResultSet parseResultSetV4(string responseBody, string entitySet = "")
{
    ODataResultSet rs;

    if (responseBody.length == 0)
        return rs;

    auto json = parseJSON(responseBody);

    // OData v4: collection in "value" array.
    if (auto value = "value" in json)
    {
        foreach (item; value.array)
            rs.entities ~= parseEntityV4(item, entitySet);

        // @odata.count
        if (auto count = "@odata.count" in json)
        {
            if (count.type == JSONType.integer)
                rs.inlineCount = nullable(count.integer);
        }

        // @odata.nextLink
        if (auto next = "@odata.nextLink" in json)
            rs.nextLink = next.str;
    }
    else
    {
        // Single entity.
        rs.entities ~= parseEntityV4(json, entitySet);
    }

    return rs;
}

/// Parse a single entity in OData v4 format.
ODataEntity parseEntityV4(JSONValue json, string entitySet = "")
{
    ODataEntity entity;
    entity.entitySet = entitySet;

    if (json.type != JSONType.object)
        return entity;

    foreach (key, value; json.objectNoRef)
    {
        // Skip OData annotations.
        if (key.startsWith("@odata.") || key.startsWith("@"))
        {
            if (key == "@odata.type")
                entity.entityType = value.str;
            else if (key == "@odata.etag")
                entity.etag = value.str;
            continue;
        }

        if (value.type == JSONType.array)
        {
            // Navigation property collection.
            ODataEntity[] navEntities;
            foreach (item; value.array)
            {
                if (item.type == JSONType.object)
                    navEntities ~= parseEntityV4(item);
            }
            if (navEntities.length > 0)
                entity.navigationProperties[key] = navEntities;
            else
                entity.properties[key] = ODataValue(value);
        }
        else if (value.type == JSONType.object)
        {
            // Could be a complex type or single nav property.
            entity.properties[key] = ODataValue(value);
        }
        else
        {
            entity.properties[key] = ODataValue(value);
        }
    }

    return entity;
}

/// Extract the count value from a $count response.
long parseCount(string responseBody)
{
    return responseBody.to!long;
}
