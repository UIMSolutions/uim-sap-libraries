module uim.sap.snc.application.usecases.secure_sap_gui_connections;

import uim.sap.snc.domain;
import uim.sap.snc.application.ports;
import uim.sap.snc.application.usecases.base;

class SecureSapGuiConnectionsUseCase : SNCSecurityUseCase {
    this(ISNCCredentialProvider credentialProvider) {
        super(credentialProvider);
    }

    override string name() const {
        return "Secure SAP GUI Connections";
    }

    override SNCProtectionLevel minimumProtectionLevel() const {
        return SNCProtectionLevel.PrivacyProtection;
    }

    override SNCAuthenticationMethod[] authenticationChain() const {
        return [SNCAuthenticationMethod.Kerberos, SNCAuthenticationMethod.X509Certificate];
    }

    override string[] notes(SNCUseCaseInput input) const {
        return [
            "Designed for admin sessions with sensitive system operations",
            "Enforces encrypted SAP GUI traffic to " ~ input.target.endpoint
        ];
    }
}
