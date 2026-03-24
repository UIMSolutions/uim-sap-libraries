module uim.sap.ale.client;

import uim.sap.ale.config;
import uim.sap.ale.domain;
import uim.sap.ale.models;
import uim.sap.ale.application.service;
import uim.sap.ale.application.usecases;
import uim.sap.ale.infrastructure;

class ALEClient {
    private ALEConfig _config;
    private ALEUseCaseService _service;

    this(ALEConfig config = ALEConfig.init) {
        config.validate();
        _config = config;

        auto gateway = new VibeALEGateway(_config.dryRunGateway);
        auto monitor = new ConsoleALEMonitoringPort();
        _service = new ALEUseCaseService(gateway, monitor, _config);
    }

    ALEUseCaseResult masterDataDistribution(ALEUseCaseInput input) {
        return _service.execute(new MasterDataDistributionUseCase(), input);
    }

    ALEUseCaseResult distributedBusinessProcesses(ALEUseCaseInput input) {
        return _service.execute(new DistributedBusinessProcessesUseCase(), input);
    }

    ALEUseCaseResult centralFinanceReporting(ALEUseCaseInput input) {
        return _service.execute(new CentralFinanceReportingUseCase(), input);
    }

    ALEUseCaseResult hrMiniMasterDistribution(ALEUseCaseInput input) {
        return _service.execute(new HRMiniMasterDistributionUseCase(), input);
    }

    ALEUseCaseResult decouplingHighAvailability(ALEUseCaseInput input) {
        return _service.execute(new DecouplingHighAvailabilityUseCase(), input);
    }
}

unittest {
    ALEConfig cfg;
    cfg.dryRunGateway = true;

    auto client = new ALEClient(cfg);

    ALEUseCaseInput input;
    input.source.systemId = "MDM_CORE";
    input.target.systemId = "ERP_REGION_01";
    input.target.logicalAddress = "sap://erp-region-01";
    input.messageType = ALEMessageType.MATMAS;
    input.objectType = "MATERIAL";

    auto result = client.masterDataDistribution(input);
    assert(result.success);
    assert(result.useCaseName == "Master Data Distribution");
}

unittest {
    ALEConfig cfg;
    cfg.dryRunGateway = false;
    cfg.bufferWhenTargetOffline = true;

    auto client = new ALEClient(cfg);

    ALEUseCaseInput input;
    input.source.systemId = "ERP_CENTRAL";
    input.target.systemId = "WMS_LOCAL";
    input.target.logicalAddress = "";
    input.messageType = ALEMessageType.WMS_DELIVERY_REQUEST;
    input.objectType = "DELIVERY_REQUEST";

    auto result = client.decouplingHighAvailability(input);
    assert(result.success);
    assert(result.state == ALEDeliveryState.Buffered);
}
