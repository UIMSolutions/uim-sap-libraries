# IDoc Library UML Description

This document provides UML-style descriptions for the SAP IDoc library.

## 1. Use Case Diagram

```plantuml
@startuml
left to right direction
actor "SAP Process Owner" as Business
actor "SAP Integration Admin" as Admin
actor "External System" as Ext

rectangle "IDoc Library" {
  usecase "EDI with External Partners" as UC1
  usecase "ALE Internal Systems" as UC2
  usecase "Third-Party Integration" as UC3
  usecase "Async Fire-and-Forget" as UC4
  usecase "Error Handling Workflow" as UC5
}

Business --> UC1
Business --> UC2
Business --> UC4
Admin --> UC5
Ext --> UC1
Ext --> UC3
@enduml
```

## 2. Component Diagram (Clean Architecture)

```plantuml
@startuml
skinparam componentStyle rectangle

package "Domain" {
  [IDoc Types]
  [Dispatch Plan]
}

package "Application" {
  [IDocUseCase]
  [UseCase Implementations]
  [IDocUseCaseService]
  [IIDocGateway]
  [IIDocWorkflowNotifier]
}

package "Infrastructure" {
  [VibeIDocGateway]
  [InMemoryIDocWorkflowNotifier]
}

package "Interface" {
  [IDocClient]
}

[IDocClient] --> [IDocUseCaseService]
[IDocUseCaseService] --> [IDocUseCase]
[UseCase Implementations] -up-|> [IDocUseCase]
[IDocUseCaseService] --> [IIDocGateway]
[IDocUseCaseService] --> [IIDocWorkflowNotifier]
[VibeIDocGateway] -up-|> [IIDocGateway]
[InMemoryIDocWorkflowNotifier] -up-|> [IIDocWorkflowNotifier]
[IDocUseCase] --> [IDoc Types]
[IDocUseCase] --> [Dispatch Plan]
@enduml
```

## 3. Sequence Diagram (Example: Async Fire-and-Forget)

```plantuml
@startuml
actor Caller
participant IDocClient
participant IDocUseCaseService
participant AsyncFireAndForgetUseCase
participant VibeIDocGateway

Caller -> IDocClient : asyncFireAndForget(input)
IDocClient -> IDocUseCaseService : execute(usecase, input)
IDocUseCaseService -> AsyncFireAndForgetUseCase : execute(input, gateway, notifier, ...)
AsyncFireAndForgetUseCase -> VibeIDocGateway : dispatch(plan, input)
VibeIDocGateway --> AsyncFireAndForgetUseCase : IDocGatewayResult(state=WaitingForTarget)
AsyncFireAndForgetUseCase --> IDocUseCaseService : IDocUseCaseResult
IDocUseCaseService --> IDocClient : IDocUseCaseResult
IDocClient --> Caller : IDocUseCaseResult
@enduml
```

## 4. Class Diagram (Core Types)

```plantuml
@startuml
class IDocClient {
  +ediWithExternalPartners(input)
  +aleInternalSystems(input)
  +thirdPartyIntegration(input)
  +asyncFireAndForget(input)
  +errorHandlingWorkflow(input)
}

class IDocUseCaseService {
  -gateway : IIDocGateway
  -workflowNotifier : IIDocWorkflowNotifier
  -config : IDocConfig
  +execute(useCase, input)
}

abstract class IDocUseCase {
  +name()
  +mode()
  +requireWorkflowOnError()
  +enableAutoResend()
  +notes(input)
  +execute(input, gateway, notifier, ...)
}

interface IIDocGateway {
  +dispatch(plan, input)
}

interface IIDocWorkflowNotifier {
  +notifyFailure(idocNumber, message, receiverSystemId)
}

class VibeIDocGateway
class InMemoryIDocWorkflowNotifier

IDocClient --> IDocUseCaseService
IDocUseCaseService --> IDocUseCase
IDocUseCaseService --> IIDocGateway
IDocUseCaseService --> IIDocWorkflowNotifier
VibeIDocGateway ..|> IIDocGateway
InMemoryIDocWorkflowNotifier ..|> IIDocWorkflowNotifier
@enduml
```

## 5. Message Scenario Coverage

- ORDERS: automated procurement to vendors.
- INVOIC: inbound invoice posting.
- DESADV: advanced shipping notifications.
- MATMAS and ACC_DOCUMENT: ALE master and finance replication.
- DELVRY, PRODORD, CUSDEC: third-party logistics and manufacturing integration.
