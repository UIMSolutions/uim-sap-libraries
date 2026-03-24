module uim.sap.snc.infrastructure.vibe_gateway;

import std.conv : to;
import std.datetime : Clock;

import vibe.data.json : Json;

import uim.sap.snc.domain;
import uim.sap.snc.application.ports;

class VibeSNCSecureChannelGateway : ISNCSecureChannelGateway {
    private bool _dryRun;

    this(bool dryRun = true) {
        _dryRun = dryRun;
    }

    override SNCGatewayResult openSecureChannel(SNCConnectionPlan plan) {
        SNCGatewayResult result;

        // Build handshake payload with vibe.d Json to keep transport layer extensible.
        Json handshake = Json.emptyObject;
        handshake["useCase"] = Json(plan.useCaseName);
        handshake["target"] = Json(plan.targetEndpoint);
        handshake["protectionLevel"] = Json(cast(uint)plan.effectiveProtectionLevel);

        if (_dryRun) {
            result.success = true;
            result.channelId = "snc-dry-" ~ Clock.currTime().stdTime.to!string;
            result.transport = "vibe.d/dry-run";
            result.message = "Dry-run SNC handshake established";
            return result;
        }

        // Placeholder for real handshake transport (for example HTTP/RFC bridge).
        result.success = plan.targetEndpoint.length > 0;
        result.channelId = "snc-live-" ~ Clock.currTime().stdTime.to!string;
        result.transport = "vibe.d";
        result.message = result.success
            ? "SNC handshake request dispatched"
            : "Missing target endpoint for live SNC handshake";
        return result;
    }
}
