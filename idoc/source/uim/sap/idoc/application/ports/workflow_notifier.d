module uim.sap.idoc.application.ports.workflow_notifier;

interface IIDocWorkflowNotifier {
    void notifyFailure(string idocNumber, string message, string receiverSystemId);
}
