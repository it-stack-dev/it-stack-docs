# IT-Stack Service Integration Map

> This document maps all cross-service integrations in IT-Stack.  
> For implementation procedures see [Integration Guide](../02-implementation/12-integration-guide.md).

---

## Integration Overview

IT-Stack's 20 services form a connected ecosystem. Every service depends on the identity layer (FreeIPA + Keycloak) and most depend on the database tier (PostgreSQL + Redis). Beyond those foundations, there are 22 documented cross-service integrations.

| Integration Type | Count | Examples |
|-----------------|-------|---------|
| Identity (SSO) | 9 | All web apps → Keycloak OIDC/SAML |
| Database | 10 | All stateful apps → PostgreSQL |
| Business data sync | 6 | Odoo ↔ SuiteCRM, Snipe-IT ↔ GLPI |
| Notifications/webhooks | 4 | Zabbix → Mattermost, Taiga → Mattermost |
| Communication integration | 3 | FreePBX ↔ SuiteCRM, FreePBX ↔ Zammad |
| Observability | 2 | Graylog ↔ Zabbix |

---

## Integration Diagram

```mermaid
graph TD
  %% Identity layer
  FIP["FreeIPA\nLDAP / Kerberos"]
  KC["Keycloak\nSSO Broker"]

  %% Database layer
  PG["PostgreSQL\nPrimary DB"]
  RD["Redis\nCache / Sessions"]
  ES["Elasticsearch\nSearch / Logs"]

  %% Collaboration
  NC["Nextcloud\nFiles / Calendar"]
  MM["Mattermost\nTeam Chat"]
  JT["Jitsi\nVideo"]

  %% Communications
  IM["iRedMail\nEmail"]
  PBX["FreePBX\nVoIP / PBX"]
  ZM["Zammad\nHelp Desk"]

  %% Business
  CRM["SuiteCRM\nCRM"]
  OD["Odoo\nERP"]
  KM["OpenKM\nDMS"]

  %% IT Management
  TG["Taiga\nProjects"]
  SN["Snipe-IT\nAssets"]
  GP["GLPI\nITSM"]

  %% Infrastructure
  TR["Traefik\nProxy / TLS"]
  ZB["Zabbix\nMonitoring"]
  GR["Graylog\nLog Mgmt"]

  %% ─── Identity flows ───────────────────────────────────────────
  FIP -->|"LDAP federation"| KC
  KC  -->|"OIDC"| NC
  KC  -->|"OIDC"| MM
  KC  -->|"OIDC"| JT
  KC  -->|"OIDC"| ZM
  KC  -->|"OIDC"| OD
  KC  -->|"OIDC"| TG
  KC  -->|"SAML"| CRM
  KC  -->|"SAML"| GP
  KC  -->|"SAML"| SN

  %% ─── Database flows ───────────────────────────────────────────
  PG  -->|"DB"| NC
  PG  -->|"DB"| MM
  PG  -->|"DB"| ZM
  PG  -->|"DB"| CRM
  PG  -->|"DB"| OD
  PG  -->|"DB"| KM
  PG  -->|"DB"| TG
  PG  -->|"DB"| SN
  PG  -->|"DB"| GP
  PG  -->|"DB"| KC
  RD  -->|"cache/sessions"| NC & MM & ZM & KC
  ES  -->|"full-text search"| ZM
  ES  -->|"log storage"| GR

  %% ─── Business integrations ────────────────────────────────────
  PBX  -->|"CTI click-to-call\nREST API"| CRM
  PBX  -->|"auto-create ticket\nwebhook"| ZM
  PBX  -->|"extension provisioning\nLDAP"| FIP
  CRM  -->|"customer sync\nREST API"| OD
  CRM  -->|"CalDAV calendar sync"| NC
  CRM  -->|"document linking\nREST API"| KM
  OD   -->|"employee sync\nLDAP"| FIP
  OD   -->|"time entry export\nAPI"| TG
  OD   -->|"asset procurement\nREST API"| SN
  SN   -->|"asset sync\nREST API"| GP
  GP   -->|"ticket escalation\nREST API"| ZM
  KM   -->|"document store\nREST API"| NC

  %% ─── Notifications ────────────────────────────────────────────
  TG   -->|"project events\nwebhook"| MM
  ZB   -->|"infra alerts\nwebhook"| MM
  GR   -->|"log alerts\nsyslog stream"| ZB

  %% ─── Observability ────────────────────────────────────────────
  TR   -->|"access logs\nJSON → Syslog"| GR
  ZB   -->|"monitors all servers\nSNMP/Zabbix agent"| FIP & PG & NC & MM & TR

  %% ─── Ingress ──────────────────────────────────────────────────
  TR  -->|"HTTPS routing"| NC & MM & JT & ZM & CRM & OD & KM & TG & SN & GP

  %% Styles
  classDef identity   fill:#dbeafe,stroke:#2563eb,color:#1e3a8a
  classDef database   fill:#dcfce7,stroke:#16a34a,color:#14532d
  classDef collab     fill:#fef9c3,stroke:#ca8a04,color:#713f12
  classDef comms      fill:#ffe4e6,stroke:#e11d48,color:#881337
  classDef business   fill:#f0fdf4,stroke:#15803d,color:#14532d
  classDef mgmt       fill:#e0f2fe,stroke:#0284c7,color:#0c4a6e
  classDef infra      fill:#f3e8ff,stroke:#9333ea,color:#581c87

  class FIP,KC identity
  class PG,RD,ES database
  class NC,MM,JT collab
  class IM,PBX,ZM comms
  class CRM,OD,KM business
  class TG,SN,GP mgmt
  class TR,ZB,GR infra
```

---

## Integration Details

### Layer 1: Identity (FreeIPA + Keycloak)

All web services authenticate via Keycloak, which federates from FreeIPA LDAP.

| Integration | Protocol | Direction | Notes |
|-------------|----------|-----------|-------|
| FreeIPA → Keycloak | LDAP (read-only federation) | FreeIPA is source of truth | Group sync every 5 min |
| Keycloak → Nextcloud | OIDC | Keycloak is IdP | `nextcloud` client; groups mapped to admin/users |
| Keycloak → Mattermost | OIDC | Keycloak is IdP | `mattermost` client; SSO + group sync |
| Keycloak → Jitsi | OIDC / JWT | Keycloak is IdP | JWT tokens for room auth |
| Keycloak → Zammad | OIDC | Keycloak is IdP | `zammad` client; maps roles to agent/customer |
| Keycloak → Odoo | OIDC | Keycloak is IdP | `odoo` client; employee groups |
| Keycloak → Taiga | OIDC | Keycloak is IdP | `taiga` client; maps to project roles |
| Keycloak → SuiteCRM | SAML 2.0 | Keycloak is IdP | `suitecrm` client; SAML assertion with role attribute |
| Keycloak → GLPI | SAML 2.0 | Keycloak is IdP | `glpi` client; tech/admin roles |
| Keycloak → Snipe-IT | SAML 2.0 | Keycloak is IdP | `snipeit` client; admin/user roles |
| FreePBX → FreeIPA | LDAP | FreeIPA is directory | Extension-to-user mapping; voicemail auth |
| Odoo → FreeIPA | LDAP | FreeIPA is directory | Employee directory sync; `uid` attribute |

### Layer 2: Database (PostgreSQL + Redis + Elasticsearch)

| Service | Database | Schema Owner | Session/Cache |
|---------|----------|-------------|--------------|
| Keycloak | `keycloak` | `keycloak_user` | Redis (session tokens) |
| Nextcloud | `nextcloud` | `nextcloud_user` | Redis (file lock cache) |
| Mattermost | `mattermost` | `mattermost_user` | Redis (job queue) |
| Zammad | `zammad` | `zammad_user` | Redis + ES (full-text search) |
| SuiteCRM | `suitecrm` | `suitecrm_user` | — |
| Odoo | `odoo` | `odoo_user` | — |
| OpenKM | `openkm` | `openkm_user` | — |
| Taiga | `taiga` | `taiga_user` | Redis (async tasks) |
| Snipe-IT | `snipeit` | `snipeit_user` | — |
| GLPI | `glpi` | `glpi_user` | — |

### Layer 3: Business Integrations

| Integration | Method | Data Synced | Trigger |
|-------------|--------|------------|---------|
| FreePBX → SuiteCRM | CTI / REST API | Call logs, caller ID → contact lookup | Incoming call |
| FreePBX → Zammad | Webhook (AMI event) | Auto-create ticket on missed/incoming call | Call end event |
| CRM → Odoo | REST API (bidirectional) | Customer = Contact in Odoo; invoice updates CRM | Scheduled + on save |
| CRM → Nextcloud | CalDAV | Contact meetings → Nextcloud calendar | On meeting create |
| CRM → OpenKM | REST API | Quote/contract PDFs linked to CRM records | On document attach |
| Odoo → Taiga | REST API | Billable hours from Taiga timesheets → Odoo invoicing | Daily batch |
| Odoo → Snipe-IT | REST API | Purchase orders create assets in Snipe-IT | On PO approval |
| Snipe-IT → GLPI | REST API | Asset checkout/checkin syncs CMDB | On asset change |
| GLPI → Zammad | REST API | Major incident in GLPI escalates to Zammad ticket | On GLPI alert |
| OpenKM → Nextcloud | REST API / WebDAV | Approved documents published to Nextcloud | On document approve |

### Layer 4: Notifications and Observability

| Integration | Method | Channel | Notes |
|-------------|--------|---------|-------|
| Taiga → Mattermost | Webhook | `#dev-notifications` | Issue created, sprint started, deployment |
| Zabbix → Mattermost | Webhook (Zabbix media type) | `#ops-alerts` | Problem, recovery, ack events |
| Graylog → Zabbix | Syslog stream | Zabbix log item | Graylog alerts trigger Zabbix problem |
| Traefik → Graylog | Access log (JSON → GELF/Syslog) | Graylog stream "web-access" | All HTTP/HTTPS requests |

---

## Dependency Graph (Startup Order)

Services must be started in dependency order. This is enforced by Ansible tags and the `deploy-stack.sh` script.

```
Phase 0 (networking):  FreeIPA DNS must resolve before anything else
Phase 1a:  PostgreSQL, Redis
Phase 1b:  Keycloak (needs PostgreSQL + FreeIPA)
Phase 1c:  Traefik (needs DNS but not application services)
Phase 2a:  Nextcloud, Mattermost, Jitsi (need PG + Redis + Keycloak)
Phase 2b:  iRedMail (independent; needs DNS only)
Phase 2c:  Zammad (needs PG + ES + Keycloak)
Phase 3a:  Elasticsearch (Phase 4 only; Zammad can use PG FTS in Phase 2)
Phase 3b:  FreePBX (needs FreeIPA LDAP; independent of web services)
Phase 3c:  SuiteCRM, Odoo, OpenKM (need PG + Keycloak)
Phase 4a:  Taiga, Snipe-IT, GLPI (need PG + Keycloak)
Phase 4b:  Zabbix (needs all services running to monitor them)
Phase 4c:  Graylog (needs ES; collects logs from Traefik and all other services)
```

---

## References

- [ADR-001: Identity Stack](adr-001-identity-stack.md)
- [ADR-002: PostgreSQL Primary](adr-002-postgresql-primary.md)
- [ADR-003: Traefik Proxy](adr-003-traefik-proxy.md)
- [ADR-006: 8-Server Layout](adr-006-8server-layout.md)
- [Implementation: Integration Guide](../02-implementation/12-integration-guide.md)
- [Network Topology](network-topology.md)
