module uim.sap.ale.application.usecases.base;

import std.conv : to;

import uim.sap.ale.domain;
import uim.sap.ale.models;
import uim.sap.ale.application.ports;

abstract class ALEUseCase {
    abstract string name() const;
    abstract ALEProcessMode mode() const;
    abstract bool allowBuffering() const;
    abstract bool requireAcknowledgement() const;
    abstract string[] notes(ALEUseCaseInput input) const;

    ALEUseCaseResult execute(
        ALEUseCaseInput input,
        IALEGateway gateway,
        IALEMonitoringPort monitor,
        string senderLogicalSystem,
        uint maxRetries,
        bool configBuffering
    ) {
        ALEDistributionPlan plan;
        plan.useCaseName = name();
        plan.mode = mode();
        plan.messageType = input.messageType;
        plan.objectType = input.objectType.length > 0 ? input.objectType : "GENERIC";
        plan.senderLogicalSystem = senderLogicalSystem;
        plan.allowBuffering = allowBuffering() && configBuffering;
        plan.requireAcknowledgement = requireAcknowledgement();
        plan.maxRetries = maxRetries;
        plan.notes = notes(input).dup;

        auto gatewayResult = gateway.distribute(plan, input);
        monitor.logState(
            gatewayResult.transferId,
            plan.useCaseName,
            gatewayResult.state.to!string,
            gatewayResult.message
        );

        ALEUseCaseResult result;
        result.useCaseName = plan.useCaseName;
        result.success = gatewayResult.success;
        result.transferId = gatewayResult.transferId;
        result.state = gatewayResult.state;
        result.messageType = input.messageType;
        result.notes = plan.notes.dup;
        result.message = gatewayResult.message;
        return result;
    }
}
