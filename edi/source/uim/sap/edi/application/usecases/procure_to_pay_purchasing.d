module uim.sap.edi.application.usecases.procure_to_pay_purchasing;

import uim.sap.edi.domain;
import uim.sap.edi.application.usecases.base;

class ProcureToPayPurchasingUseCase : EDIUseCase {
    override string name() const {
        return "Procure-to-Pay (Purchasing)";
    }

    override EDIProcessMode mode() const {
        return EDIProcessMode.ProcureToPayPurchasing;
    }

    override bool allowBuffering() const {
        return true;
    }

    override bool requireAcknowledgement() const {
        return true;
    }

    override bool requireThreeWayMatch() const {
        return true;
    }

    override EDIMessageType[] supportedMessageTypes() const {
        return [
            EDIMessageType.ORDERS,
            EDIMessageType.ORDRSP,
            EDIMessageType.DESADV,
            EDIMessageType.INVOIC
        ];
    }

    override string[] checkpoints(EDIUseCaseInput input) const {
        return [
            "Purchase order (ORDERS) created in SAP and transmitted to supplier",
            "Order response (ORDRSP) consumed and linked to originating purchase order",
            "ASN (DESADV) used to build inbound delivery automatically",
            "Invoice (INVOIC) posted and matched by three-way validation",
            "SAP transaction context: " ~ input.sapTransactionCode
        ];
    }
}