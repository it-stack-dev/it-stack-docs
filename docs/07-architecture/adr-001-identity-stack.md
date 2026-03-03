# ADR-001: Use FreeIPA + Keycloak for Identity and SSO

**Status:** Accepted  
**Date:** 2026-02-27  
**Deciders:** IT-Stack Architecture Team  

---

## Context

Every enterprise service — email, file sharing, chat, ticketing, ERP, CRM — requires user authentication and authorization. Without a centralized identity layer, each service maintains its own user database, creating:

- Separate passwords per service (poor UX and security)
- No unified account lifecycle (onboarding / offboarding must be repeated per service)
- No group-based access control across services
- No single sign-on (users must log in repeatedly)

IT-Stack serves 50–1,000+ users across 20 services. A robust, open-source identity layer is the most critical architectural decision.

### Requirements

| Requirement | Details |
|-------------|---------|
| Central user directory | One source of truth for all user accounts and groups |
| Kerberos for internal auth | Service-to-service authentication without passwords |
| DNS integration | Internal DNS propagated with service hostnames |
| Modern SSO protocols | OAuth2, OIDC, and SAML for web application federation |
| Certificate authority | Internal PKI for TLS on the LAN |
| Protocol bridging | LDAP directory + modern token-based auth in one stack |

---

## Decision

**Use FreeIPA as the identity provider and directory, with Keycloak as the SSO broker.**

### Component Roles

#### FreeIPA (`lab-id1`, 10.0.50.11)
- **LDAP directory** — canonical user and group store (389-ds)
- **Kerberos KDC** — ticket-based authentication for Linux hosts and services
- **DNS server** — internal DNS zone `it-stack.lab` with A/PTR records for all servers
- **Certificate authority** — signs certificates for all internal services via Dogtag PKI
- **Host enrollment** — manages `/etc/krb5.conf`, SSH keytabs, and sudo rules for all 8 servers

#### Keycloak (`lab-id1`, port 8443)
- **SSO broker** — federates identity from FreeIPA LDAP into OAuth2/OIDC/SAML tokens
- **Application realm** — `it-stack` realm with one client per service
- **Protocol translation** — older apps use SAML; modern apps use OIDC
- **Group mapping** — FreeIPA groups (`admins`, `users`, `voip`, `finance`) → Keycloak roles
- **MFA enforcement** — TOTP optional per realm policy
- **Token storage** — JWT access tokens; Redis used for session cache (via Keycloak SPI)

### Identity Flow

```
User → Browser → Service → Keycloak (OIDC/SAML) → FreeIPA LDAP → Kerberos ticket
                                 ↑
                         Token issued to service
                         (contains user + groups)
```

### Service-to-Protocol Mapping

| Service | Protocol | Realm Client ID |
|---------|----------|----------------|
| Nextcloud | OIDC | `nextcloud` |
| Mattermost | OIDC | `mattermost` |
| Jitsi | OIDC | `jitsi` |
| Zammad | OIDC | `zammad` |
| Odoo | OIDC | `odoo` |
| Taiga | OIDC | `taiga` |
| SuiteCRM | SAML 2.0 | `suitecrm` |
| GLPI | SAML 2.0 | `glpi` |
| Snipe-IT | SAML 2.0 | `snipeit` |

---

## Consequences

### Positive
- **Single password** — one user account works across all 20 services
- **Instant deprovisioning** — disable FreeIPA account, access revoked everywhere in seconds
- **Group-based access** — `finance` group gets Odoo + SuiteCRM; `ops` group gets Zabbix + GLPI
- **No vendor lock-in** — FreeIPA (Red Hat sponsored) and Keycloak (CNCF) are both open-source
- **Kerberos SSO on Linux** — desktops on the domain get automatic Kerberos tickets
- **Internal PKI** — no need to purchase or manage external certificate authorities internally

### Negative / Trade-offs
- **Complexity** — two services to maintain instead of one; LDAP federation must be kept in sync
- **Startup dependency** — all other services depend on Keycloak being up; Phase 1 must complete before Phase 2/3/4
- **FreeIPA requires dedicated host** — IPA server owns DNS; running it in Docker is unsupported; bare-metal or VM required for production
- **Keycloak memory** — requires Java 17, minimum 2 GB RAM in production (4 GB recommended)
- **LDAP schema changes** — adding custom FreeIPA attributes requires schema extensions

---

## Alternatives Considered

### OpenLDAP + Authentik
- OpenLDAP is standalone LDAP without Kerberos, DNS, or PKI — requires separate tooling for all three
- Authentik is modern but less mature for large enterprise SAML scenarios
- **Rejected:** FreeIPA provides more in one package; Keycloak has broader service support

### Active Directory (Samba)
- Samba 4 implements AD DS compatibility, including Kerberos and Group Policy
- More familiar to Windows-centric teams
- **Rejected:** FreeIPA is more Linux-native; Samba AD integration adds complexity without benefit for an all-Linux stack

### Keycloak-only (no LDAP)
- Keycloak has a built-in user database
- Loses Kerberos (Linux desktop auth), internal DNS, and PKI integration
- **Rejected:** FreeIPA capabilities are essential for the full enterprise stack

---

## References

- [FreeIPA Documentation](https://www.freeipa.org/page/Documentation)
- [Keycloak Server Documentation](https://www.keycloak.org/documentation)
- [it-stack-freeipa repo](https://github.com/it-stack-dev/it-stack-freeipa)
- [it-stack-keycloak repo](https://github.com/it-stack-dev/it-stack-keycloak)
- [Integration Guide — SSO Federations](../02-implementation/12-integration-guide.md)
