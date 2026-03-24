module uim.sap.idoc.application.usecases.ale_internal_systems;

import uim.sap.idoc.domain;
import uim.sap.idoc.application.usecases.base;

class ALEInternalSystemsUseCase : IDocUseCase {
    override string name() const {
        return "ALE Internal SAP Systems";
    }

    override IDocProcessingMode mode() const {
        return IDocProcessingMode.ALEInternalSystems;
    }

    override bool requireWorkflowOnError() const {
        return true;
    }

    override bool enableAutoResend() const {
        return true;
    }

    override string[] notes(IDocUseCaseInput input) const {
        return [
            "Synchronizes SAP landscapes using ALE distribution",
            "Covers master data distribution like MATMAS and central finance postings",
            "Supports hub-and-spoke SAP topology"
        ];
    }
}
