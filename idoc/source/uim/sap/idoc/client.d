module uim.sap.idoc.client;

import uim.sap.idoc.config;
import uim.sap.idoc.domain;
import uim.sap.idoc.models;
import uim.sap.idoc.application.service;
import uim.sap.idoc.application.usecases;
import uim.sap.idoc.infrastructure;

class IDocClient {
    private IDocConfig _config;
    private IDocUseCaseService _service;

    this(IDocConfig config = IDocConfig.init) {
        config.validate();
        _config = config;

        auto gateway = new VibeIDocGateway(_config.dryRunGateway);
        auto notifier = new InMemoryIDocWorkflowNotifier();

        _service = new IDocUseCaseService(gateway, notifier, _config);
    }

    IDocUseCaseResult ediWithExternalPartners(IDocUseCaseInput input) {
        return _service.execute(new EDIExternalPartnersUseCase(), input);
    }

    IDocUseCaseResult aleInternalSystems(IDocUseCaseInput input) {
        return _service.execute(new ALEInternalSystemsUseCase(), input);
    }

    IDocUseCaseResult thirdPartyIntegration(IDocUseCaseInput input) {
        return _service.execute(new ThirdPartyIntegrationUseCase(), input);
    }

    IDocUseCaseResult asyncFireAndForget(IDocUseCaseInput input) {
        return _service.execute(new AsyncFireAndForgetUseCase(), input);
    }

    IDocUseCaseResult errorHandlingWorkflow(IDocUseCaseInput input) {
        return _service.execute(new ErrorHandlingWorkflowUseCase(), input);
    }
}

unittest {
    IDocConfig cfg;
    cfg.dryRunGateway = true;
    cfg.defaultPort = "A000000001";

    auto client = new IDocClient(cfg);

    IDocUseCaseInput input;
    input.sender.systemId = "ERP_PRD";
    input.receiver.systemId = "VENDOR";
    input.receiver.logicalAddress = "https://partner.example.org/idoc";
    input.messageType = IDocMessageType.ORDERS;
    input.basicType = "ORDERS05";

    auto result = client.ediWithExternalPartners(input);
    assert(result.success);
    assert(result.useCaseName == "EDI with External Partners");
}

unittest {
    IDocConfig cfg;
    cfg.dryRunGateway = false;
    cfg.autoResendOnConnectivityRecovery = true;

    auto client = new IDocClient(cfg);

    IDocUseCaseInput input;
    input.sender.systemId = "ERP_EU";
    input.receiver.systemId = "BW_CENTRAL";
    input.receiver.logicalAddress = "";
    input.messageType = IDocMessageType.ACC_DOCUMENT;
    input.basicType = "ACC_DOCUMENT03";

    auto result = client.asyncFireAndForget(input);
    assert(result.success);
    assert(result.deliveryState == IDocDeliveryState.WaitingForTarget);
}
