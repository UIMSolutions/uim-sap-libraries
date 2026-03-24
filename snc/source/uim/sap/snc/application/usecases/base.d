module uim.sap.snc.application.usecases.base;

import std.conv : to;

import uim.sap.snc.domain;
import uim.sap.snc.models;
import uim.sap.snc.application.ports;

abstract class SNCSecurityUseCase {
    protected ISNCCredentialProvider _credentialProvider;

    this(ISNCCredentialProvider credentialProvider) {
        _credentialProvider = credentialProvider;
    }

    abstract string name() const;
    abstract SNCProtectionLevel minimumProtectionLevel() const;
    abstract SNCAuthenticationMethod[] authenticationChain() const;
    abstract string[] notes(SNCUseCaseInput input) const;

    SNCUseCaseResult execute(
        SNCUseCaseInput input,
        ISNCSecureChannelGateway gateway,
        SNCProtectionLevel tenantMinimumLevel
    ) {
        auto effectiveLevel = enforceMinimumProtectionLevel(
            enforceMinimumProtectionLevel(input.requestedProtectionLevel, minimumProtectionLevel()),
            tenantMinimumLevel
        );

        SNCConnectionPlan plan;
        plan.useCaseName = name();
        plan.effectiveProtectionLevel = effectiveLevel;
        plan.authenticationChain = authenticationChain().dup;
        plan.hasAuthentication = hasAuthentication(effectiveLevel);
        plan.hasIntegrityProtection = hasIntegrity(effectiveLevel);
        plan.hasPrivacyProtection = hasPrivacy(effectiveLevel);
        plan.targetEndpoint = input.target.endpoint;
        plan.operationalNotes = notes(input).dup;

        foreach (method; plan.authenticationChain) {
            if (_credentialProvider.canProvide(method)) {
                auto credential = _credentialProvider.issueCredential(method, input.initiator.principal);
                if (credential.length > 0) {
                    plan.operationalNotes ~= "Credential provisioned for " ~ method.to!string;
                }
            }
        }

        auto gatewayResult = gateway.openSecureChannel(plan);

        SNCUseCaseResult result;
        result.useCaseName = plan.useCaseName;
        result.success = gatewayResult.success;
        result.channelId = gatewayResult.channelId;
        result.effectiveProtectionLevel = effectiveLevel;
        result.authenticationChain = plan.authenticationChain.dup;
        result.notes = plan.operationalNotes.dup;
        result.message = gatewayResult.message;
        return result;
    }
}
