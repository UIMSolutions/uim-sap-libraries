/// SAP OData error handling and response parsing for error cases.
module sap.odata.errors;

import std.json;
import sap.odata.types;

/// Parse an OData error response body (JSON) into an ODataError.
/// SAP OData v2 error format:
/// {
///   "error": {
///     "code": "...",
///     "message": { "lang": "en", "value": "..." },
///     "innererror": {
///       "errordetails": [
///         { "code": "...", "message": "...", "severity": "error", "target": "" }
///       ]
///     }
///   }
/// }
ODataError parseODataError(string responseBody)
{
    ODataError err;
    err.rawBody = responseBody;

    if (responseBody.length == 0)
    {
        err.message = "Empty error response";
        return err;
    }

    try
    {
        auto json = parseJSON(responseBody);
        if (auto errObj = "error" in json)
        {
            if (auto code = "code" in *errObj)
                err.code = code.str;

            if (auto msg = "message" in *errObj)
            {
                if (msg.type == JSONType.object)
                {
                    if (auto val = "value" in *msg)
                        err.message = val.str;
                }
                else if (msg.type == JSONType.string)
                {
                    err.message = msg.str;
                }
            }

            // Parse inner error details (SAP specific).
            if (auto inner = "innererror" in *errObj)
            {
                if (auto details = "errordetails" in *inner)
                {
                    foreach (detail; details.array)
                    {
                        ODataErrorDetail d;
                        if (auto c = "code" in detail) d.code = c.str;
                        if (auto m = "message" in detail) d.message = m.str;
                        if (auto s = "severity" in detail) d.severity = s.str;
                        if (auto t = "target" in detail) d.target = t.str;
                        err.details ~= d;
                    }
                }
            }
        }
    }
    catch (Exception)
    {
        // If JSON parsing fails, use the raw body as message.
        err.message = responseBody.length > 500 ? responseBody[0 .. 500] : responseBody;
    }

    if (err.message.length == 0)
        err.message = "Unknown OData error";

    err.severity = "error";
    return err;
}
