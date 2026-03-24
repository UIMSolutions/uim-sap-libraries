# SNC Library UML Description

This document provides UML-style descriptions for the SAP SNC library.

## 1. Use Case Diagram

```plantuml
@startuml
left to right direction
actor "SAP User" as User
actor "Security Admin" as Admin
actor "External System" as Ext

rectangle "SNC Library" {
  usecase "Zero-Password Login" as UC1
  usecase "Smart Card Integration" as UC2
  usecase "System-to-System Communication" as UC3
  usecase "Third-Party Integration" as UC4
  usecase "Cloud-to-On-Premise Connectivity" as UC5
  usecase "Secure SAP GUI Connections" as UC6
  usecase "Secure Printing" as UC7
  usecase "Encryption Only" as UC8
}

User --> UC1
User --> UC2
User --> UC6
User --> UC8
Admin --> UC2
Admin --> UC6
Admin --> UC7
Ext --> UC3
Ext --> UC4
Ext --> UC5
@enduml
```

## 2. Component Diagram (Clean Architecture)

```plantuml
@startuml
skinparam componentStyle rectangle

package "Domain" {
  [SNCProtectionLevel]
  [SNC Types]
}

package "Application" {
  [SNCSecurityUseCase]
  [UseCase Implementations]
  [SNCUseCaseService]
  [ISNCSecureChannelGateway]
  [ISNCCredentialProvider]
}

package "Infrastructure" {
  [VibeSNCSecureChannelGateway]
  [InMemoryCredentialProvider]
}

package "Interface" {
  [SNCClient]
}

[SNCClient] --> [SNCUseCaseService]
[SNCUseCaseService] --> [SNCSecurityUseCase]
[UseCase Implementations] -up-|> [SNCSecurityUseCase]
[SNCUseCaseService] --> [ISNCSecureChannelGateway]
[SNCUseCaseService] --> [ISNCCredentialProvider]
[VibeSNCSecureChannelGateway] -up-|> [ISNCSecureChannelGateway]
[InMemoryCredentialProvider] -up-|> [ISNCCredentialProvider]
[SNCSecurityUseCase] --> [SNCProtectionLevel]
[SNCSecurityUseCase] --> [SNC Types]
@enduml
```

## 3. Sequence Diagram (Example: Smart Card Integration)

```plantuml
@startuml
actor User
participant SNCClient
participant SNCUseCaseService
participant SmartCardIntegrationUseCase
participant InMemoryCredentialProvider
participant VibeSNCSecureChannelGateway

User -> SNCClient : smartCardIntegration(input)
SNCClient -> SNCUseCaseService : execute(usecase, input)
SNCUseCaseService -> SmartCardIntegrationUseCase : execute(input, gateway, minLevel)
SmartCardIntegrationUseCase -> InMemoryCredentialProvider : canProvide(SmartCardWithPin)
SmartCardIntegrationUseCase -> InMemoryCredentialProvider : issueCredential(...)
SmartCardIntegrationUseCase -> VibeSNCSecureChannelGateway : openSecureChannel(plan)
VibeSNCSecureChannelGateway --> SmartCardIntegrationUseCase : SNCGatewayResult
SmartCardIntegrationUseCase --> SNCUseCaseService : SNCUseCaseResult
SNCUseCaseService --> SNCClient : SNCUseCaseResult
SNCClient --> User : SNCUseCaseResult
@enduml
```

## 4. Class Diagram (Core Types)

```plantuml
@startuml
class SNCClient {
  +zeroPasswordLogin(input)
  +smartCardIntegration(input)
  +systemToSystemCommunication(input)
  +thirdPartyIntegration(input)
  +cloudToOnPremiseConnectivity(input)
  +secureSapGuiConnection(input)
  +securePrinting(input)
  +encryptionOnly(input)
}

class SNCUseCaseService {
  -gateway : ISNCSecureChannelGateway
  -credentialProvider : ISNCCredentialProvider
  -tenantMinimumLevel : SNCProtectionLevel
  +execute(useCase, input)
}

abstract class SNCSecurityUseCase {
  +name()
  +minimumProtectionLevel()
  +authenticationChain()
  +notes(input)
  +execute(input, gateway, tenantMinimumLevel)
}

interface ISNCSecureChannelGateway {
  +openSecureChannel(plan)
}

interface ISNCCredentialProvider {
  +canProvide(method)
  +issueCredential(method, principal)
}

class VibeSNCSecureChannelGateway
class InMemoryCredentialProvider

SNCClient --> SNCUseCaseService
SNCUseCaseService --> SNCSecurityUseCase
SNCUseCaseService --> ISNCSecureChannelGateway
SNCUseCaseService --> ISNCCredentialProvider
VibeSNCSecureChannelGateway ..|> ISNCSecureChannelGateway
InMemoryCredentialProvider ..|> ISNCCredentialProvider
@enduml
```

## 5. Protection Level Mapping

- AuthenticationOnly: verifies identities.
- IntegrityProtection: verifies identities and detects tampering.
- PrivacyProtection: encryption plus integrity plus authentication.
