module rfc.examples.basic_usage;

/**
 * Basic usage example for RFC adapter
 */
import uim.sap.rfc;
import vibe.data.json : Json;
import std.stdio : writeln;

void main() {
    auto cfg = RFCConfig.createBasic(
        "https://my.sap.system",
        "SAPUSER",
        "SAPPASSWORD",
        "100"
    );

    cfg.endpointPath = "/sap/bc/rfc";

    auto client = new RFCClient(cfg);

    if (!client.testConnection()) {
        writeln("Could not connect to RFC adapter endpoint");
        return;
    }

    Json params = Json.emptyObject;
    params["REQUTEXT"] = "Hello from uim-sap-rfc";

    try {
        auto result = client.invoke("STFC_CONNECTION", params);
        writeln("RFC call successful with status: ", result.statusCode);
        writeln("Response payload: ", result.data.toString());
    } catch (RFCException e) {
        writeln("RFC call failed: ", e.msg);
    }
}
