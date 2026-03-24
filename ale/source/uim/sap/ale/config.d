module uim.sap.ale.config;

import uim.sap.ale.exceptions;

struct ALEConfig {
    string defaultLogicalSystem = "SAP_DEFAULT";
    bool dryRunGateway = true;
    bool bufferWhenTargetOffline = true;
    uint maxBufferRetries = 10;

    void validate() const {
        if (defaultLogicalSystem.length == 0) {
            throw new ALEConfigurationException("defaultLogicalSystem must not be empty");
        }

        if (maxBufferRetries == 0) {
            throw new ALEConfigurationException("maxBufferRetries must be greater than zero");
        }
    }
}
