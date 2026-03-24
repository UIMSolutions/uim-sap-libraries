module uim.sap.idoc.domain.types;

enum IDocMessageType {
    ORDERS,
    INVOIC,
    DESADV,
    MATMAS,
    ACC_DOCUMENT,
    DELVRY,
    PRODORD,
    CUSDEC,
    CUSTOM
}

enum IDocProcessingMode {
    EDIExternalPartners,
    ALEInternalSystems,
    ThirdPartyIntegration,
    AsyncFireAndForget,
    ErrorHandlingWorkflow
}

enum IDocDeliveryState {
    Ready,
    Dispatched,
    WaitingForTarget,
    Failed,
    Reprocessed,
    Completed
}

struct IDocSystemParty {
    string systemId;
    string logicalAddress;
}

struct IDocUseCaseInput {
    IDocSystemParty sender;
    IDocSystemParty receiver;
    IDocMessageType messageType = IDocMessageType.CUSTOM;
    string basicType = "";
    string correlationId = "";
    string[string] metadata;
    string payloadJson = "{}";
}

struct IDocDispatchPlan {
    string useCaseName;
    IDocProcessingMode mode;
    IDocMessageType messageType;
    string basicType;
    string port;
    bool asynchronous = true;
    bool requireWorkflowOnError = false;
    bool enableAutoResend = false;
    uint maxRetryAttempts;
    string[] notes;
}

struct IDocGatewayResult {
    bool success;
    string idocNumber;
    IDocDeliveryState state;
    string message;
}
