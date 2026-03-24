module uim.sap.snc.application.usecases.third_party_integration;

import uim.sap.snc.domain;
import uim.sap.snc.application.ports;
import uim.sap.snc.application.usecases.base;

class ThirdPartyIntegrationUseCase : SNCSecurityUseCase {
    this(ISNCCredentialProvider credentialProvider) {
        super(credentialProvider);
    }

    override string name() const {
        return "Third-Party Integration";
    }

    override SNCProtectionLevel minimumProtectionLevel() const {
        return SNCProtectionLevel.IntegrityProtection;
    }

    override SNCAuthenticationMethod[] authenticationChain() const {
        return [SNCAuthenticationMethod.ServicePrincipal, SNCAuthenticationMethod.X509Certificate];
    }

    override string[] notes(SNCUseCaseInput input) const {
        return [
            "Targets Java/Python/monitoring clients using RFC interfaces",
            "Apply least privilege scopes to principal: " ~ input.initiator.principal
        ];
    }
}
