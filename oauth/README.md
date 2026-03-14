# OAuth 2.0 on SAP BTP — UIM Service

OAuth 2.0 authorization and authentication service for SAP BTP, built with D, the UIM framework, and vibe.d.

Supports a wide range of application scenarios including web, mobile, and IoT.

## Features

- **Authorization Code Grant** (RFC 6749 §4.1) — for web and mobile applications with user interaction
- **Client Credentials Grant** (RFC 6749 §4.4) — for server-to-server / machine-to-machine communication  
- **Token Refresh** (RFC 6749 §6) — rotate access tokens using refresh tokens
- **Token Introspection** (RFC 7662) — validate and inspect active tokens
- **Token Revocation** (RFC 7009) — revoke access and refresh tokens
- **PKCE Support** — Proof Key for Code Exchange for public clients
- **Client Management** — register, update, suspend, and delete OAuth clients
- **Scope Management** — define and manage authorization scopes
- **In-memory Store** — thread-safe, mutex-synchronized data store

## Configuration

| Variable | Default | Description |
|---|---|---|
| `OAU_HOST` | `0.0.0.0` | Listen address |
| `OAU_PORT` | `8090` | Listen port |
| `OAU_BASE_PATH` | `/api/oau` | API base path |
| `OAU_SERVICE_NAME` | `uim-oau` | Service identifier |
| `OAU_AUTH_TOKEN` | *(empty)* | Bearer token for management API |
| `OAU_MAX_CLIENTS` | `1000` | Maximum registered clients |
| `OAU_AUTH_CODE_LIFETIME` | `600` | Authorization code TTL (seconds) |
| `OAU_ACCESS_TOKEN_LIFETIME` | `3600` | Access token TTL (seconds) |
| `OAU_REFRESH_TOKEN_LIFETIME` | `86400` | Refresh token TTL (seconds) |
| `OAU_MAX_SCOPES_PER_CLIENT` | `50` | Max scopes per client |
| `OAU_ISSUER` | `uim-oau` | Token issuer identifier |

## API Endpoints

### OAuth Protocol

| Method | Path | Description |
|---|---|---|
| POST | `/api/oau/oauth/authorize` | Request authorization code |
| POST | `/api/oau/oauth/token` | Exchange code / credentials for tokens |
| POST | `/api/oau/oauth/introspect` | Introspect an access token |
| POST | `/api/oau/oauth/revoke` | Revoke a token |

### Client Management

| Method | Path | Description |
|---|---|---|
| GET | `/api/oau/v1/clients` | List all clients |
| POST | `/api/oau/v1/clients` | Register a new client |
| GET | `/api/oau/v1/clients/{id}` | Get client details |
| PUT | `/api/oau/v1/clients/{id}` | Update client |
| DELETE | `/api/oau/v1/clients/{id}` | Delete client |
| POST | `/api/oau/v1/clients/{id}/suspend` | Suspend a client |

### Scope Management

| Method | Path | Description |
|---|---|---|
| GET | `/api/oau/v1/scopes` | List all scopes |
| POST | `/api/oau/v1/scopes` | Create a scope |
| GET | `/api/oau/v1/scopes/{id}` | Get scope details |
| DELETE | `/api/oau/v1/scopes/{id}` | Delete a scope |

### Health

| Method | Path | Description |
|---|---|---|
| GET | `/api/oau/health` | Health check |
| GET | `/api/oau/ready` | Readiness probe |

## Grant Flows

### Authorization Code Grant

1. **Client** requests authorization via `POST /oauth/authorize` with `response_type=code`
2. **Server** validates client, redirect URI, and scopes; returns an authorization `code`
3. **Client** exchanges the code via `POST /oauth/token` with `grant_type=authorization_code`
4. **Server** returns `access_token`, `refresh_token`, `expires_in`, and `scope`

### Client Credentials Grant

1. **Client** sends `POST /oauth/token` with `grant_type=client_credentials`, `client_id`, and `client_secret`
2. **Server** authenticates the client and returns `access_token`, `expires_in`, and `scope`
3. No refresh token is issued (server-to-server pattern)

## Container

```bash
# Build
podman build -t ghcr.io/uimsolutions/uim-sap-oau:latest .

# Run
podman run --rm -p 8090:8090 ghcr.io/uimsolutions/uim-sap-oau:latest
```

## Kubernetes

```bash
kubectl apply -f k8s/
```

## License

Apache-2.0
