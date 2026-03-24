module uim.sap.idoc.application.usecases.base;

import uim.sap.idoc.domain;
import uim.sap.idoc.models;
import uim.sap.idoc.application.ports;

abstract class IDocUseCase {
    abstract string name() const;
    abstract IDocProcessingMode mode() const;
    abstract bool requireWorkflowOnError() const;
    abstract bool enableAutoResend() const;
    abstract string[] notes(IDocUseCaseInput input) const;

    IDocUseCaseResult execute(
        IDocUseCaseInput input,
        IIDocGateway gateway,
        IIDocWorkflowNotifier notifier,
        string defaultPort,
        uint maxRetryAttempts
    ) {
        IDocDispatchPlan plan;
        plan.useCaseName = name();
        plan.mode = mode();
        plan.messageType = input.messageType;
        plan.basicType = input.basicType.length > 0 ? input.basicType : "CUSTOM01";
        plan.port = defaultPort;
        plan.asynchronous = true;
        plan.requireWorkflowOnError = requireWorkflowOnError();
        plan.enableAutoResend = enableAutoResend();
        plan.maxRetryAttempts = maxRetryAttempts;
        plan.notes = notes(input).dup;

        auto gatewayResult = gateway.dispatch(plan, input);

        if (!gatewayResult.success && plan.requireWorkflowOnError) {
            notifier.notifyFailure(gatewayResult.idocNumber, gatewayResult.message, input.receiver.systemId);
        }

        IDocUseCaseResult result;
        result.useCaseName = plan.useCaseName;
        result.success = gatewayResult.success;
        result.idocNumber = gatewayResult.idocNumber;
        result.deliveryState = gatewayResult.state;
        result.messageType = input.messageType;
        result.notes = plan.notes.dup;
        result.message = gatewayResult.message;
        return result;
    }
}
