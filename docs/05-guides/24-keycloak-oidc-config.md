# Keycloak OIDC Configuration Guide

**Document:** 24  
**Location:** `docs/05-guides/24-keycloak-oidc-config.md`  
**Last Updated:** March 2026

This guide covers configuring Keycloak as the Single Sign-On (SSO) provider for all IT-Stack services using OpenID Connect (OIDC) and SAML 2.0. After following this guide, users log in once through Keycloak and are automatically authenticated across every service.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Prerequisites](#2-prerequisites)
3. [Keycloak Initial Setup](#3-keycloak-initial-setup)
4. [OIDC Client: Nextcloud](#4-oidc-client-nextcloud)
5. [OIDC Client: Mattermost](#5-oidc-client-mattermost)
6. [OIDC Client: Taiga](#6-oidc-client-taiga)
7. [OIDC Client: Zabbix](#7-oidc-client-zabbix)
8. [OIDC Client: Odoo](#8-oidc-client-odoo)
9. [SAML Client: SuiteCRM](#9-saml-client-suitecrm)
10. [SAML Client: Snipe-IT](#10-saml-client-snipe-it)
11. [User & Group Management](#11-user--group-management)
12. [Token & Session Configuration](#12-token--session-configuration)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. Architecture Overview

```
User Browser
    │
    ▼ (login button on any service)
Keycloak (http://4.154.17.25:8180)
    │  Issues: ID token + Access token + Refresh token
    ▼
Service validates token → grants access
    │
    ▼ (attribute mapping)
User profile populated from Keycloak claims
(email, name, groups, roles)
```

**Token flow used:** Authorization Code Flow (all services)  
**Session lifetime:** 8 hours idle, 24 hours maximum  
**Realm:** `it-stack` (all services share one realm)  
**Admin console:** `http://4.154.17.25:8180/admin/`

---

## 2. Prerequisites

- Keycloak running: `docker ps | grep keycloak-demo` → `Up`
- Keycloak admin credentials: username `admin`, check via `docker inspect keycloak-demo` for `KEYCLOAK_ADMIN_PASSWORD`
- All target services running

**Get Keycloak admin password:**

```bash
docker inspect keycloak-demo --format '{{range .Config.Env}}{{println .}}{{end}}' | grep KEYCLOAK_ADMIN_PASSWORD
```

---

## 3. Keycloak Initial Setup

### 3.1 Create the `it-stack` Realm

```bash
# Get admin token
KC_URL="http://localhost:8180"
KC_ADMIN="admin"
KC_PASS=$(docker inspect keycloak-demo \
  --format '{{range .Config.Env}}{{println .}}{{end}}' \
  | grep KEYCLOAK_ADMIN_PASSWORD | cut -d= -f2)

TOKEN=$(curl -s -X POST "$KC_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=$KC_ADMIN&password=$KC_PASS&grant_type=password&client_id=admin-cli" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

echo "Got token: ${TOKEN:0:20}..."

# Create realm
curl -s -X POST "$KC_URL/admin/realms" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "realm": "it-stack",
    "displayName": "IT-Stack",
    "enabled": true,
    "loginWithEmailAllowed": true,
    "registrationAllowed": false,
    "resetPasswordAllowed": true,
    "rememberMe": true,
    "sslRequired": "none",
    "accessTokenLifespan": 300,
    "ssoSessionIdleTimeout": 28800,
    "ssoSessionMaxLifespan": 86400
  }' && echo "Realm created"
```

### 3.2 Create Admin Service Account Groups

```bash
# Create groups that map to service roles
for group in "it-admins" "it-staff" "all-users" "helpdesk" "managers"; do
  curl -s -X POST "$KC_URL/admin/realms/it-stack/groups" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"$group\"}" && echo "Group created: $group"
done
```

### 3.3 Create Test Users

```bash
# Create a standard user
curl -s -X POST "$KC_URL/admin/realms/it-stack/users" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "jsmith",
    "email": "jsmith@itstack.local",
    "firstName": "John",
    "lastName": "Smith",
    "enabled": true,
    "emailVerified": true,
    "credentials": [{"type":"password","value":"ChangeMe01!","temporary":true}],
    "groups": ["/all-users"]
  }' && echo "User created"
```

---

## 4. OIDC Client: Nextcloud

### 4.1 Register the Client in Keycloak

Via Keycloak Admin UI (**http://4.154.17.25:8180/admin/**):

1. Switch to realm **it-stack**
2. **Clients** → **Create client**
3. Fill in:
   | Field | Value |
   |-------|-------|
   | Client type | OpenID Connect |
   | Client ID | `nextcloud` |
   | Name | Nextcloud |
   | Client authentication | ON |
   | Authorization | OFF |
   | Standard flow | ON (✅) |
   | Direct access grants | OFF |
4. **Next** → Valid redirect URIs: `http://4.154.17.25:8280/*`
5. Web origins: `http://4.154.17.25:8280`
6. **Save**
7. **Credentials** tab → copy Client secret

**Or via API:**

```bash
curl -s -X POST "$KC_URL/admin/realms/it-stack/clients" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "nextcloud",
    "name": "Nextcloud",
    "enabled": true,
    "protocol": "openid-connect",
    "publicClient": false,
    "standardFlowEnabled": true,
    "directAccessGrantsEnabled": false,
    "redirectUris": ["http://4.154.17.25:8280/*"],
    "webOrigins": ["http://4.154.17.25:8280"]
  }' && echo "Nextcloud client created"

# Get the client secret (need client UUID first)
CLIENT_UUID=$(curl -s "$KC_URL/admin/realms/it-stack/clients?clientId=nextcloud" \
  -H "Authorization: Bearer $TOKEN" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

NC_SECRET=$(curl -s "$KC_URL/admin/realms/it-stack/clients/$CLIENT_UUID/client-secret" \
  -H "Authorization: Bearer $TOKEN" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['value'])")

echo "Nextcloud client secret: $NC_SECRET"
```

### 4.2 Configure Nextcloud

```bash
# Enable Social Login app
docker exec -u 33 nc-demo php occ app:enable sociallogin

# Configure OIDC
docker exec -u 33 nc-demo php occ config:system:set \
  social_login_providers --value='[{
    "appid":"oidc_login",
    "name":"IT-Stack Login",
    "type":"oidc",
    "client_id":"nextcloud",
    "client_secret":"REPLACE_WITH_SECRET",
    "authorize_url":"http://4.154.17.25:8180/realms/it-stack/protocol/openid-connect/auth",
    "token_url":"http://localhost:8180/realms/it-stack/protocol/openid-connect/token",
    "userinfo_url":"http://localhost:8180/realms/it-stack/protocol/openid-connect/userinfo",
    "logout_url":"http://4.154.17.25:8180/realms/it-stack/protocol/openid-connect/logout",
    "scope":"openid email profile",
    "default_group":"all-users",
    "username_attribute":"preferred_username",
    "email_attribute":"email"
  }]'
```

> After this, a **"Login with IT-Stack"** button appears on the Nextcloud login page.

---

## 5. OIDC Client: Mattermost

### 5.1 Register in Keycloak

```bash
curl -s -X POST "$KC_URL/admin/realms/it-stack/clients" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "mattermost",
    "name": "Mattermost",
    "enabled": true,
    "protocol": "openid-connect",
    "publicClient": false,
    "standardFlowEnabled": true,
    "redirectUris": [
      "http://4.154.17.25:8265/signup/gitlab/complete",
      "http://4.154.17.25:8265/login/gitlab/complete"
    ],
    "webOrigins": ["http://4.154.17.25:8265"]
  }' && echo "Mattermost client created"
```

> **Note:** Mattermost uses the "GitLab" SSO endpoint for custom OIDC providers.

### 5.2 Configure Mattermost

In Mattermost Admin Console (**System Console** → **Authentication** → **GitLab**):

| Field | Value |
|-------|-------|
| Enable authentication with GitLab | True |
| Application ID | `mattermost` |
| Application Secret Key | *(from Keycloak Credentials tab)* |
| GitLab Site URL | `http://4.154.17.25:8180/realms/it-stack` |
| Discovery Endpoint | `[leave blank]` |
| Auth Endpoint | `/protocol/openid-connect/auth` |
| Token Endpoint | `/protocol/openid-connect/token` |
| User API Endpoint | `/protocol/openid-connect/userinfo` |

**Or via Mattermost config (config.json):**

```bash
docker exec mm-demo mmctl config set GitLabSettings.Enable true
docker exec mm-demo mmctl config set GitLabSettings.Id "mattermost"
docker exec mm-demo mmctl config set GitLabSettings.Secret "REPLACE_WITH_SECRET"
docker exec mm-demo mmctl config set GitLabSettings.Url "http://4.154.17.25:8180/realms/it-stack"
docker exec mm-demo mmctl config set GitLabSettings.AuthEndpoint "protocol/openid-connect/auth"
docker exec mm-demo mmctl config set GitLabSettings.TokenEndpoint "protocol/openid-connect/token"
docker exec mm-demo mmctl config set GitLabSettings.UserApiEndpoint "protocol/openid-connect/userinfo"
```

---

## 6. OIDC Client: Taiga

### 6.1 Register in Keycloak

```bash
curl -s -X POST "$KC_URL/admin/realms/it-stack/clients" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "taiga",
    "name": "Taiga",
    "enabled": true,
    "protocol": "openid-connect",
    "publicClient": false,
    "standardFlowEnabled": true,
    "redirectUris": ["http://4.154.17.25:9001/*"],
    "webOrigins": ["http://4.154.17.25:9001"]
  }' && echo "Taiga client created"
```

### 6.2 Configure Taiga Backend

```bash
# Edit Taiga backend environment in docker-compose
# Add to taiga-back service environment:
cat >> ~/it-stack-labs/taiga/docker-compose.yml << 'EOF'
# Add to taiga-back environment:
# ENABLE_OPENID: "True"
# OPENID_CLIENT_ID: "taiga"
# OPENID_CLIENT_SECRET: "REPLACE_WITH_SECRET"
# OPENID_REALM: "it-stack"
# OPENID_BASE_URL: "http://4.154.17.25:8180/realms/it-stack"
EOF

# Restart taiga-back with new env
docker compose -f ~/it-stack-labs/taiga/docker-compose.yml up -d taiga-back-s01
```

---

## 7. OIDC Client: Zabbix

Zabbix 7.x supports SAML natively. OIDC is configured via HTTP SSO.

### 7.1 Register in Keycloak

```bash
curl -s -X POST "$KC_URL/admin/realms/it-stack/clients" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "zabbix",
    "name": "Zabbix",
    "enabled": true,
    "protocol": "openid-connect",
    "publicClient": true,
    "standardFlowEnabled": true,
    "redirectUris": ["http://4.154.17.25:8307/*"]
  }' && echo "Zabbix client created"
```

### 7.2 Configure Zabbix

In Zabbix Admin Console (**Administration** → **Authentication** → **SAML settings**):

| Field | Value |
|-------|-------|
| IdP entity ID | `http://4.154.17.25:8180/realms/it-stack` |
| SSO service URL | `http://4.154.17.25:8180/realms/it-stack/protocol/saml` |
| SLO URL | `http://4.154.17.25:8180/realms/it-stack/protocol/saml` |
| Username attribute | `username` |
| SP entity ID | `http://4.154.17.25:8307` |

---

## 8. OIDC Client: Odoo

### 8.1 Register in Keycloak

```bash
curl -s -X POST "$KC_URL/admin/realms/it-stack/clients" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "odoo",
    "name": "Odoo ERP",
    "enabled": true,
    "protocol": "openid-connect",
    "publicClient": false,
    "standardFlowEnabled": true,
    "redirectUris": ["http://4.154.17.25:8303/*"],
    "webOrigins": ["http://4.154.17.25:8303"]
  }' && echo "Odoo client created"
```

### 8.2 Configure Odoo

1. In Odoo: **Settings** → **Integrations** → **OAuth Providers** → **Create**
2. Fill in:
   | Field | Value |
   |-------|-------|
   | Provider name | IT-Stack SSO |
   | Client ID | `odoo` |
   | Allowed | ✅ |
   | Auth Flow | Authorization Code |
   | Authorization URL | `http://4.154.17.25:8180/realms/it-stack/protocol/openid-connect/auth` |
   | Scope | `openid email profile` |
   | Validation URL | `http://4.154.17.25:8180/realms/it-stack/protocol/openid-connect/userinfo` |
   | Data URL | (leave blank) |

---

## 9. SAML Client: SuiteCRM

SuiteCRM supports SAML 2.0 for SSO.

### 9.1 Register SAML Client in Keycloak

1. **Clients** → **Create client**
2. Client type: **SAML**
3. Client ID (Entity ID): `http://4.154.17.25:8302`
4. Valid redirect URIs: `http://4.154.17.25:8302/*`
5. **Save**
6. **Keys** tab → import SuiteCRM SP certificate (or generate new)

### 9.2 Configure SuiteCRM

In SuiteCRM Admin Panel (**Admin** → **SAML Authentication**):

| Field | Value |
|-------|-------|
| Enable SAML | Yes |
| IdP Entity ID | `http://4.154.17.25:8180/realms/it-stack` |
| IdP SSO URL | `http://4.154.17.25:8180/realms/it-stack/protocol/saml` |
| IdP SLO URL | `http://4.154.17.25:8180/realms/it-stack/protocol/saml` |
| IdP x509 Certificate | *(from Keycloak → Realm Settings → Keys → RS256 Certificate)* |
| SP Entity ID | `http://4.154.17.25:8302` |
| User attribute mapping | `email` → `email`, `first_name` → `given_name`, `last_name` → `family_name` |

---

## 10. SAML Client: Snipe-IT

### 10.1 Register in Keycloak

1. **Clients** → **Create client** → Type: **SAML**
2. Client ID: `http://4.154.17.25:8305`
3. Redirect URIs: `http://4.154.17.25:8305/*`

### 10.2 Configure Snipe-IT

In Snipe-IT (**Admin** → **Settings** → **SAML**):

| Field | Value |
|-------|-------|
| SAML enabled | Yes |
| IdP metadata URL | `http://4.154.17.25:8180/realms/it-stack/protocol/saml/descriptor` |
| SP entity ID | `http://4.154.17.25:8305` |
| ACS URL | `http://4.154.17.25:8305/saml/acs` |
| Attribute mapping: username | `username` |
| Attribute mapping: email | `email` |
| Attribute mapping: first_name | `given_name` |
| Attribute mapping: last_name | `family_name` |

---

## 11. User & Group Management

### Create Users via Keycloak API

```bash
# Bulk create users from CSV
while IFS=, read username email firstname lastname; do
  curl -s -X POST "$KC_URL/admin/realms/it-stack/users" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"username\": \"$username\",
      \"email\": \"$email\",
      \"firstName\": \"$firstname\",
      \"lastName\": \"$lastname\",
      \"enabled\": true,
      \"emailVerified\": true,
      \"credentials\": [{\"type\":\"password\",\"value\":\"TempPass01!\",\"temporary\":true}],
      \"groups\": [\"/all-users\"]
    }" && echo "Created user: $username"
done < users.csv
```

### Assign Realm Roles

```bash
# Make it-admins members Zabbix admins, Graylog admins, etc.
# Add role mapping in each service client under "it-stack" realm

# Example: add admin group to Nextcloud admin role
KC_CLIENT=$(curl -s "$KC_URL/admin/realms/it-stack/clients?clientId=nextcloud" \
  -H "Authorization: Bearer $TOKEN" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

# Create client role "nextcloud-admin"
curl -s -X POST "$KC_URL/admin/realms/it-stack/clients/$KC_CLIENT/roles" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"nextcloud-admin","description":"Nextcloud administrator"}'
```

---

## 12. Token & Session Configuration

Configured at **Realm Settings** → **Tokens** in the Keycloak Admin Console:

| Setting | Recommended Value | Reason |
|---------|-----------------|--------|
| Default signature algorithm | RS256 | Industry standard |
| Access token lifespan | 5 minutes | Short-lived = secure |
| Client login timeout | 5 minutes | Prevent stale flows |
| SSO session idle | 8 hours | Normal work day |
| SSO session max | 24 hours | Force daily re-auth |
| Offline session idle | 30 days | Remember me |
| Refresh token max reuse | 0 | Rotation on every use |

**Apply via API:**

```bash
curl -s -X PUT "$KC_URL/admin/realms/it-stack" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "defaultSignatureAlgorithm": "RS256",
    "accessTokenLifespan": 300,
    "accessCodeLifespan": 60,
    "ssoSessionIdleTimeout": 28800,
    "ssoSessionMaxLifespan": 86400,
    "offlineSessionIdleTimeout": 2592000,
    "refreshTokenMaxReuse": 0
  }' && echo "Token settings updated"
```

---

## 13. Troubleshooting

### OIDC Login Redirects to Error Page

```bash
# Check Keycloak logs for the error
docker logs keycloak-demo --tail 50 | grep -i "error\|invalid\|redirect"

# Common causes:
# 1. Redirect URI mismatch — check client Valid Redirect URIs includes exact URL
# 2. Client secret wrong — re-copy from Keycloak Credentials tab
# 3. Realm doesn't exist — confirm http://4.154.17.25:8180/realms/it-stack/.well-known/openid-configuration returns JSON
```

### Test OIDC Discovery Endpoint

```bash
curl -s http://4.154.17.25:8180/realms/it-stack/.well-known/openid-configuration \
  | python3 -m json.tool | head -20
```

Expected: JSON with `authorization_endpoint`, `token_endpoint`, `userinfo_endpoint`.

### Validate Token

```bash
# Get a test token
curl -s -X POST "http://localhost:8180/realms/it-stack/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=nextcloud&client_secret=SECRET&username=jsmith&password=ChangeMe01!" \
  | python3 -m json.tool
```

### SAML Metadata

```bash
# Get IdP metadata XML for SAML clients
curl -s http://4.154.17.25:8180/realms/it-stack/protocol/saml/descriptor | xmllint --format - 2>/dev/null | head -30
```

---

*IT-Stack Keycloak OIDC Configuration Guide · Version 1.0 · March 2026*
