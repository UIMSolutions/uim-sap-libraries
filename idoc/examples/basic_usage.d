module idoc.examples.basic_usage;

/**
 * Basic usage example for IDOC library
 */
import uim.sap.idoc;
import vibe.data.json : Json;
import std.stdio : writeln;

void main() {
    auto cfg = SAPIDocConfig.createBasic(
        "https://my.sap.system",
        "SAPUSER",
        "SAPPASSWORD",
        "100"
    );

    cfg.endpointPath = "/sap/idoc";

    auto client = new SAPIDocClient(cfg);

    Json segments = Json.emptyArray;

    Json segment = Json.emptyObject;
    segment["segmentName"] = Json("E1EDK01");
    segment["fields"] = Json.emptyObject;
    segment["fields"]["BELNR"] = Json("4500001234");
    segment["fields"]["BSART"] = Json("NB");
    segments ~= segment;

    try {
        auto submitResult = client.submit("ORDERS05", "ORDERS", segments, "DPORT", "RPORT");
        writeln("IDOC submitted: ", submitResult.documentNumber);

        auto statusResult = client.getStatus(submitResult.documentNumber);
        writeln("IDOC status: ", statusResult.status);
    } catch (SAPIDocException e) {
        writeln("IDOC operation failed: ", e.msg);
    }
}
