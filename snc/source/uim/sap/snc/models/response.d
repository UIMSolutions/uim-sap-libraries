module uim.sap.snc.models.response;

import uim.sap.snc.domain;

struct SNCUseCaseResult {
    string useCaseName;
    bool success;
    string channelId;
    SNCProtectionLevel effectiveProtectionLevel;
    SNCAuthenticationMethod[] authenticationChain;
    string[] notes;
    string message;
}
