/// Example: Basic usage of the SAP OData library.
///
/// Demonstrates connecting to a SAP system, querying data,
/// creating entities, and using batch requests.
module odata.examples.basic_usage;

version (Example):

import std.stdio : writeln, writefln;
import std.json : JSONValue, parseJSON;
import sap.odata;

void main()
{
    // ── 1. Create a service connection ─────────────────
    auto svc = createSAPService(
        "https://my-sap-host:443",                       // base URL
        "/sap/opu/odata/sap/API_BUSINESS_PARTNER",       // service path
        "SAP_USER",                                       // username
        "SAP_PASS",                                       // password
        "100",                                            // sap-client
        "EN",                                             // sap-language
    );

    // ── 2. Fetch and inspect metadata ──────────────────
    auto meta = svc.fetchMetadata();
    writeln("Entity Sets:");
    foreach (ref es; meta.entitySets)
        writefln("  - %s (type: %s)", es.name, es.entityTypeName);

    // ── 3. Query with fluent API ───────────────────────
    auto q = ODataQuery.entitySet("A_BusinessPartner")
        .select("BusinessPartner", "BusinessPartnerFullName", "BusinessPartnerCategory")
        .filterEq("BusinessPartnerCategory", "1")
        .orderBy("BusinessPartnerFullName")
        .top(10)
        .withInlineCount();

    auto result = svc.query(q);
    writefln("\nBusiness Partners (total: %s):", result.inlineCount);
    foreach (ref entity; result.entities)
    {
        writefln("  %s - %s",
            entity["BusinessPartner"].str,
            entity["BusinessPartnerFullName"].str,
        );
    }

    // ── 4. Read a single entity ────────────────────────
    auto bp = svc.read("A_BusinessPartner", "'1000000'");
    writefln("\nSingle BP: %s", bp["BusinessPartnerFullName"].str);

    // ── 5. Read with composite key ─────────────────────
    auto addr = svc.readByKeys("A_BusinessPartnerAddress", [
        "BusinessPartner": "'1000000'",
        "AddressID": "'1'",
    ]);
    writefln("Address: %s", addr.get("CityName"));

    // ── 6. Navigate to related entities ────────────────
    auto addresses = svc.readNavigationProperty(
        "A_BusinessPartner", "'1000000'", "to_BusinessPartnerAddress"
    );
    writefln("\nAddresses for BP 1000000: %d found", addresses.entities.length);

    // ── 7. Create an entity ────────────────────────────
    auto newBP = JSONValue([
        "BusinessPartnerCategory": JSONValue("1"),
        "BusinessPartnerFullName": JSONValue("Test Partner"),
        "FirstName":               JSONValue("Test"),
        "LastName":                JSONValue("Partner"),
    ]);
    auto created = svc.create("A_BusinessPartner", newBP);
    writefln("\nCreated BP: %s", created["BusinessPartner"].str);

    // ── 8. Update (partial) ────────────────────────────
    auto updatePayload = JSONValue([
        "BusinessPartnerFullName": JSONValue("Updated Partner Name"),
    ]);
    svc.patch("A_BusinessPartner", "'1000000'", updatePayload);
    writeln("Patched successfully.");

    // ── 9. Delete ──────────────────────────────────────
    svc.remove("A_BusinessPartner", "'9999999'");
    writeln("Deleted successfully.");

    // ── 10. Function import ────────────────────────────
    auto fiResult = svc.callFunction("GetDefaultAddress", [
        "BusinessPartner": "'1000000'",
    ]);
    if (fiResult.entities.length > 0)
        writefln("Default address: %s", fiResult.entities[0].get("CityName"));

    // ── 11. Batch request ──────────────────────────────
    BatchRequest batch;
    batch.retrievals ~= BatchRequest.Retrieval("A_BusinessPartner('1000000')");
    batch.retrievals ~= BatchRequest.Retrieval("A_BusinessPartner('1000001')");
    batch.changeSets ~= [
        ChangeSetOperation(
            HttpMethod.POST,
            "A_BusinessPartner",
            JSONValue(["BusinessPartnerCategory": JSONValue("1"),
                "LastName": JSONValue("BatchCreated")]),
            "1",
        ),
    ];

    auto batchResults = svc.executeBatch(batch);
    writefln("\nBatch returned %d parts", batchResults.length);
    foreach (ref part; batchResults)
        writefln("  Status: %d", part.statusCode);

    // ── 12. Count entities ─────────────────────────────
    auto totalCount = svc.count("A_BusinessPartner",
        "BusinessPartnerCategory eq '1'");
    writefln("\nTotal person BPs: %d", totalCount);

    // ── 13. Fetch all pages ────────────────────────────
    auto allQ = ODataQuery.entitySet("A_BusinessPartner")
        .select("BusinessPartner")
        .filterEq("BusinessPartnerCategory", "2")
        .top(100);

    auto allEntities = svc.queryAll(allQ);
    writefln("Fetched all %d organization BPs", allEntities.length);
}
