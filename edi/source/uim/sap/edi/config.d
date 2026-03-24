module uim.sap.edi.config;

import uim.sap.edi.exceptions;

struct EDIConfig {
    string defaultSenderLogicalSystem = "SAP_DEFAULT";
    bool dryRunGateway = true;
    bool bufferWhenReceiverOffline = true;
    bool strictValidation = true;
    uint maxRetries = 5;

    void validate() const {
        if (defaultSenderLogicalSystem.length == 0) {
            throw new EDIConfigurationException("defaultSenderLogicalSystem must not be empty");
        }

        if (maxRetries == 0) {
            throw new EDIConfigurationException("maxRetries must be greater than zero");
        }
    }
}