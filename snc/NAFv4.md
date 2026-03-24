# SNC Library NAFv4 Description

This document maps the SNC library architecture to NAFv4-style viewpoints.

## 1. Purpose and Scope

- System of interest: SAP SNC library for D and vibe.d.
- Scope: secure SNC session planning and channel establishment for SAP-related communication patterns.
- Stakeholders: security architects, SAP basis administrators, integration engineers, platform operators.

## 2. NAFv4 Viewpoint Mapping

### 2.1 Capability View (NCV)

Capabilities provided by the SNC library:

- C1: Zero-password user access with Kerberos/X.509.
- C2: Smart card based MFA access.
- C3: Secure system-to-system transport for SAP workloads.
- C4: Secure third-party to SAP RFC integration.
- C5: Secure cloud-to-on-premise SAP connectivity.
- C6: Secure SAP GUI administration sessions.
- C7: Secure print stream protection.
- C8: Encryption-only contractor sessions.

### 2.2 Operational View (NOV)

Operational nodes and exchanges:

- Node A: User workstation or external client.
- Node B: SNC library runtime (application service + use cases).
- Node C: SAP endpoint (ERP/BW/RFC/GUI/spool target).
- Node D: Identity or credential source (AD, PKI, smart card token).

Operational exchange flow:

1. Request enters SNCClient with use-case input.
2. Use case computes effective protection level and authentication chain.
3. Credentials are provisioned by provider for each method in chain.
4. Secure channel plan is sent to secure channel gateway.
5. Gateway returns channel details and status.

### 2.3 Service-Oriented View (NSOV)

Logical service contracts:

- Credential service contract: ISNCCredentialProvider
- Secure channel service contract: ISNCSecureChannelGateway
- Use case orchestration service: SNCUseCaseService

Service quality objectives:

- Deterministic protection-level enforcement.
- Composable authentication chains.
- Transport abstraction decoupled from use case policy.

### 2.4 Systems View (NSV)

Static system breakdown:

- Domain layer: protection levels, participants, connection plans.
- Application layer: abstract use case and specific SNC use cases.
- Infrastructure layer: vibe gateway and credential provider adapters.
- Interface layer: SNCClient facade for consumers.

Dependency direction:

- Interface -> Application -> Domain
- Infrastructure implements Application ports
- Domain has no dependency on infrastructure

### 2.5 Security View (NSecV)

Security controls:

- Protection levels:
  - AuthenticationOnly
  - IntegrityProtection
  - PrivacyProtection
- Mutual authentication support in configuration.
- Method-specific credential provisioning abstraction.
- Use-case specific minimum protection policies.
- Tenant minimum protection override policy.

Control intent by use case:

- Smart card, secure GUI, secure printing, cloud on-prem, system-to-system: privacy protection baseline.
- Zero-password and third-party integration: integrity or stronger.
- Encryption-only: privacy with manual username/password identity flow.

### 2.6 Standards View (NStdV)

Applicable standards and patterns:

- SAP SNC conceptual model for secure communication.
- Kerberos and X.509 for enterprise identity integration.
- Smart card/token plus PIN for MFA context.
- Clean architecture layering for maintainability and testability.

## 3. Architecture Decisions

- AD-1: Use clean architecture to isolate policy from transport.
- AD-2: Represent protection levels as domain enum with enforcement helpers.
- AD-3: Implement use cases as independent policy units.
- AD-4: Use gateway and credential provider interfaces for replaceable adapters.
- AD-5: Provide a facade client to simplify consumer integration.

## 4. Risks and Constraints

- Current gateway implementation is dry-run friendly and uses placeholder transport behavior.
- Real SNC adapter integration requires environment-specific SAP stack details.
- Credential provider is in-memory demo implementation and must be replaced for production.

## 5. Verification Approach

- Unit tests validate protection-level enforcement and facade execution path.
- Package-level test command: dub test (snc package).
- CI matrix includes snc package test execution.
