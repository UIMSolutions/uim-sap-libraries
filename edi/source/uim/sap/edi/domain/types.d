module uim.sap.edi.domain.types;

enum EDIMessageStandard {
    EDIFACT,
    ANSI_X12,
    IDOC_XML,
    ISO20022,
    CUSTOM
}

enum EDIMessageType {
    ORDERS,
    ORDRSP,
    DESADV,
    INVOIC,
    ASN,
    OUTBOUND_INVOICE,
    IFTMIN,
    IFTSTA,
    INVENTORY_REPORT,
    PAYEXT,
    FINSTA,
    CUSTOM
}

enum EDIProcessMode {
    ProcureToPayPurchasing,
    OrderToCashSales,
    LogisticsTransport3PL,
    CashManagementBanking
}

enum EDIFlowState {
    Planned,
    Received,
    Validated,
    Transmitted,
    Buffered,
    Matched,
    Completed,
    Failed
}

struct EDIParty {
    string partnerId;
    string logicalAddress;
    string role;
}

struct EDIUseCaseInput {
    EDIParty sender;
    EDIParty receiver;
    EDIMessageStandard standard = EDIMessageStandard.EDIFACT;
    EDIMessageType messageType = EDIMessageType.CUSTOM;
    string sapTransactionCode = "";
    string documentNumber = "";
    string correlationId = "";
    string payloadJson = "{}";
    string[string] metadata;
}

struct EDIProcessingPlan {
    string useCaseName;
    EDIProcessMode mode;
    EDIMessageType messageType;
    EDIMessageStandard standard;
    string documentNumber;
    string senderLogicalSystem;
    bool allowBuffering = true;
    bool requireAcknowledgement = true;
    bool requireThreeWayMatch = false;
    uint maxRetries = 3;
    string[] checkpoints;
}

struct EDIGatewayResult {
    bool success;
    string transferId;
    EDIFlowState state;
    string message;
}