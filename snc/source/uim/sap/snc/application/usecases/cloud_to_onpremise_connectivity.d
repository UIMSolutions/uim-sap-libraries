module uim.sap.snc.application.usecases.cloud_to_onpremise_connectivity;

import uim.sap.snc.domain;
import uim.sap.snc.application.ports;
import uim.sap.snc.application.usecases.base;

class CloudToOnPremiseConnectivityUseCase : SNCSecurityUseCase {
    this(ISNCCredentialProvider credentialProvider) {
        super(credentialProvider);
    }

    override string name() const {
        return "Cloud-to-On-Premise Connectivity";
    }

    override SNCProtectionLevel minimumProtectionLevel() const {
        return SNCProtectionLevel.PrivacyProtection;
    }

    override SNCAuthenticationMethod[] authenticationChain() const {
        return [SNCAuthenticationMethod.TechnicalCertificate, SNCAuthenticationMethod.ServicePrincipal];
    }

    override string[] notes(SNCUseCaseInput input) const {
        return [
            "Protects cloud-to-private connectivity line of sight",
            "Use with private link or VPN tunnel to endpoint: " ~ input.target.endpoint
        ];
    }
}
