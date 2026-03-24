module uim.sap.ale.infrastructure.monitoring;

import std.stdio : writeln;

import uim.sap.ale.application.ports;

class ConsoleALEMonitoringPort : IALEMonitoringPort {
    override void logState(string transferId, string useCaseName, string state, string detail) {
        writeln("[ALE-MONITOR] id=", transferId,
            " usecase=", useCaseName,
            " state=", state,
            " detail=", detail);
    }
}
