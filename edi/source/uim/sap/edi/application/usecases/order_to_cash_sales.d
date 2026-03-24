module uim.sap.edi.application.usecases.order_to_cash_sales;

import uim.sap.edi.domain;
import uim.sap.edi.application.usecases.base;

class OrderToCashSalesUseCase : EDIUseCase {
    override string name() const {
        return "Order-to-Cash (Sales)";
    }

    override EDIProcessMode mode() const {
        return EDIProcessMode.OrderToCashSales;
    }

    override bool allowBuffering() const {
        return true;
    }

    override bool requireAcknowledgement() const {
        return true;
    }

    override bool requireThreeWayMatch() const {
        return false;
    }

    override EDIMessageType[] supportedMessageTypes() const {
        return [
            EDIMessageType.ORDERS,
            EDIMessageType.ASN,
            EDIMessageType.OUTBOUND_INVOICE
        ];
    }

    override string[] checkpoints(EDIUseCaseInput input) const {
        return [
            "Customer ORDERS creates SAP sales order without manual entry",
            "Shipping notification (ASN) is sent for fulfillment visibility",
            "Outbound invoicing is delivered electronically to accelerate payment",
            "SAP transaction context: " ~ input.sapTransactionCode
        ];
    }
}