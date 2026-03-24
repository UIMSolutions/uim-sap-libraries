module uim.sap.idoc.infrastructure.vibe_gateway;

import std.conv : to;
import std.datetime : Clock;

import vibe.data.json : Json;

import uim.sap.idoc.domain;
import uim.sap.idoc.application.ports;

class VibeIDocGateway : IIDocGateway {
    private bool _dryRun;

    this(bool dryRun = true) {
        _dryRun = dryRun;
    }

    override IDocGatewayResult dispatch(IDocDispatchPlan plan, IDocUseCaseInput input) {
        IDocGatewayResult result;

        // Keep payload generation in vibe.d Json for straightforward adapter extension.
        Json outbound = Json.emptyObject;
        outbound["useCase"] = Json(plan.useCaseName);
        outbound["messageType"] = Json(input.messageType.to!string);
        outbound["basicType"] = Json(plan.basicType);
        outbound["sender"] = Json(input.sender.systemId);
        outbound["receiver"] = Json(input.receiver.systemId);
        outbound["asynchronous"] = Json(plan.asynchronous);

        if (_dryRun) {
            result.success = true;
            result.idocNumber = "DRY" ~ Clock.currTime().stdTime.to!string;
            result.state = IDocDeliveryState.Ready;
            result.message = "Dry-run IDoc queued for asynchronous dispatch";
            return result;
        }

        immutable targetDown = input.receiver.logicalAddress.length == 0;

        if (targetDown && plan.enableAutoResend) {
            result.success = true;
            result.idocNumber = "Q" ~ Clock.currTime().stdTime.to!string;
            result.state = IDocDeliveryState.WaitingForTarget;
            result.message = "Target unavailable, IDoc stored and scheduled for resend";
            return result;
        }

        result.success = !targetDown;
        result.idocNumber = "IDOC" ~ Clock.currTime().stdTime.to!string;
        result.state = result.success ? IDocDeliveryState.Completed : IDocDeliveryState.Failed;
        result.message = result.success
            ? "IDoc dispatched successfully"
            : "Dispatch failed due to missing target address";
        return result;
    }
}
