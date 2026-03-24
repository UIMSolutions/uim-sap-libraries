module uim.sap.snc.config;

import uim.sap.snc.domain;
import uim.sap.snc.exceptions;

struct SNCConfig {
    SNCProtectionLevel minimumProtectionLevel = SNCProtectionLevel.PrivacyProtection;
    bool dryRunGateway = true;
    bool requireMutualAuthentication = true;

    void validate() const {
        if (!isValidProtectionLevel(minimumProtectionLevel)) {
            throw new SNCConfigurationException("Invalid minimum SNC protection level");
        }
    }
}
