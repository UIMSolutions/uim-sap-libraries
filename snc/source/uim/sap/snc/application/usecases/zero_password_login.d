module uim.sap.snc.application.usecases.zero_password_login;

import uim.sap.snc.domain;
import uim.sap.snc.application.ports;
import uim.sap.snc.application.usecases.base;

class ZeroPasswordLoginUseCase : SNCSecurityUseCase {
    this(ISNCCredentialProvider credentialProvider) {
        super(credentialProvider);
    }

    override string name() const {
        return "Zero-Password Login";
    }

    override SNCProtectionLevel minimumProtectionLevel() const {
        return SNCProtectionLevel.IntegrityProtection;
    }

    override SNCAuthenticationMethod[] authenticationChain() const {
        return [SNCAuthenticationMethod.Kerberos, SNCAuthenticationMethod.X509Certificate];
    }

    override string[] notes(SNCUseCaseInput input) const {
        return [
            "Supports workstation single sign-on for principal: " ~ input.initiator.principal,
            "Ideal for AD/Kerberos or enterprise PKI-backed SAP landscapes"
        ];
    }
}
