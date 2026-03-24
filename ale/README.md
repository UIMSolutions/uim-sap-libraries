# SAP ALE Library for D

This package provides a clean architecture implementation for SAP Application Link Enabling using D and vibe.d.

## Included use cases

- Master Data Distribution
- Distributed Business Processes
- Central Finance and Reporting
- HR Mini-Master Distribution
- Decoupled High-Availability WMS buffering

## Quick start

```d
import uim.sap.ale;

void main() {
    ALEConfig cfg;
    cfg.defaultLogicalSystem = "SAPCLNT100";

    auto client = new ALEClient(cfg);

    ALEUseCaseInput input;
    input.source.systemId = "MDM_CORE";
    input.target.systemId = "ERP_REGION_EU";
    input.messageType = ALEMessageType.MATMAS;

    auto result = client.masterDataDistribution(input);
}
```
