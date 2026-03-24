module uim.sap.idoc.config;

import uim.sap.idoc.exceptions;

struct IDocConfig {
    string defaultPort = "SAPDEFAULT";
    bool dryRunGateway = true;
    uint maxRetryAttempts = 5;
    bool autoResendOnConnectivityRecovery = true;

    void validate() const {
        if (defaultPort.length == 0) {
            throw new IDocConfigurationException("Default IDoc port must not be empty");
        }

        if (maxRetryAttempts == 0) {
            throw new IDocConfigurationException("maxRetryAttempts must be greater than zero");
        }
    }
}
