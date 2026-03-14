# RFC Adapter Library for D

A lightweight RFC adapter for D applications, built with `uim-framework` and `vibe.d`.

This package targets RFC access through HTTP/JSON adapter endpoints (for example, ICF/API wrappers that expose RFC function modules).

## Features

- Typed adapter API for RFC invocation
- Basic and Bearer authentication support
- SAP-specific headers (`sap-client`, `sap-language`)
- Config validation and custom headers
- Retry handling and structured exceptions

## Installation

Add to your `dub.sdl`:

```sdl
dependency "uim-rfc" version="~>1.0.0"
```

Or to your `dub.json`:

```json
{
  "dependencies": {
    "uim-rfc": "~>1.0.0"
  }
}
```

## Quick Start

```d
import uim.sap.rfc;
import vibe.data.json : Json;

void main() {
    auto config = RFCConfig.createBasic(
        "https://my.sap.system",
        "SAPUSER",
        "SAPPASSWORD",
        "100"
    );

    config.endpointPath = "/sap/bc/rfc";

    auto client = new RFCClient(config);

    if (client.testConnection()) {
        Json params = Json.emptyObject;
        params["REQUTEXT"] = "Hello from D";

        auto response = client.invoke("STFC_CONNECTION", params);
        // Handle response.data
    }
}
```

## Configuration

```d
RFCConfig config;
config.baseUrl = "my.sap.system";
config.useSSL = true;
config.port = 443;
config.endpointPath = "/sap/bc/rfc";
config.authType = RFCAuthType.Bearer;
config.bearerToken = "<access-token>";
config.sapClient = "100";
config.sapLanguage = "EN";
config.maxRetries = 3;
```

## Error Handling

The adapter provides these exception types:

- `RFCException` (base)
- `RFCConfigurationException`
- `RFCConnectionException`
- `RFCInvocationException`
