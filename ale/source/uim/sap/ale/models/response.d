module uim.sap.ale.models.response;

import uim.sap.ale.domain;

struct ALEUseCaseResult {
    string useCaseName;
    bool success;
    string transferId;
    ALEDeliveryState state;
    ALEMessageType messageType;
    string[] notes;
    string message;
}
