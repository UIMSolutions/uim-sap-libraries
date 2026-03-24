module uim.sap.edi.models.response;

import uim.sap.edi.domain;

struct EDIUseCaseResult {
    string useCaseName;
    bool success;
    string transferId;
    EDIFlowState state;
    EDIMessageType messageType;
    string[] checkpoints;
    string message;
}