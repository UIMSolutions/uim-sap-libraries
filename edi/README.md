# SAP EDI Library for D

This package provides a clean architecture implementation for SAP Electronic Data Interchange scenarios using D and vibe.d.

## Included use cases

- Procure-to-Pay (Purchasing): ORDERS, ORDRSP, DESADV, INVOIC
- Order-to-Cash (Sales): inbound ORDERS, ASN, outbound invoicing
- Logistics and Transport (3PL): IFTMIN, IFTSTA, VMI inventory reporting
- Cash Management (Banking): PAYEXT and FINSTA integration

## Quick Start

```d
import uim.sap.edi;

void main() {
    EDIConfig cfg;
    cfg.defaultSenderLogicalSystem = "SAP_ERP_PRD";

    auto client = new EDIClient(cfg);

    EDIUseCaseInput input;
    input.sender.partnerId = "SAP_ERP_PRD";
    input.sender.role = "BUYER";
    input.receiver.partnerId = "SUPPLIER_4711";
    input.receiver.logicalAddress = "https://supplier-gateway.example/edi";
    input.receiver.role = "SUPPLIER";
    input.messageType = EDIMessageType.ORDERS;
    input.standard = EDIMessageStandard.EDIFACT;
    input.sapTransactionCode = "ME21N";
    input.documentNumber = "4500012345";

    auto result = client.procureToPayPurchasing(input);
    assert(result.success);
}
```