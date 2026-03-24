module uim.sap.edi.application.ports.monitor;

interface IEDIMonitoringPort {
    void logState(string transferId, string useCaseName, string state, string detail);
}