---
doc: "01-core-01"
title: "Identity & Authentication — FreeIPA + Keycloak"
category: identity
phase: 1
servers: [lab-id1]
date: 2026-02-27
---

# Identity & Authentication

> **Category:** Identity & Security — Layer 1  
> **Phase:** 1 (Foundation)  
> **Servers:** `lab-id1` (10.0.50.11, 16 GB RAM)  
> **Modules:** FreeIPA (01) · Keycloak (02)

---

## Overview

The identity layer is the foundation of IT-Stack. Every other service authenticates against it.
The two-component design separates **directory services** (FreeIPA) from **application SSO** (Keycloak),
giving you LDAP/Kerberos for infrastructure and OAuth2/OIDC/SAML for web applications.

```
Users → Keycloak (OAuth2/OIDC/SAML) → FreeIPA (LDAP/Kerberos)
                                              ↑
                          DNS · NTP · PKI · sudo rules · host enrollment
```

---

## Module 01: FreeIPA

**Repo:** [it-stack-freeipa](https://github.com/it-stack-dev/it-stack-freeipa)  
**Image:** FreeIPA Server on Rocky Linux 9  
**Ports:** 389 (LDAP), 636 (LDAPS), 88 (Kerberos), 464 (kpasswd), 53 (DNS), 80/443 (Web UI)

### Responsibilities

| Function | Detail |
|----------|--------|
| LDAP directory | Central user/group store for all 20 services |
| Kerberos KDC | SSO tickets for SSH, NFS, and internal services |
| DNS server | Internal DNS for `internal.example.com` domain |
| PKI / CA | Issues TLS certificates for all servers |
| sudo rules | Centralized privilege management |
| Host enrollment | All 8 servers joined to the IPA domain |

### Key Configuration

```ini
# IPA domain
IPA_DOMAIN=internal.example.com
IPA_REALM=INTERNAL.EXAMPLE.COM
IPA_SERVER=lab-id1.internal.example.com
IPA_ADMIN_PASSWORD=<vault>
IPA_DS_PASSWORD=<vault>
```

### LDAP Schema

| OU | Purpose |
|----|---------|
| `ou=people` | All user accounts |
| `ou=groups` | Posix groups (it-admins, it-users, service-accounts) |
| `ou=services` | Service principals (HTTP, LDAP, kadmin) |
| `cn=sudo` | Sudo rules by group |
| `cn=hbac` | Host-based access control rules |

---

## Module 02: Keycloak

**Repo:** [it-stack-keycloak](https://github.com/it-stack-dev/it-stack-keycloak)  
**Image:** `quay.io/keycloak/keycloak:24`  
**Ports:** 8080 (HTTP), 8443 (HTTPS)

### Responsibilities

| Function | Detail |
|----------|--------|
| OAuth2 / OIDC broker | Issues JWT tokens to all web applications |
| SAML IdP | For applications that require SAML 2.0 |
| LDAP federation | Reads users/groups from FreeIPA in real-time |
| MFA | TOTP and WebAuthn support |
| Admin console | Self-service password reset, user management |

### Realms

| Realm | Purpose |
|-------|---------|
| `master` | Keycloak admin only — never use for apps |
| `it-stack` | All production users and service clients |

### OIDC Clients (SSO integrations)

| Client ID | Application | Protocol |
|----------|-------------|----------|
| `nextcloud` | Nextcloud | OIDC |
| `mattermost` | Mattermost | OIDC |
| `jitsi` | Jitsi | OIDC |
| `odoo` | Odoo | OIDC |
| `zammad` | Zammad | OIDC |
| `taiga` | Taiga | OIDC |
| `suitecrm` | SuiteCRM | SAML |
| `glpi` | GLPI | SAML |
| `snipeit` | Snipe-IT | SAML |

---

## Integration: FreeIPA → Keycloak LDAP Federation

```
Keycloak realm: it-stack
  └── User federation: FreeIPA LDAP
        ├── Connection URL: ldap://lab-id1:389
        ├── Bind DN: uid=keycloak-svc,cn=users,cn=accounts,dc=internal,dc=example,dc=com
        ├── User search base: cn=users,cn=accounts,dc=internal,dc=example,dc=com
        ├── Group search base: cn=groups,cn=accounts,dc=internal,dc=example,dc=com
        └── Sync: periodic full sync every 1h, changed users every 10m
```

---

## Lab Progression

| Lab | Name | Key Task |
|-----|------|----------|
| 01-01 | Standalone | FreeIPA install, first user created |
| 01-02 | External Dependencies | DNS integration, other servers enrolled |
| 01-03 | Advanced Features | Sudo rules, HBAC, PKI certificates |
| 01-04 | SSO Integration | Keycloak LDAP federation configured |
| 01-05 | Advanced Integration | All Phase 1 services authenticating |
| 01-06 | Production Deployment | HA replica IPA server, monitoring |
| 02-01 | Standalone | Keycloak standalone with dev realm |
| 02-04 | SSO Integration | FreeIPA federation, all OIDC clients |

---

## Security Notes

- FreeIPA admin password and DS password in Ansible Vault
- LDAPS (port 636) required in production — disable plain LDAP
- Kerberos keytabs for service accounts stored in `/etc/krb5.keytab` on each server
- Keycloak admin console access restricted to `lab-id1` subnet
- All Keycloak client secrets rotated quarterly via Ansible playbook
