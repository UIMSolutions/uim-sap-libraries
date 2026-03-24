module uim.sap.edi.infrastructure.vibe_gateway;

import std.conv : to;
import std.datetime : Clock;

import vibe.data.json : Json;

import uim.sap.edi.domain;
import uim.sap.edi.application.ports;

class VibeEDIGateway : IEDIGateway {
    private bool _dryRun;
    private bool _strictValidation;

    this(bool dryRun = true, bool strictValidation = true) {
        _dryRun = dryRun;
        _strictValidation = strictValidation;
    }

    override EDIGatewayResult process(EDIProcessingPlan plan, EDIUseCaseInput input) {
        EDIGatewayResult result;

        // Keep an envelope object for future extension with real HTTP adapters.
        Json envelope = Json.emptyObject;
        envelope["useCase"] = Json(plan.useCaseName);
        envelope["sender"] = Json(input.sender.partnerId);
        envelope["receiver"] = Json(input.receiver.partnerId);
        envelope["messageType"] = Json(input.messageType.to!string);
        envelope["documentNumber"] = Json(plan.documentNumber);
        envelope["buffering"] = Json(plan.allowBuffering);

        if (_strictValidation && (input.sender.partnerId.length == 0 || input.receiver.partnerId.length == 0)) {
            result.success = false;
            result.transferId = "EDI-ERR-" ~ Clock.currTime().stdTime.to!string;
            result.state = EDIFlowState.Failed;
            result.message = "Validation failed: sender and receiver partner ids are mandatory";
            return result;
        }

        if (_dryRun) {
            result.success = true;
            result.transferId = "EDI-DRY-" ~ Clock.currTime().stdTime.to!string;
            result.state = EDIFlowState.Planned;
            result.message = "Dry-run EDI exchange planned";
            return result;
        }

        immutable receiverOffline = input.receiver.logicalAddress.length == 0;
        if (receiverOffline && plan.allowBuffering) {
            result.success = true;
            result.transferId = "EDI-BUF-" ~ Clock.currTime().stdTime.to!string;
            result.state = EDIFlowState.Buffered;
            result.message = "Receiver unavailable; message buffered for retry";
            return result;
        }

        if (receiverOffline && !plan.allowBuffering) {
            result.success = false;
            result.transferId = "EDI-ERR-" ~ Clock.currTime().stdTime.to!string;
            result.state = EDIFlowState.Failed;
            result.message = "Receiver unavailable and buffering disabled";
            return result;
        }

        result.success = true;
        result.transferId = "EDI-TRF-" ~ Clock.currTime().stdTime.to!string;
        result.state = plan.requireThreeWayMatch && input.messageType == EDIMessageType.INVOIC
            ? EDIFlowState.Matched
            : EDIFlowState.Completed;
        result.message = result.state == EDIFlowState.Matched
            ? "EDI exchange completed with three-way match"
            : "EDI exchange completed";
        return result;
    }
}