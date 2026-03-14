module uim.sap.idoc.models.submitrequest;

import uim.sap.idoc;
@safe:

struct IDocSubmitRequest {
    IDocControlRecord control;
    Json segments = Json.emptyArray;
    bool testRun;

    Json toJson() const {
        Json payload = Json.emptyObject;
        payload["control"] = control.toJson();
        payload["segments"] = segments;
        payload["testRun"] = Json(testRun);
        return payload;
    }
}