module app;

import uim.sap.oau;

void main() {
    OAUConfig config = new OAUConfig;
    config.host = envOr("OAU_HOST", "0.0.0.0");
    config.port = readPort(envOr("OAU_PORT", "8090"), 8090);
    config.basePath = envOr("OAU_BASE_PATH", "/api/oau");
    config.serviceName = envOr("OAU_SERVICE_NAME", "uim-oau");
    config.serviceVersion = envOr("OAU_SERVICE_VERSION", UIM_OAU_VERSION);

    config.maxClients = readSize(envOr("OAU_MAX_CLIENTS", "1000"), 1000);
    config.authCodeLifetimeSecs = readSize(envOr("OAU_AUTH_CODE_LIFETIME", "600"), 600);
    config.accessTokenLifetimeSecs = readSize(envOr("OAU_ACCESS_TOKEN_LIFETIME", "3600"), 3600);
    config.refreshTokenLifetimeSecs = readSize(envOr("OAU_REFRESH_TOKEN_LIFETIME", "86400"), 86_400);
    config.maxScopesPerClient = readSize(envOr("OAU_MAX_SCOPES_PER_CLIENT", "50"), 50);
    config.issuer = envOr("OAU_ISSUER", "uim-oau");

    auto token = envOr("OAU_AUTH_TOKEN", "");
    if (token.length > 0) {
        config.requireAuthToken(true);
        config.authToken(token);
    }

    config.customHeader("X-Service", config.serviceName);
    config.customHeader("X-Version", config.serviceVersion);

    auto service = new OAUService(config);
    auto server = new OAUServer(service);

    writeln("Starting OAuth 2.0 Service on ", config.host, ":", config.port);
    writeln("Base path: ", config.basePath);
    writeln("Issuer: ", config.issuer);
    server.run();
}
