module uim.sap.edi.infrastructure.monitoring;

import std.stdio : writeln;

import uim.sap.edi.application.ports;

class ConsoleEDIMonitoringPort : IEDIMonitoringPort {
    override void logState(string transferId, string useCaseName, string state, string detail) {
        writeln("[EDI-MONITOR] id=", transferId,
            " usecase=", useCaseName,
            " state=", state,
            " detail=", detail);
    }
}