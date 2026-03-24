# SAP SNC Library for D

This package provides a clean architecture implementation for SAP SNC (Secure Network Communications) scenarios using D and vibe.d.

## Included SNC use cases

- Zero-Password Login (Kerberos/X.509)
- Smart Card Integration (MFA with PIN-protected token)
- System-to-System Communication
- Third-Party RFC Integration
- Cloud-to-On-Premise Connectivity
- Secure SAP GUI Connections
- Secure Printing
- Encryption-Only Sessions

## Protection levels

- Authentication only
- Integrity protection
- Privacy protection (encryption)

## Quick start

```d
import uim.sap.snc;

void main() {
    SNCConfig cfg;
    cfg.minimumProtectionLevel = SNCProtectionLevel.PrivacyProtection;

    auto client = new SNCClient(cfg);

    SNCUseCaseInput input;
    input.initiator.principal = "CN=alice@example.org";
    input.target.principal = "p:CN=SAP/PRD@EXAMPLE.ORG";
    input.target.endpoint = "https://sap.example.org";

    auto result = client.secureSapGuiConnection(input);
}
```
