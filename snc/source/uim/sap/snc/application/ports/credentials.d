module uim.sap.snc.application.ports.credentials;

import uim.sap.snc.domain;

interface ISNCCredentialProvider {
    bool canProvide(SNCAuthenticationMethod method);
    string issueCredential(SNCAuthenticationMethod method, string principal);
}
