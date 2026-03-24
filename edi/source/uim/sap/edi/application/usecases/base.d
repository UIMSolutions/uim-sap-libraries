module uim.sap.edi.application.usecases.base;

import std.conv : to;

import uim.sap.edi.domain;
import uim.sap.edi.models;
import uim.sap.edi.application.ports;

abstract class EDIUseCase {
    abstract string name() const;
    abstract EDIProcessMode mode() const;
    abstract bool allowBuffering() const;
    abstract bool requireAcknowledgement() const;
    abstract bool requireThreeWayMatch() const;
    abstract EDIMessageType[] supportedMessageTypes() const;
    abstract string[] checkpoints(EDIUseCaseInput input) const;

    final EDIUseCaseResult execute(
        EDIUseCaseInput input,
        IEDIGateway gateway,
        IEDIMonitoringPort monitor,
        string senderLogicalSystem,
        uint maxRetries,
        bool configBuffering,
        bool strictValidation
    ) {
        if (!isSupported(input.messageType)) {
            EDIUseCaseResult unsupported;
            unsupported.useCaseName = name();
            unsupported.success = false;
            unsupported.transferId = "";
            unsupported.state = EDIFlowState.Failed;
            unsupported.messageType = input.messageType;
            unsupported.checkpoints = ["Unsupported message type for use case"];
            unsupported.message = "Message type " ~ input.messageType.to!string ~ " is not supported by " ~ name();

            monitor.logState("", name(), unsupported.state.to!string, unsupported.message);
            return unsupported;
        }

        EDIProcessingPlan plan;
        plan.useCaseName = name();
        plan.mode = mode();
        plan.messageType = input.messageType;
        plan.standard = input.standard;
        plan.documentNumber = input.documentNumber;
        plan.senderLogicalSystem = senderLogicalSystem;
        plan.allowBuffering = allowBuffering() && configBuffering;
        plan.requireAcknowledgement = requireAcknowledgement();
        plan.requireThreeWayMatch = requireThreeWayMatch();
        plan.maxRetries = maxRetries;
        plan.checkpoints = checkpoints(input).dup;

        auto gatewayResult = gateway.process(plan, input);
        monitor.logState(
            gatewayResult.transferId,
            plan.useCaseName,
            gatewayResult.state.to!string,
            gatewayResult.message
        );

        EDIUseCaseResult result;
        result.useCaseName = plan.useCaseName;
        result.success = gatewayResult.success;
        result.transferId = gatewayResult.transferId;
        result.state = gatewayResult.state;
        result.messageType = input.messageType;
        result.checkpoints = plan.checkpoints.dup;
        result.message = gatewayResult.message;
        return result;
    }

    private bool isSupported(EDIMessageType messageType) const {
        foreach (allowed; supportedMessageTypes()) {
            if (allowed == messageType) {
                return true;
            }
        }
        return false;
    }
}