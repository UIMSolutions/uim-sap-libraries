/// OData batch request support for SAP.
///
/// SAP OData v2 batch requests use multipart/mixed content type.
/// A batch request can contain multiple GET retrievals and
/// change sets (groups of CUD operations that are atomic).
module sap.odata.batch;

import std.array : appender, join;
import std.conv : to;
import std.json;
import std.string : indexOf, strip, startsWith, splitLines;
import std.uuid : randomUUID;
import std.algorithm : findSplitAfter;

import sap.odata.types;
import sap.odata.parser;

/// Build a multipart batch request body.
/// Returns tuple of (boundary, body).
struct BatchBody
{
    string boundary;
    string content;
}

/// Build an OData batch request body from a BatchRequest.
BatchBody buildBatchBody(ref const BatchRequest batch, string serviceUrl)
{
    string batchBoundary = "batch_" ~ randomUUID().toString();
    auto body = appender!string;

    // GET retrievals.
    foreach (ref retrieval; batch.retrievals)
    {
        body.put("--");
        body.put(batchBoundary);
        body.put("\r\n");
        body.put("Content-Type: application/http\r\n");
        body.put("Content-Transfer-Encoding: binary\r\n");
        body.put("\r\n");
        body.put("GET ");
        body.put(retrieval.path);
        body.put(" HTTP/1.1\r\n");
        body.put("Accept: application/json\r\n");
        body.put("\r\n");
    }

    // Change sets.
    foreach (ref changeSet; batch.changeSets)
    {
        string csBoundary = "changeset_" ~ randomUUID().toString();

        body.put("--");
        body.put(batchBoundary);
        body.put("\r\n");
        body.put("Content-Type: multipart/mixed; boundary=");
        body.put(csBoundary);
        body.put("\r\n");
        body.put("\r\n");

        foreach (ref op; changeSet)
        {
            body.put("--");
            body.put(csBoundary);
            body.put("\r\n");
            body.put("Content-Type: application/http\r\n");
            body.put("Content-Transfer-Encoding: binary\r\n");
            if (op.contentId.length > 0)
            {
                body.put("Content-ID: ");
                body.put(op.contentId);
                body.put("\r\n");
            }
            body.put("\r\n");

            string methodStr;
            final switch (op.method)
            {
                case HttpMethod.GET:    methodStr = "GET"; break;
                case HttpMethod.POST:   methodStr = "POST"; break;
                case HttpMethod.PUT:    methodStr = "PUT"; break;
                case HttpMethod.PATCH:  methodStr = "PATCH"; break;
                case HttpMethod.DELETE: methodStr = "DELETE"; break;
                case HttpMethod.MERGE:  methodStr = "MERGE"; break;
            }

            body.put(methodStr);
            body.put(" ");
            body.put(op.path);
            body.put(" HTTP/1.1\r\n");
            body.put("Accept: application/json\r\n");
            body.put("Content-Type: application/json\r\n");

            if (op.payload.type != JSONType.null_)
            {
                auto payloadStr = op.payload.toString();
                body.put("Content-Length: ");
                body.put(payloadStr.length.to!string);
                body.put("\r\n");
                body.put("\r\n");
                body.put(payloadStr);
            }
            else
            {
                body.put("\r\n");
            }

            body.put("\r\n");
        }

        body.put("--");
        body.put(csBoundary);
        body.put("--\r\n");
    }

    body.put("--");
    body.put(batchBoundary);
    body.put("--\r\n");

    return BatchBody(batchBoundary, body.data);
}

/// Individual response from a batch part.
struct BatchPartResponse
{
    int statusCode;
    string body;
    string contentId;
}

/// Parse a multipart batch response.
BatchPartResponse[] parseBatchResponse(string responseBody, string boundary)
{
    BatchPartResponse[] results;

    if (responseBody.length == 0 || boundary.length == 0)
        return results;

    string delim = "--" ~ boundary;
    auto parts = splitByBoundary(responseBody, delim);

    foreach (part; parts)
    {
        auto trimmed = part.strip;
        if (trimmed.length == 0 || trimmed == "--")
            continue;

        // Check if this is a changeset (nested multipart).
        auto csIdx = trimmed.indexOf("multipart/mixed");
        if (csIdx >= 0)
        {
            // Extract changeset boundary.
            auto bIdx = trimmed.indexOf("boundary=", csIdx);
            if (bIdx >= 0)
            {
                auto rest = trimmed[bIdx + 9 .. $];
                auto nlIdx = rest.indexOf("\r\n");
                if (nlIdx < 0) nlIdx = rest.indexOf("\n");
                auto csBoundary = nlIdx > 0 ? rest[0 .. nlIdx].strip : rest.strip;
                auto innerParts = parseBatchResponse(trimmed, csBoundary);
                results ~= innerParts;
            }
            continue;
        }

        // Parse individual HTTP response.
        auto resp = parseHttpResponse(trimmed);
        if (resp.statusCode > 0)
            results ~= resp;
    }

    return results;
}

private string[] splitByBoundary(string text, string boundary)
{
    string[] parts;
    string remaining = text;

    while (remaining.length > 0)
    {
        auto idx = remaining.indexOf(boundary);
        if (idx < 0)
        {
            if (remaining.strip.length > 0)
                parts ~= remaining;
            break;
        }

        if (idx > 0)
            parts ~= remaining[0 .. idx];

        remaining = remaining[idx + boundary.length .. $];
    }

    return parts;
}

private BatchPartResponse parseHttpResponse(string part)
{
    BatchPartResponse resp;

    // Find the HTTP status line.
    auto httpIdx = part.indexOf("HTTP/1.1 ");
    if (httpIdx < 0)
        httpIdx = part.indexOf("HTTP/1.0 ");
    if (httpIdx < 0)
        return resp;

    auto statusStart = httpIdx + 9;
    auto lines = part[statusStart .. $].splitLines;
    if (lines.length == 0)
        return resp;

    // Parse status code.
    auto statusLine = lines[0].strip;
    if (statusLine.length >= 3)
    {
        try
            resp.statusCode = statusLine[0 .. 3].to!int;
        catch (Exception)
            return resp;
    }

    // Find Content-ID.
    auto cidIdx = part.indexOf("Content-ID:");
    if (cidIdx < 0)
        cidIdx = part.indexOf("Content-Id:");
    if (cidIdx >= 0)
    {
        auto cidRest = part[cidIdx + 11 .. $];
        auto nlIdx = cidRest.indexOf("\n");
        resp.contentId = nlIdx > 0 ? cidRest[0 .. nlIdx].strip : cidRest.strip;
    }

    // Find body (after double newline in the HTTP part).
    auto bodyStart = part.indexOf("\r\n\r\n", cast(ptrdiff_t) httpIdx);
    if (bodyStart < 0)
        bodyStart = part.indexOf("\n\n", cast(ptrdiff_t) httpIdx);
    if (bodyStart >= 0)
    {
        resp.body = part[bodyStart + (part[bodyStart .. bodyStart + 2] == "\r\n" ? 4 : 2) .. $].strip;
    }

    return resp;
}
