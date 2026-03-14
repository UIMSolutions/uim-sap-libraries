module uim.sap.rfc.models.request;

struct RFCRequest {
    string functionName;
    Json parameters = Json.emptyObject;
    string destination;

    Json toJson() const {
        Json payload = Json.emptyObject;
        payload["function"] = Json(functionName);
        payload["parameters"] = parameters;

        if (destination.length > 0) {
            payload["destination"] = Json(destination);
        }

        return payload;
    }
}