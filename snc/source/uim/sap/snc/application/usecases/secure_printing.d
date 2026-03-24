module uim.sap.snc.application.usecases.secure_printing;

import uim.sap.snc.domain;
import uim.sap.snc.application.ports;
import uim.sap.snc.application.usecases.base;

class SecurePrintingUseCase : SNCSecurityUseCase {
    this(ISNCCredentialProvider credentialProvider) {
        super(credentialProvider);
    }

    override string name() const {
        return "Secure Printing";
    }

    override SNCProtectionLevel minimumProtectionLevel() const {
        return SNCProtectionLevel.PrivacyProtection;
    }

    override SNCAuthenticationMethod[] authenticationChain() const {
        return [SNCAuthenticationMethod.TechnicalCertificate, SNCAuthenticationMethod.ServicePrincipal];
    }

    override string[] notes(SNCUseCaseInput input) const {
        return [
            "Encrypts SAP spool stream for confidential print payloads",
            "Target print endpoint: " ~ input.target.endpoint
        ];
    }
}
