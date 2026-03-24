module uim.sap.ale.application.service;

import uim.sap.ale.config;
import uim.sap.ale.domain;
import uim.sap.ale.models;
import uim.sap.ale.application.ports;
import uim.sap.ale.application.usecases.base;

class ALEUseCaseService {
    private IALEGateway _gateway;
    private IALEMonitoringPort _monitor;
    private ALEConfig _config;

    this(IALEGateway gateway, IALEMonitoringPort monitor, ALEConfig config) {
        _gateway = gateway;
        _monitor = monitor;
        _config = config;
    }

    ALEUseCaseResult execute(ALEUseCase useCase, ALEUseCaseInput input) {
        return useCase.execute(
            input,
            _gateway,
            _monitor,
            _config.defaultLogicalSystem,
            _config.maxBufferRetries,
            _config.bufferWhenTargetOffline
        );
    }
}
