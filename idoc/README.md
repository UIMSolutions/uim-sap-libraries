# IDOC Library for D

IDOC client library for D language, built with `uim-framework` and `vibe.d`.

This package provides a typed adapter for IDOC submission and status retrieval against HTTP-based IDOC integration endpoints.

## Features

- Submit IDOCs with typed control record and segment payloads
- Query IDOC processing status by document number
- Basic and Bearer authentication support
- headers support (`sap-client`, `sap-language`)
- Retry logic and typed exception hierarchy

## Installation

`dub.sdl`:

```sdl
dependency "uim-idoc" version="~>1.0.0"
```

`dub.json`:

```json
{
  "dependencies": {
    "uim-idoc": "~>1.0.0"
  }
}
```

## Quick Start

```d
import uim.sap.idoc;
import vibe.data.json : Json;

void main() {
    auto cfg = SAPIDocConfig.createBasic(
        "https://my.sap.system",
        "SAPUSER",
        "SAPPASSWORD",
        "100"
    );

    cfg.endpointPath = "/sap/idoc";

    auto client = new SAPIDocClient(cfg);

    Json segments = Json.emptyArray;

    Json seg1 = Json.emptyObject;
    seg1["segmentName"] = Json("E1EDK01");
    seg1["fields"] = Json.emptyObject;
    seg1["fields"]["BELNR"] = Json("4500001234");
    segments ~= seg1;

    auto response = client.submit("ORDERS05", "ORDERS", segments);
    auto status = client.getStatus(response.documentNumber);
}
```

## Exception Types

- `SAPIDocException`
- `SAPIDocConfigurationException`
- `SAPIDocConnectionException`
- `SAPIDocRequestException`
