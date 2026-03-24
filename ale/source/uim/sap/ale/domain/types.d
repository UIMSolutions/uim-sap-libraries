module uim.sap.ale.domain.types;

enum ALEMessageType {
    MATMAS,
    DEBMAS,
    CREMAS,
    ORDERS,
    DELVRY,
    ACC_DOCUMENT,
    HR_MINI_MASTER,
    WMS_DELIVERY_REQUEST,
    CUSTOM
}

enum ALEProcessMode {
    MasterDataDistribution,
    DistributedBusinessProcess,
    CentralFinanceReporting,
    HRMiniMasterDistribution,
    DecouplingHighAvailability
}

enum ALEDeliveryState {
    Planned,
    Distributed,
    Buffered,
    Failed,
    Confirmed
}

struct ALESystemNode {
    string systemId;
    string logicalAddress;
}

struct ALEUseCaseInput {
    ALESystemNode source;
    ALESystemNode target;
    ALEMessageType messageType = ALEMessageType.CUSTOM;
    string objectType = "";
    string correlationId = "";
    string payloadJson = "{}";
    string[string] metadata;
}

struct ALEDistributionPlan {
    string useCaseName;
    ALEProcessMode mode;
    ALEMessageType messageType;
    string objectType;
    string senderLogicalSystem;
    bool asynchronous = true;
    bool allowBuffering = true;
    bool requireAcknowledgement = true;
    uint maxRetries = 3;
    string[] notes;
}

struct ALEGatewayResult {
    bool success;
    string transferId;
    ALEDeliveryState state;
    string message;
}
