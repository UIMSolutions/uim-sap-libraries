module uim.sap.snc.application.usecases.system_to_system_communication;

import uim.sap.snc.domain;
import uim.sap.snc.application.ports;
import uim.sap.snc.application.usecases.base;

class SystemToSystemCommunicationUseCase : SNCSecurityUseCase {
    this(ISNCCredentialProvider credentialProvider) {
        super(credentialProvider);
    }

    override string name() const {
        return "System-to-System Communication";
    }

    override SNCProtectionLevel minimumProtectionLevel() const {
        return SNCProtectionLevel.PrivacyProtection;
    }

    override SNCAuthenticationMethod[] authenticationChain() const {
        return [SNCAuthenticationMethod.ServicePrincipal, SNCAuthenticationMethod.TechnicalCertificate];
    }

    override string[] notes(SNCUseCaseInput input) const {
        return [
            "Secures trusted channels between SAP backends",
            "Designed for RFC/batch data transfers from " ~ input.initiator.principal ~ " to " ~ input.target.principal
        ];
    }
}
