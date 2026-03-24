module uim.sap.snc.application.ports.securechannel;

import uim.sap.snc.domain;

interface ISNCSecureChannelGateway {
    SNCGatewayResult openSecureChannel(SNCConnectionPlan plan);
}
