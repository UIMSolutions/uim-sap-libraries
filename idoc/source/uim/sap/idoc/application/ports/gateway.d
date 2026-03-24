module uim.sap.idoc.application.ports.gateway;

import uim.sap.idoc.domain;

interface IIDocGateway {
    IDocGatewayResult dispatch(IDocDispatchPlan plan, IDocUseCaseInput input);
}
