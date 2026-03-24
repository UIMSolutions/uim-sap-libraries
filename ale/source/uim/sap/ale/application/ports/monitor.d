module uim.sap.ale.application.ports.monitor;

interface IALEMonitoringPort {
    void logState(string transferId, string useCaseName, string state, string detail);
}
