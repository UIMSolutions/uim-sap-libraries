module uim.sap.ale.application.ports.gateway;

import uim.sap.ale.domain;

interface IALEGateway {
    ALEGatewayResult distribute(ALEDistributionPlan plan, ALEUseCaseInput input);
}
