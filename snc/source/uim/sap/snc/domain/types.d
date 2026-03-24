module uim.sap.snc.domain.types;

import uim.sap.snc.domain.protectionlevel;

enum SNCAuthenticationMethod {
    Kerberos,
    X509Certificate,
    SmartCardWithPin,
    UsernamePassword,
    ServicePrincipal,
    TechnicalCertificate
}

struct SNCParticipant {
    string principal;
    string endpoint;
}

struct SNCUseCaseInput {
    SNCParticipant initiator;
    SNCParticipant target;
    SNCProtectionLevel requestedProtectionLevel = SNCProtectionLevel.PrivacyProtection;
    string purpose;
}

struct SNCConnectionPlan {
    string useCaseName;
    SNCProtectionLevel effectiveProtectionLevel;
    SNCAuthenticationMethod[] authenticationChain;
    bool requiresMutualAuthentication = true;
    bool hasAuthentication;
    bool hasIntegrityProtection;
    bool hasPrivacyProtection;
    string targetEndpoint;
    string[] operationalNotes;
}

struct SNCGatewayResult {
    bool success;
    string channelId;
    string transport;
    string message;
}
