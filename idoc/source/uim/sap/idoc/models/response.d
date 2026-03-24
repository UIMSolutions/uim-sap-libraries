module uim.sap.idoc.models.response;

import uim.sap.idoc.domain;

struct IDocUseCaseResult {
    string useCaseName;
    bool success;
    string idocNumber;
    IDocDeliveryState deliveryState;
    IDocMessageType messageType;
    string[] notes;
    string message;
}
