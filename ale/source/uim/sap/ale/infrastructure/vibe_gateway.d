module uim.sap.ale.infrastructure.vibe_gateway;

import std.conv : to;
import std.datetime : Clock;

import vibe.data.json : Json;

import uim.sap.ale.domain;
import uim.sap.ale.application.ports;

class VibeALEGateway : IALEGateway {
    private bool _dryRun;

    this(bool dryRun = true) {
        _dryRun = dryRun;
    }

    override ALEGatewayResult distribute(ALEDistributionPlan plan, ALEUseCaseInput input) {
        ALEGatewayResult result;

        // Keep wire payload in Json for straightforward adapter extension.
        Json envelope = Json.emptyObject;
        envelope["useCase"] = Json(plan.useCaseName);
        envelope["sender"] = Json(input.source.systemId);
        envelope["target"] = Json(input.target.systemId);
        envelope["messageType"] = Json(input.messageType.to!string);
        envelope["buffering"] = Json(plan.allowBuffering);

        if (_dryRun) {
            result.success = true;
            result.transferId = "ALE-DRY-" ~ Clock.currTime().stdTime.to!string;
            result.state = ALEDeliveryState.Planned;
            result.message = "Dry-run ALE distribution planned";
            return result;
        }

        immutable targetOffline = input.target.logicalAddress.length == 0;
        if (targetOffline && plan.allowBuffering) {
            result.success = true;
            result.transferId = "ALE-BUF-" ~ Clock.currTime().stdTime.to!string;
            result.state = ALEDeliveryState.Buffered;
            result.message = "Target unavailable; payload buffered for retry";
            return result;
        }

        result.success = !targetOffline;
        result.transferId = "ALE-TRF-" ~ Clock.currTime().stdTime.to!string;
        result.state = result.success ? ALEDeliveryState.Distributed : ALEDeliveryState.Failed;
        result.message = result.success
            ? "ALE payload distributed"
            : "Distribution failed: missing target logical address";
        return result;
    }
}
