module uim.sap.snc.application.service;

import uim.sap.snc.domain;
import uim.sap.snc.models;
import uim.sap.snc.application.ports;
import uim.sap.snc.application.usecases.base;

class SNCUseCaseService {
    private ISNCSecureChannelGateway _gateway;
    private ISNCCredentialProvider _credentialProvider;
    private SNCProtectionLevel _tenantMinimumLevel;

    this(
        ISNCSecureChannelGateway gateway,
        ISNCCredentialProvider credentialProvider,
        SNCProtectionLevel tenantMinimumLevel
    ) {
        _gateway = gateway;
        _credentialProvider = credentialProvider;
        _tenantMinimumLevel = tenantMinimumLevel;
    }

    @property ISNCCredentialProvider credentialProvider() {
        return _credentialProvider;
    }

    SNCUseCaseResult execute(SNCSecurityUseCase useCase, SNCUseCaseInput input) {
        return useCase.execute(input, _gateway, _tenantMinimumLevel);
    }
}
