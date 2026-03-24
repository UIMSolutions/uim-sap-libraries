# SAP IDoc Library for D

This package provides a clean architecture implementation for SAP IDoc (Intermediate Document) scenarios using D and vibe.d.

## Included use cases

- Electronic Data Interchange (EDI) with external partners
- ALE-based synchronization between SAP systems
- Integration with third-party non-SAP systems
- Asynchronous fire-and-forget reliability scenarios
- Error handling and workflow-triggered reprocessing

## Quick Start

```d
import uim.sap.idoc;

void main() {
    IDocConfig cfg;
    cfg.defaultPort = "A000000123";

    auto client = new IDocClient(cfg);

    IDocUseCaseInput input;
    input.sender.systemId = "ERP_PRD";
    input.receiver.systemId = "VENDOR_GATEWAY";
    input.messageType = IDocMessageType.ORDERS;
    input.basicType = "ORDERS05";

    auto result = client.ediWithExternalPartners(input);
}
```
