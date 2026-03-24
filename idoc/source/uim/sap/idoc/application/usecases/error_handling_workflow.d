module uim.sap.idoc.application.usecases.error_handling_workflow;

import uim.sap.idoc.domain;
import uim.sap.idoc.application.usecases.base;

class ErrorHandlingWorkflowUseCase : IDocUseCase {
    override string name() const {
        return "Error Handling and Workflow";
    }

    override IDocProcessingMode mode() const {
        return IDocProcessingMode.ErrorHandlingWorkflow;
    }

    override bool requireWorkflowOnError() const {
        return true;
    }

    override bool enableAutoResend() const {
        return true;
    }

    override string[] notes(IDocUseCaseInput input) const {
        return [
            "Supports business validation failures and targeted user notification",
            "Aligns with WE02/WE05 operational monitoring and reprocessing patterns",
            "Allows correction and reprocessing without sender-side resubmission"
        ];
    }
}
