module uim.sap.snc.application.usecases.encryption_only;

import uim.sap.snc.domain;
import uim.sap.snc.application.ports;
import uim.sap.snc.application.usecases.base;

class EncryptionOnlyUseCase : SNCSecurityUseCase {
    this(ISNCCredentialProvider credentialProvider) {
        super(credentialProvider);
    }

    override string name() const {
        return "Encryption Only";
    }

    override SNCProtectionLevel minimumProtectionLevel() const {
        return SNCProtectionLevel.PrivacyProtection;
    }

    override SNCAuthenticationMethod[] authenticationChain() const {
        return [SNCAuthenticationMethod.UsernamePassword];
    }

    override string[] notes(SNCUseCaseInput input) const {
        return [
            "Transport is encrypted while users still authenticate with SAP credentials",
            "Useful for external contractors/service providers"
        ];
    }
}
