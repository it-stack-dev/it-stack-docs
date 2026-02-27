# Security Policy

## Overview

IT-Stack deploys enterprise-critical services including identity management (FreeIPA, Keycloak), email, VoIP, databases, and business systems. Security is not an afterthought — it is a core requirement at every layer.

This document describes how to report security vulnerabilities, what we consider a security issue, and what to expect after you report one.

---

## Supported Versions

Security patches are applied to the **latest release** of each component repository. Older versions receive security fixes only for critical vulnerabilities (CVSS ≥ 9.0).

| Component | Supported Versions |
|-----------|-------------------|
| FreeIPA | Latest stable |
| Keycloak | Latest stable |
| PostgreSQL | 16.x (current), 15.x (security only) |
| Redis | 7.x |
| All other modules | Latest stable |

---

## Reporting a Vulnerability

**Please do NOT report security vulnerabilities through public GitHub Issues.**

### Private Disclosure

Report security vulnerabilities using one of these methods:

1. **GitHub Private Security Advisory** (preferred)
   - Navigate to the affected repository on GitHub
   - Go to **Security** → **Advisories** → **Report a vulnerability**
   - Fill in the advisory form

2. **Email**
   - Send details to the maintainers via the GitHub organization contact
   - Subject line: `[SECURITY] IT-Stack — {brief description}`
   - Encrypt with GPG if possible (public key available in the `.github` repo)

### What to Include

A useful security report includes:

```
Affected component:  e.g., it-stack-keycloak, it-stack-postgresql
Affected version:    e.g., 0.3.1 / latest main as of 2026-02-27
Severity estimate:   Critical / High / Medium / Low
CVSS score (if known): e.g., 8.5 (CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N)

Description:
  Clear description of the vulnerability.

Steps to reproduce:
  1. ...
  2. ...
  3. ...

Impact:
  What an attacker could achieve with this vulnerability.

Suggested fix (optional):
  If you have a patch or suggestion.
```

---

## Response Process

| Timeline | Action |
|----------|--------|
| **Within 48 hours** | Acknowledge receipt of the report |
| **Within 7 days** | Confirm whether the issue is valid and assign severity |
| **Within 14 days** | Provide a timeline for a fix (or explain why it won't be fixed) |
| **Within 90 days** | Release a patch (critical/high) or mitigation guidance |

We follow [coordinated disclosure](https://vuls.cert.org/confluence/display/CVD/Executive+Summary) — we ask that you give us time to release a fix before publishing details publicly. We will work with you on timing.

---

## Security Architecture

### Layers of Defense

```
Internet
   │
   ▼
Traefik (TLS termination, rate limiting, WAF headers)
   │
   ▼
Keycloak (OIDC/SAML SSO — all services authenticate here)
   │
   ▼
FreeIPA (LDAP/Kerberos — user identity and group policy)
   │
   ▼
Application Services (each isolated, principle of least privilege)
   │
   ▼
PostgreSQL / Redis / Elasticsearch (network-isolated, auth required)
```

### Security Controls in Place

| Control | Implementation |
|---------|---------------|
| Identity | FreeIPA (Kerberos + LDAP), Keycloak (OIDC + SAML) |
| Transport encryption | TLS 1.2+ enforced everywhere via Traefik |
| Secrets management | Ansible Vault — secrets never stored in git |
| Network isolation | Per-service firewall rules, no unnecessary port exposure |
| Container security | Trivy image scanning in CI/CD pipeline |
| Authentication | SSO required for all user-facing services |
| Audit logging | Graylog centralized log aggregation |
| Alerting | Zabbix + Graylog alert on suspicious activity |

---

## Security Best Practices for Deployers

When deploying IT-Stack in your environment:

### Secrets

- **Never** commit secrets to git — use Ansible Vault for all credentials
- Rotate the default Keycloak admin password immediately after first login
- Generate unique PostgreSQL passwords per service (don't reuse `service123`)
- Disable default/demo accounts in all services

### Network

- Place all servers on an isolated VLAN (`10.0.50.0/24` in reference architecture)
- Restrict external access — only Traefik (ports 80/443) should face the internet
- Use internal DNS (FreeIPA) — don't expose service ports directly
- Enable `ufw` on all nodes: only allow necessary ports

### TLS

- Use valid certificates (Let's Encrypt via Traefik ACME, or your CA)
- Do not use self-signed certs in production (acceptable for lab labs only)
- Enforce `HSTS` headers via Traefik middleware

### Updates

- Keep all services updated — track upstream security advisories
- Subscribe to upstream security mailing lists for all 20 components
- Apply OS security patches monthly (`unattended-upgrades` on Ubuntu)

### Keycloak Hardening

- Enable brute-force protection (Keycloak realm settings)
- Require MFA (TOTP) for privileged accounts
- Set appropriate token lifetimes (access: 5 min, refresh: 30 min)
- Audit realm event logging

### PostgreSQL Hardening

- `pg_hba.conf`: restrict to specific IPs, require `scram-sha-256`
- Create per-service database users with minimal permissions
- Enable `pg_audit` for sensitive databases

---

## Known Limitations

- FreePBX's web interface uses authentication but is less hardened than modern applications — restrict to internal network
- iRedMail's default spam filter configuration may need tuning for your environment
- Lab compose files (`docker-compose.standalone.yml`) use default/example credentials — **never use in production**

---

## Vulnerability Disclosure Policy

We commit to:

1. Acknowledging your report within 48 hours
2. Keeping you informed of progress
3. Crediting you in the security advisory (unless you prefer anonymity)
4. Not pursuing legal action against researchers acting in good faith

We ask that you:

1. Give us reasonable time to fix before public disclosure (90 days max)
2. Make a good-faith effort to avoid data loss, service disruption, or access to others' data
3. Do not use the vulnerability beyond what is needed to demonstrate the issue

---

## Security Hall of Fame

We maintain a list of security researchers who have responsibly disclosed vulnerabilities. Thank you for helping keep IT-Stack secure.

*(No entries yet — be the first!)*
