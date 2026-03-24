module uim.sap.snc.client;

import uim.sap.snc.config;
import uim.sap.snc.domain;
import uim.sap.snc.models;
import uim.sap.snc.application.service;
import uim.sap.snc.application.usecases;
import uim.sap.snc.infrastructure;

class SNCClient {
    private SNCConfig _config;
    private SNCUseCaseService _service;

    this(SNCConfig config = SNCConfig.init) {
        config.validate();
        _config = config;

        auto credentialProvider = new InMemoryCredentialProvider();
        auto gateway = new VibeSNCSecureChannelGateway(config.dryRunGateway);

        _service = new SNCUseCaseService(gateway, credentialProvider, _config.minimumProtectionLevel);
    }

    SNCUseCaseResult zeroPasswordLogin(SNCUseCaseInput input) {
        return _service.execute(new ZeroPasswordLoginUseCase(_service.credentialProvider), input);
    }

    SNCUseCaseResult smartCardIntegration(SNCUseCaseInput input) {
        return _service.execute(new SmartCardIntegrationUseCase(_service.credentialProvider), input);
    }

    SNCUseCaseResult systemToSystemCommunication(SNCUseCaseInput input) {
        return _service.execute(new SystemToSystemCommunicationUseCase(_service.credentialProvider), input);
    }

    SNCUseCaseResult thirdPartyIntegration(SNCUseCaseInput input) {
        return _service.execute(new ThirdPartyIntegrationUseCase(_service.credentialProvider), input);
    }

    SNCUseCaseResult cloudToOnPremiseConnectivity(SNCUseCaseInput input) {
        return _service.execute(new CloudToOnPremiseConnectivityUseCase(_service.credentialProvider), input);
    }

    SNCUseCaseResult secureSapGuiConnection(SNCUseCaseInput input) {
        return _service.execute(new SecureSapGuiConnectionsUseCase(_service.credentialProvider), input);
    }

    SNCUseCaseResult securePrinting(SNCUseCaseInput input) {
        return _service.execute(new SecurePrintingUseCase(_service.credentialProvider), input);
    }

    SNCUseCaseResult encryptionOnly(SNCUseCaseInput input) {
        return _service.execute(new EncryptionOnlyUseCase(_service.credentialProvider), input);
    }
}

unittest {
    SNCConfig cfg;
    cfg.dryRunGateway = true;
    cfg.minimumProtectionLevel = SNCProtectionLevel.IntegrityProtection;

    auto client = new SNCClient(cfg);

    SNCUseCaseInput input;
    input.initiator.principal = "user@example.org";
    input.target.principal = "p:CN=SAP/PRD@EXAMPLE.ORG";
    input.target.endpoint = "https://sap.example.org";
    input.requestedProtectionLevel = SNCProtectionLevel.AuthenticationOnly;

    auto result = client.encryptionOnly(input);

    assert(result.success);
    assert(result.useCaseName == "Encryption Only");
    assert(result.effectiveProtectionLevel == SNCProtectionLevel.PrivacyProtection);
}
