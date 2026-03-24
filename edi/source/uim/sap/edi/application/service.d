module uim.sap.edi.application.service;

import uim.sap.edi.config;
import uim.sap.edi.domain;
import uim.sap.edi.models;
import uim.sap.edi.application.ports;
import uim.sap.edi.application.usecases.base;

class EDIUseCaseService {
    private IEDIGateway _gateway;
    private IEDIMonitoringPort _monitor;
    private EDIConfig _config;

    this(IEDIGateway gateway, IEDIMonitoringPort monitor, EDIConfig config) {
        _gateway = gateway;
        _monitor = monitor;
        _config = config;
    }

    EDIUseCaseResult execute(EDIUseCase useCase, EDIUseCaseInput input) {
        return useCase.execute(
            input,
            _gateway,
            _monitor,
            _config.defaultSenderLogicalSystem,
            _config.maxRetries,
            _config.bufferWhenReceiverOffline,
            _config.strictValidation
        );
    }
}