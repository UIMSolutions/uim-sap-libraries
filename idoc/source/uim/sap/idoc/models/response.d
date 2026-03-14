module uim.sap.idoc.models.response;

import uim.sap.idoc;
@safe:

struct IDocResponse {
    bool success;
    int statusCode;
    string documentNumber;
    string status;
    string errorMessage;
    Json data = Json.emptyObject;
    string[string] headers;
    SysTime timestamp;

    bool isSuccess() const pure nothrow @safe @nogc {
        return success;
    }
}
