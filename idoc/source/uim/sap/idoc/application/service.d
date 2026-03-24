module uim.sap.idoc.application.service;

import uim.sap.idoc.config;
import uim.sap.idoc.domain;
import uim.sap.idoc.models;
import uim.sap.idoc.application.ports;
import uim.sap.idoc.application.usecases.base;

class IDocUseCaseService {
    private IIDocGateway _gateway;
    private IIDocWorkflowNotifier _workflowNotifier;
    private IDocConfig _config;

    this(IIDocGateway gateway, IIDocWorkflowNotifier workflowNotifier, IDocConfig config) {
        _gateway = gateway;
        _workflowNotifier = workflowNotifier;
        _config = config;
    }

    IDocUseCaseResult execute(IDocUseCase useCase, IDocUseCaseInput input) {
        return useCase.execute(
            input,
            _gateway,
            _workflowNotifier,
            _config.defaultPort,
            _config.maxRetryAttempts
        );
    }
}
