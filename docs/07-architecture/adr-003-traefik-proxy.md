# ADR-003: Traefik as Reverse Proxy with Automatic TLS

**Status:** Accepted  
**Date:** 2026-02-27  
**Deciders:** IT-Stack Architecture Team  

---

## Context

IT-Stack runs 20 services across 8 servers. Users reach each service via a browser or API client. Without a reverse proxy:

- Every service would need its own TLS certificate management
- Services would need to be reachable on non-standard ports (`:8069`, `:3000`, `:8065`, etc.)
- No unified access logging or rate limiting
- No central routing rules — clients must know which server hosts which service

### Subdomain Design

Each service gets its own FQDN under the domain `it-stack.lab`:

| Subdomain | Service | Backend |
|-----------|---------|---------|
| `cloud.it-stack.lab` | Nextcloud | lab-app1:80 |
| `chat.it-stack.lab` | Mattermost | lab-app1:8065 |
| `meet.it-stack.lab` | Jitsi | lab-app1:443 |
| `mail.it-stack.lab` | iRedMail webmail | lab-comm1:443 |
| `desk.it-stack.lab` | Zammad | lab-comm1:3000 |
| `crm.it-stack.lab` | SuiteCRM | lab-biz1:80 |
| `erp.it-stack.lab` | Odoo | lab-biz1:8069 |
| `dms.it-stack.lab` | OpenKM | lab-biz1:8080 |
| `pm.it-stack.lab` | Taiga | lab-mgmt1:80 |
| `assets.it-stack.lab` | Snipe-IT | lab-mgmt1:80 |
| `itsm.it-stack.lab` | GLPI | lab-mgmt1:80 |
| `sso.it-stack.lab` | Keycloak | lab-id1:8443 |
| `ipa.it-stack.lab` | FreeIPA | lab-id1:443 |
| `logs.it-stack.lab` | Graylog | lab-proxy1:9000 |
| `proxy.it-stack.lab` | Traefik dashboard | lab-proxy1:8080 |

---

## Decision

**Deploy Traefik v3 on `lab-proxy1` (10.0.50.15) as the single inbound TLS termination and routing layer.**

### Architecture

```
Internet / LAN
      │
      ▼
lab-proxy1 (10.0.50.15)
  :80  → redirect to :443
  :443 → Traefik TLS termination
      │
      ├── cloud.it-stack.lab  → lab-app1:80
      ├── chat.it-stack.lab   → lab-app1:8065
      ├── meet.it-stack.lab   → lab-app1:443 (passthrough)
      ├── desk.it-stack.lab   → lab-comm1:3000
      ├── crm.it-stack.lab    → lab-biz1:80
      ├── erp.it-stack.lab    → lab-biz1:8069
      └── ...
```

### TLS Strategy

| Environment | TLS Source | Method |
|-------------|-----------|--------|
| Lab / LAN | FreeIPA internal CA | Traefik `file` provider with imported certs |
| Production with public DNS | Let's Encrypt | Traefik ACME with `tlsChallenge` or `dnsChallenge` |
| Production air-gapped | Internal CA | Same as Lab |

### Configuration via Labels (Docker) or Files (bare-metal)

In Lab environments, Traefik reads router rules from static files in `/etc/traefik/conf.d/`. In Docker lab setups, services are discovered via Docker labels on containers.

### Key Traefik Features Used

| Feature | Configuration |
|---------|--------------|
| HTTP→HTTPS redirect | `entryPoints.web.http.redirections` |
| TLS termination | `entryPoints.websecure.address: ":443"` |
| Dashboard | `api.dashboard: true` (protected by BasicAuth middleware) |
| Access logging | `/var/log/traefik/access.log` (JSON format → Graylog) |
| Healthchecks | `ping.entryPoint: traefik` on `:8082` |
| Middlewares | `compress`, `rateLimit`, `secureHeaders` |

---

## Consequences

### Positive
- **One TLS certificate store** — cert renewal runs once and covers all subdomains
- **Clean URLs** — `https://chat.it-stack.lab` instead of `http://lab-app1:8065`
- **Centralized access log** — all service access in one log stream, ingested by Graylog
- **Zero-downtime updates** — Traefik reroutes traffic gracefully during backend restarts
- **Docker-native** — in lab environments, containers self-register via labels; no manual routing
- **Let's Encrypt integration** — automatic cert issuance and renewal for public deployments

### Negative / Trade-offs
- **Proxy is a critical path** — if `lab-proxy1` goes down, all web-based services become unreachable
  - Mitigation: Traefik is stateless; restart is sub-second; HAProxy could be added in active-passive for Phase 6
- **WebSocket support required** — Mattermost and Jitsi use WebSockets; Traefik handles this by default but must be verified per service
- **IP passthrough for VoIP** — FreePBX (SIP/RTP) bypasses Traefik entirely; VoIP traffic routes directly to `lab-pbx1`
- **Jitsi HTTPS passthrough** — Jitsi handles its own TLS for DTLS-SRTP; Traefik must use TCP passthrough or SNI routing for meet.it-stack.lab

---

## Alternatives Considered

### Nginx (as reverse proxy)
- Mature, well-understood; excellent documentation
- TLS certificate renewals require cron + certbot + nginx reload (not automatic)
- No built-in service discovery from Docker labels
- **Rejected:** Traefik's automatic Let's Encrypt and Docker-native service discovery reduce operational overhead substantially

### Caddy
- Also offers automatic Let's Encrypt; simpler configuration syntax
- Less mature Docker label-based service discovery than Traefik
- Smaller community for enterprise edge cases (Jitsi passthrough, WebSocket quirks)
- **Rejected:** Traefik has larger enterprise adoption and more IT-Stack-relevant documentation

### HAProxy
- Extremely high performance; battle-tested at massive scale
- No built-in Let's Encrypt; complex ACL syntax for many services
- **Rejected:** appropriate for Phase 6 active-passive HA in front of Traefik, not as primary proxy

---

## References

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [it-stack-traefik repo](https://github.com/it-stack-dev/it-stack-traefik)
- [Ansible role: traefik](../../it-stack-dev/repos/meta/it-stack-ansible/roles/traefik/)
- [Network topology](network-topology.md)
