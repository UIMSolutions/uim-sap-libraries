module uim.sap.edi.application.ports.gateway;

import uim.sap.edi.domain;

interface IEDIGateway {
    EDIGatewayResult process(EDIProcessingPlan plan, EDIUseCaseInput input);
}