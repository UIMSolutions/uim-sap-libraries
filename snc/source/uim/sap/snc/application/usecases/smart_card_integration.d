module uim.sap.snc.application.usecases.smart_card_integration;

import uim.sap.snc.domain;
import uim.sap.snc.application.ports;
import uim.sap.snc.application.usecases.base;

class SmartCardIntegrationUseCase : SNCSecurityUseCase {
    this(ISNCCredentialProvider credentialProvider) {
        super(credentialProvider);
    }

    override string name() const {
        return "Smart Card Integration";
    }

    override SNCProtectionLevel minimumProtectionLevel() const {
        return SNCProtectionLevel.PrivacyProtection;
    }

    override SNCAuthenticationMethod[] authenticationChain() const {
        return [SNCAuthenticationMethod.SmartCardWithPin, SNCAuthenticationMethod.X509Certificate];
    }

    override string[] notes(SNCUseCaseInput input) const {
        return [
            "MFA flow with hardware token and PIN for: " ~ input.initiator.principal,
            "Recommended for privileged access and regulated workloads"
        ];
    }
}
