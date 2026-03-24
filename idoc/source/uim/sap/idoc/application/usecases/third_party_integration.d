module uim.sap.idoc.application.usecases.third_party_integration;

import uim.sap.idoc.domain;
import uim.sap.idoc.application.usecases.base;

class ThirdPartyIntegrationUseCase : IDocUseCase {
    override string name() const {
        return "Third-Party Non-SAP Integration";
    }

    override IDocProcessingMode mode() const {
        return IDocProcessingMode.ThirdPartyIntegration;
    }

    override bool requireWorkflowOnError() const {
        return true;
    }

    override bool enableAutoResend() const {
        return true;
    }

    override string[] notes(IDocUseCaseInput input) const {
        return [
            "Connects WMS, MES, 3PL and customs software to SAP core",
            "Useful for DELVRY, PRODORD and customs export declarations",
            "Stable asynchronous integration model for heterogeneous stacks"
        ];
    }
}
