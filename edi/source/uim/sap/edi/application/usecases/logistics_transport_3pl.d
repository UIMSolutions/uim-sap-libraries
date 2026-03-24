module uim.sap.edi.application.usecases.logistics_transport_3pl;

import uim.sap.edi.domain;
import uim.sap.edi.application.usecases.base;

class LogisticsTransport3PLUseCase : EDIUseCase {
    override string name() const {
        return "Logistics and Transport (3PL)";
    }

    override EDIProcessMode mode() const {
        return EDIProcessMode.LogisticsTransport3PL;
    }

    override bool allowBuffering() const {
        return true;
    }

    override bool requireAcknowledgement() const {
        return false;
    }

    override bool requireThreeWayMatch() const {
        return false;
    }

    override EDIMessageType[] supportedMessageTypes() const {
        return [
            EDIMessageType.IFTMIN,
            EDIMessageType.IFTSTA,
            EDIMessageType.INVENTORY_REPORT
        ];
    }

    override string[] checkpoints(EDIUseCaseInput input) const {
        return [
            "Shipping instructions (IFTMIN) sent from SAP shipping",
            "Carrier status updates (IFTSTA) reflected in SAP document flow",
            "VMI inventory reports drive supplier replenishment decisions",
            "Logistics collaboration for document " ~ input.documentNumber
        ];
    }
}