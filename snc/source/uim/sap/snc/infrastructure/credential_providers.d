module uim.sap.snc.infrastructure.credential_providers;

import std.conv : to;
import std.random : uniform;

import uim.sap.snc.domain;
import uim.sap.snc.application.ports;

class InMemoryCredentialProvider : ISNCCredentialProvider {
    override bool canProvide(SNCAuthenticationMethod method) {
        final switch (method) {
            case SNCAuthenticationMethod.Kerberos:
            case SNCAuthenticationMethod.X509Certificate:
            case SNCAuthenticationMethod.SmartCardWithPin:
            case SNCAuthenticationMethod.UsernamePassword:
            case SNCAuthenticationMethod.ServicePrincipal:
            case SNCAuthenticationMethod.TechnicalCertificate:
                return true;
        }
    }

    override string issueCredential(SNCAuthenticationMethod method, string principal) {
        immutable nonce = uniform(100_000, 999_999);
        return method.to!string ~ ":" ~ principal ~ ":" ~ nonce.to!string;
    }
}
