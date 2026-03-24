module uim.sap.idoc.application.usecases.async_fire_and_forget;

import uim.sap.idoc.domain;
import uim.sap.idoc.application.usecases.base;

class AsyncFireAndForgetUseCase : IDocUseCase {
    override string name() const {
        return "Asynchronous Fire and Forget";
    }

    override IDocProcessingMode mode() const {
        return IDocProcessingMode.AsyncFireAndForget;
    }

    override bool requireWorkflowOnError() const {
        return false;
    }

    override bool enableAutoResend() const {
        return true;
    }

    override string[] notes(IDocUseCaseInput input) const {
        return [
            "Queues IDocs when targets are temporarily unavailable",
            "Resends automatically on connectivity recovery",
            "Protects business process continuity from transient outages"
        ];
    }
}
