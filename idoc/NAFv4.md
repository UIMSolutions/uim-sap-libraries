# IDoc Library NAFv4 Description

This document maps the SAP IDoc library architecture to NAFv4-style viewpoints.

## 1. Purpose and Scope

- System of interest: IDoc clean architecture library for D and vibe.d.
- Scope: asynchronous SAP IDoc dispatch orchestration, reliability behavior, and workflow-driven error handling.
- Stakeholders: enterprise architects, SAP integration teams, platform operators, business process owners.

## 2. NAFv4 Viewpoint Mapping

### 2.1 Capability View (NCV)

Capabilities provided by this module:

- C1: EDI exchange with external business partners.
- C2: ALE synchronization across internal SAP systems.
- C3: Non-SAP third-party system integration.
- C4: Reliable asynchronous fire-and-forget processing.
- C5: Workflow-based error handling and reprocessing support.

### 2.2 Operational View (NOV)

Operational nodes:

- Node A: Sending system (SAP ERP/S4 or external producer).
- Node B: IDoc library runtime.
- Node C: Receiving system (SAP or non-SAP).
- Node D: Operational workflow/monitoring actor.

Operational flow:

1. Caller submits IDoc use-case request with message metadata.
2. Use case generates dispatch plan and reliability policy.
3. Gateway attempts dispatch or queues for asynchronous resend.
4. On failure conditions, workflow notifier emits operational event.
5. Result is returned with state and diagnostic context.

### 2.3 Service-Oriented View (NSOV)

Service contracts:

- IDoc dispatch contract: IIDocGateway
- Workflow notification contract: IIDocWorkflowNotifier
- Application orchestration service: IDocUseCaseService

Service qualities:

- Asynchronous integration first.
- Stable contract boundaries for adapter replacement.
- Explicit reliability and error handling policies per use case.

### 2.4 Systems View (NSV)

Static architecture:

- Domain: message types, processing modes, dispatch plan, delivery states.
- Application: use-case policies and orchestration.
- Infrastructure: vibe.d transport adapter and workflow notifier adapter.
- Interface: IDocClient facade.

Dependency direction:

- Interface -> Application -> Domain
- Infrastructure implements Application ports
- Domain is infrastructure-agnostic

### 2.5 Security View (NSecV)

Security and integrity concerns:

- Message processing policies are explicit and auditable via use-case plans.
- Asynchronous queueing model avoids data loss from transient connectivity issues.
- Workflow signaling supports controlled reprocessing and operational governance.
- Integration boundary enables future insertion of signing/encryption adapters.

### 2.6 Standards View (NStdV)

Applicable standards and patterns:

- SAP IDoc-based enterprise integration patterns.
- EDI bridge contexts including EDIFACT/ANSI X12 mappings.
- ALE distribution model for SAP landscapes.
- Clean architecture principles for maintainable integration libraries.

## 3. Architecture Decisions

- AD-1: Model integration scenarios as separate use-case classes.
- AD-2: Keep transport behind IIDocGateway to support multiple adapters.
- AD-3: Treat asynchronous processing as default operating mode.
- AD-4: Trigger workflow notifications through dedicated port abstraction.
- AD-5: Use IDocClient facade to simplify consumer integration.

## 4. Risks and Constraints

- Current gateway provides dry-run and simulated operational behavior.
- Real partner mappings and SAP port configuration are environment-specific.
- Production workflow integration requires concrete enterprise eventing/notification backend.

## 5. Verification Approach

- Unit tests validate facade behavior and asynchronous waiting-state scenario.
- Package-level verification command: dub test in idoc package.
- Repository CI matrix includes idoc test execution.
