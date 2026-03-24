module uim.sap.idoc.infrastructure.workflow_notifier;

import std.stdio : writeln;

import uim.sap.idoc.application.ports;

class InMemoryIDocWorkflowNotifier : IIDocWorkflowNotifier {
    override void notifyFailure(string idocNumber, string message, string receiverSystemId) {
        writeln("[IDOC-WORKFLOW] receiver=", receiverSystemId,
            " idoc=", idocNumber,
            " message=", message);
    }
}
