#!/usr/bin/env pwsh
# create-category-specs.ps1
# Creates docs/01-core/ category specification documents for all 7 IT-Stack categories.

$docs = "C:\IT-Stack\docs\01-core"
$null = New-Item -ItemType Directory -Path $docs -Force

# ── 01. Identity & Authentication ─────────────────────────────────────────────
Set-Content "$docs\01-identity.md" -Encoding UTF8 @'
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
'@
Write-Host "[OK] docs/01-core/01-identity.md" -ForegroundColor Green

# ── 02. Database & Cache ───────────────────────────────────────────────────────
Set-Content "$docs\02-database.md" -Encoding UTF8 @'
---
doc: "01-core-02"
title: "Database & Cache — PostgreSQL + Redis + Elasticsearch"
category: database
phase: 1 (PostgreSQL, Redis) / 4 (Elasticsearch)
servers: [lab-db1]
date: 2026-02-27
---

# Database & Cache

> **Category:** Database & Cache — Layer 2  
> **Servers:** `lab-db1` (10.0.50.12, 32 GB RAM)  
> **Modules:** PostgreSQL (03) · Redis (04) · Elasticsearch (05)

---

## Overview

All stateful data lives on `lab-db1`. Every application service connects here for its primary database,
caching layer, and search/log index. Centralizing storage on one high-memory server simplifies backup,
monitoring, and disaster recovery.

---

## Module 03: PostgreSQL

**Repo:** [it-stack-postgresql](https://github.com/it-stack-dev/it-stack-postgresql)  
**Version:** PostgreSQL 16.x  
**Port:** 5432

### Service Databases

| Database | Owner | Used By |
|----------|-------|---------|
| `keycloak` | keycloak | Keycloak SSO |
| `nextcloud` | nextcloud | Nextcloud files/calendar |
| `mattermost` | mattermost | Mattermost chat |
| `zammad` | zammad | Zammad help desk |
| `suitecrm` | suitecrm | SuiteCRM CRM |
| `odoo` | odoo | Odoo ERP |
| `openkm` | openkm | OpenKM DMS |
| `taiga` | taiga | Taiga project management |
| `snipeit` | snipeit | Snipe-IT assets |
| `glpi` | glpi | GLPI ITSM |
| `zabbix` | zabbix | Zabbix monitoring |

### Access Control (`pg_hba.conf`)

```
# All app servers connect via md5 from the 10.0.50.0/24 subnet
host    all    all    10.0.50.0/24    scram-sha-256
# Replication
host    replication    replicator    10.0.50.12/32    scram-sha-256
```

### Backup Strategy

```bash
# Daily pg_dumpall via cron (04:00 UTC)
pg_dumpall -U postgres | gzip > /backups/pg-$(date +%Y%m%d).sql.gz
# Retention: 30 daily, 12 weekly, 6 monthly
```

---

## Module 04: Redis

**Repo:** [it-stack-redis](https://github.com/it-stack-dev/it-stack-redis)  
**Version:** Redis 7.x  
**Port:** 6379

### Usage by Service

| Service | Redis Use |
|---------|-----------|
| Nextcloud | File locking, session cache |
| Mattermost | Session store, rate limiting |
| Zammad | Job queues (Sidekiq) |
| Taiga | Async task queue (Celery) |
| Keycloak | Session sticky cache (optional) |

### Configuration

```
maxmemory 4gb
maxmemory-policy allkeys-lru
requirepass <vault>
bind 10.0.50.12
```

---

## Module 05: Elasticsearch

**Repo:** [it-stack-elasticsearch](https://github.com/it-stack-dev/it-stack-elasticsearch)  
**Version:** Elasticsearch 8.x  
**Ports:** 9200 (HTTP), 9300 (transport)  
**Phase:** 4

### Usage by Service

| Service | Elasticsearch Index | Purpose |
|---------|---------------------|---------|
| Zammad | `zammad-*` | Full-text ticket search |
| Graylog | `graylog_*` | Log storage and search |
| Mattermost | `mattermost_*` (optional) | Message search |

### JVM Configuration

```
-Xms8g -Xmx8g   # Set to half of lab-db1 RAM
```

---

## Lab Progression

| Lab | Module | Key Task |
|-----|--------|----------|
| 03-01 | PostgreSQL | Standalone, create all 11 databases |
| 03-02 | PostgreSQL | Remote access from app servers |
| 03-04 | PostgreSQL | FreeIPA LDAP auth for DB users |
| 04-01 | Redis | Standalone, verify keyspace |
| 04-02 | Redis | Nextcloud + Mattermost connecting |
| 05-01 | Elasticsearch | Standalone, verify cluster health |
| 05-02 | Elasticsearch | Graylog + Zammad indexing |
'@
Write-Host "[OK] docs/01-core/02-database.md" -ForegroundColor Green

# ── 03. Collaboration ──────────────────────────────────────────────────────────
Set-Content "$docs\03-collaboration.md" -Encoding UTF8 @'
---
doc: "01-core-03"
title: "Collaboration — Nextcloud + Mattermost + Jitsi"
category: collaboration
phase: 2
servers: [lab-app1]
date: 2026-02-27
---

# Collaboration

> **Category:** Collaboration — Layer 3  
> **Phase:** 2  
> **Servers:** `lab-app1` (10.0.50.13, 24 GB RAM)  
> **Modules:** Nextcloud (06) · Mattermost (07) · Jitsi (08)

---

## Overview

The collaboration layer replaces Microsoft 365, Slack/Teams, and Zoom in a single server.
All three services authenticate via Keycloak OIDC and store data in PostgreSQL on `lab-db1`.

---

## Module 06: Nextcloud

**Repo:** [it-stack-nextcloud](https://github.com/it-stack-dev/it-stack-nextcloud)  
**Port:** 443 (via Traefik) · **Subdomain:** `cloud.example.com`  
**Replaces:** Microsoft 365 (OneDrive, SharePoint, Calendar, Contacts, Office Online)

### Features Used in IT-Stack

| Feature | Detail |
|---------|--------|
| Files | Self-hosted file sync for all users |
| Calendar / Contacts | CalDAV/CardDAV shared with SuiteCRM |
| Collabora / ONLYOFFICE | In-browser office document editing |
| Talk | Internal video/audio calls (Jitsi handles large meetings) |
| OIDC login | Via Keycloak `nextcloud` client |
| External storage | Optional S3-compatible backend |

### Storage Layout

```
/var/www/nextcloud/data/
├── {username}/files/       # User files
├── appdata_{instanceid}/   # App data
└── __groupfolders/         # Shared department folders
```

---

## Module 07: Mattermost

**Repo:** [it-stack-mattermost](https://github.com/it-stack-dev/it-stack-mattermost)  
**Port:** 8065 (via Traefik) · **Subdomain:** `chat.example.com`  
**Replaces:** Slack, Microsoft Teams

### Default Channels

| Channel | Purpose |
|---------|---------|
| `#general` | Company-wide announcements |
| `#it-ops` | IT team coordination |
| `#ops-alerts` | Zabbix + Graylog automated alerts |
| `#deployments` | CI/CD deployment notifications |
| `#help-desk` | Zammad ticket escalations |

### Integrations

| Integration | Direction | Method |
|-------------|-----------|--------|
| Zabbix alerts | Zabbix → Mattermost | Webhook |
| Graylog alerts | Graylog → Mattermost | Webhook |
| Taiga updates | Taiga → Mattermost | Webhook |
| GLPI/Zammad tickets | GLPI → Mattermost | Webhook |

---

## Module 08: Jitsi

**Repo:** [it-stack-jitsi](https://github.com/it-stack-dev/it-stack-jitsi)  
**Ports:** 443 (HTTPS), 10000/UDP (media) · **Subdomain:** `meet.example.com`  
**Replaces:** Zoom, Google Meet

### Architecture

```
Browser → Jitsi Meet Web (443) → Jicofo (conference focus)
                                       → JVB (Video Bridge, 10000/UDP)
                                       → Prosody XMPP
```

### OIDC Authentication

When `TOKEN_AUTH_URL` is set to the Keycloak `jitsi` client, only authenticated users
can create rooms. Room names become JWT tokens tied to the Keycloak session.

---

## Lab Progression

| Lab | Module | Key Task |
|-----|--------|----------|
| 06-01 | Nextcloud | Standalone — file upload, app install |
| 06-02 | Nextcloud | PostgreSQL external DB, Redis cache |
| 06-04 | Nextcloud | Keycloak OIDC login |
| 06-05 | Nextcloud | SuiteCRM CalDAV sync, Mattermost notifications |
| 07-01 | Mattermost | Standalone — team, channels, users |
| 07-04 | Mattermost | Keycloak OIDC, invite-only |
| 08-01 | Jitsi | Standalone — test video call |
| 08-04 | Jitsi | Keycloak JWT authentication |
'@
Write-Host "[OK] docs/01-core/03-collaboration.md" -ForegroundColor Green

# ── 04. Communications ────────────────────────────────────────────────────────
Set-Content "$docs\04-communications.md" -Encoding UTF8 @'
---
doc: "01-core-04"
title: "Communications — iRedMail + FreePBX + Zammad"
category: communications
phase: 2 (iRedMail, Zammad) / 3 (FreePBX)
servers: [lab-comm1, lab-pbx1]
date: 2026-02-27
---

# Communications

> **Category:** Communications — Layer 4  
> **Phase:** 2 (iRedMail, Zammad) · 3 (FreePBX)  
> **Servers:** `lab-comm1` (10.0.50.14) · `lab-pbx1` (10.0.50.16)  
> **Modules:** iRedMail (09) · FreePBX (10) · Zammad (11)

---

## Module 09: iRedMail

**Repo:** [it-stack-iredmail](https://github.com/it-stack-dev/it-stack-iredmail)  
**Ports:** 25 (SMTP), 587 (submission), 143 (IMAP), 993 (IMAPS), 80/443 (webmail)  
**Subdomain:** `mail.example.com` · **Replaces:** Exchange Online, Google Workspace

### Components

| Component | Purpose |
|-----------|---------|
| Postfix | MTA — inbound/outbound SMTP |
| Dovecot | IMAP/POP3 server |
| Roundcube | Web mail client |
| SpamAssassin | Spam filtering |
| ClamAV | Antivirus scanning on attachments |
| iRedAPD | Policy daemon (rate limiting, greylisting) |
| OpenLDAP | User store (optionally federated to FreeIPA) |

### DNS Requirements

```
MX    mail.example.com           → lab-comm1
A     mail.example.com           → 10.0.50.14
SPF   v=spf1 mx a ~all
DKIM  default._domainkey          → (generated by iRedMail)
DMARC _dmarc                     → v=DMARC1; p=quarantine; rua=mailto:postmaster@example.com
```

---

## Module 10: FreePBX

**Repo:** [it-stack-freepbx](https://github.com/it-stack-dev/it-stack-freepbx)  
**Server:** `lab-pbx1` (10.0.50.16, dedicated VoIP server)  
**Ports:** 5060 (SIP UDP/TCP), 5061 (SIP TLS), 10000–20000 (RTP media)  
**Replaces:** RingCentral, 8x8, Vonage

### Architecture

```
SIP Trunk (ITSP) → Asterisk → FreePBX GUI
                       ↓
              Extensions (softphones, desk phones)
                       ↓
              SuiteCRM (CTI — click-to-call, call logging)
              Zammad   (auto-create tickets from missed calls)
```

### Key Features Configured

| Feature | Detail |
|---------|--------|
| IVR | Auto-attendant with department routing |
| Ring groups | IT support, helpdesk, sales |
| Voicemail | Email delivery via iRedMail |
| Call recording | Stored locally, linked in SuiteCRM |
| FreeIPA LDAP | Extension provisioning from directory |
| SIP TLS + SRTP | Encrypted voice traffic |

---

## Module 11: Zammad

**Repo:** [it-stack-zammad](https://github.com/it-stack-dev/it-stack-zammad)  
**Port:** 3000 (via Traefik) · **Subdomain:** `desk.example.com`  
**Replaces:** Zendesk, Freshdesk

### Ticket Channels

| Channel | Trigger |
|---------|---------|
| Email | All mail to `support@example.com` |
| Phone | FreePBX missed call webhook |
| Chat | Nextcloud Talk widget |
| API | GLPI escalation via REST |

### Integrations

| Integration | Detail |
|-------------|--------|
| Keycloak OIDC | SSO login for agents and end users |
| Elasticsearch | Full-text ticket search |
| iRedMail | Email channel (IMAP + SMTP) |
| FreePBX | CTI — auto-open ticket on inbound call |
| GLPI | Escalate IT incidents, sync CIs |
| Mattermost | Agent notifications to `#help-desk` |
'@
Write-Host "[OK] docs/01-core/04-communications.md" -ForegroundColor Green

# ── 05. Business Systems ───────────────────────────────────────────────────────
Set-Content "$docs\05-business.md" -Encoding UTF8 @'
---
doc: "01-core-05"
title: "Business Systems — SuiteCRM + Odoo + OpenKM"
category: business
phase: 3
servers: [lab-biz1]
date: 2026-02-27
---

# Business Systems

> **Category:** Business Systems — Layer 5  
> **Phase:** 3 (Back Office)  
> **Servers:** `lab-biz1` (10.0.50.17, 24 GB RAM)  
> **Modules:** SuiteCRM (12) · Odoo (13) · OpenKM (14)

---

## Module 12: SuiteCRM

**Repo:** [it-stack-suitecrm](https://github.com/it-stack-dev/it-stack-suitecrm)  
**Port:** 443 (via Traefik) · **Subdomain:** `crm.example.com`  
**Replaces:** Salesforce, HubSpot

### Core Modules Used

| CRM Module | Purpose |
|------------|---------|
| Accounts & Contacts | Customer and prospect database |
| Opportunities | Sales pipeline management |
| Cases | Customer support case tracking |
| Activities | Calls, meetings, tasks linked to records |
| Reports & Dashboards | Sales analytics |
| Email integration | Via iRedMail IMAP sync |

### Key Integrations

| Integration | Method | Detail |
|-------------|--------|--------|
| FreePBX CTI | AMI / REST | Click-to-call, auto-log inbound calls |
| Odoo | REST API | Sync converted opportunity → Odoo customer |
| Nextcloud | CalDAV | Sync activities to shared calendar |
| OpenKM | REST API | Link documents to CRM records |
| Keycloak | SAML 2.0 | SSO login |

---

## Module 13: Odoo

**Repo:** [it-stack-odoo](https://github.com/it-stack-dev/it-stack-odoo)  
**Ports:** 8069 (web), 8072 (longpoll) · **Subdomain:** `erp.example.com`  
**Replaces:** SAP, QuickBooks, NetSuite

### Installed Modules

| Odoo Module | Purpose |
|-------------|---------|
| Accounting | Double-entry bookkeeping, invoicing, expenses |
| Inventory | Stock management, warehouse operations |
| Purchase | PO management, vendor tracking |
| HR & Payroll | Employee records, leave, payroll |
| Project | Task management (lightweight — Taiga is primary PM) |
| Manufacturing | BOM, work orders (if applicable) |

### Key Integrations

| Integration | Method | Detail |
|-------------|--------|--------|
| FreeIPA LDAP | LDAP auth | Employee directory sync |
| SuiteCRM | REST API | Customer ↔ partner sync |
| Snipe-IT | REST API | Asset procurement → inventory |
| Taiga | Export | Timesheets → Odoo HR |
| Keycloak | OIDC | SSO login |

---

## Module 14: OpenKM

**Repo:** [it-stack-openkm](https://github.com/it-stack-dev/it-stack-openkm)  
**Port:** 8080 (via Traefik) · **Subdomain:** `docs.example.com`  
**Replaces:** SharePoint, Confluence, Google Drive (enterprise DMS use case)

### Document Repository Structure

```
/okm:root/
├── HR/               → Contracts, policies, onboarding docs
├── Finance/          → Invoices, receipts, financial reports
├── IT/               → Runbooks, network diagrams, SLAs
├── Sales/            → Proposals, contracts, case studies
├── Legal/            → NDAs, compliance documents
└── Shared/           → Company-wide reference documents
```

### Key Integrations

| Integration | Detail |
|-------------|--------|
| SuiteCRM | Attach documents to CRM records via REST |
| Odoo | Invoice/PO document storage |
| Nextcloud | Optional: Nextcloud as external storage backend |
| FreeIPA LDAP | User authentication and group-based ACLs |
'@
Write-Host "[OK] docs/01-core/05-business.md" -ForegroundColor Green

# ── 06. IT & Project Management ───────────────────────────────────────────────
Set-Content "$docs\06-it-management.md" -Encoding UTF8 @'
---
doc: "01-core-06"
title: "IT & Project Management — Taiga + Snipe-IT + GLPI"
category: it-management
phase: 4
servers: [lab-mgmt1]
date: 2026-02-27
---

# IT & Project Management

> **Category:** IT & Project Management — Layer 6  
> **Phase:** 4 (IT Management)  
> **Servers:** `lab-mgmt1` (10.0.50.18, 16 GB RAM)  
> **Modules:** Taiga (15) · Snipe-IT (16) · GLPI (17)

---

## Module 15: Taiga

**Repo:** [it-stack-taiga](https://github.com/it-stack-dev/it-stack-taiga)  
**Port:** 443 (via Traefik) · **Subdomain:** `pm.example.com`  
**Replaces:** Jira, Linear, Trello

### Project Boards in Use

| Project | Board Type | Team |
|---------|------------|------|
| IT-Stack Build | Kanban / Scrum | IT Infrastructure |
| IT Operations | Kanban | IT Operations |
| HR Onboarding | Kanban | HR |

### Key Integrations

| Integration | Method | Detail |
|-------------|--------|--------|
| Mattermost | Webhook | Story/task updates → `#dev-updates` |
| Odoo | Export | Sprint timesheets → Odoo HR timesheet |
| Keycloak | OIDC | SSO login |

---

## Module 16: Snipe-IT

**Repo:** [it-stack-snipeit](https://github.com/it-stack-dev/it-stack-snipeit)  
**Port:** 443 (via Traefik) · **Subdomain:** `assets.example.com`  
**Replaces:** Lansweeper, ManageEngine AssetExplorer

### Asset Categories

| Category | Examples |
|----------|---------|
| Computers | Desktops, laptops, servers |
| Network | Switches, routers, access points |
| Phones | VoIP handsets, mobile phones |
| Software | Licensed software (by seat) |
| Peripherals | Monitors, keyboards, mice |

### Key Integrations

| Integration | Method | Detail |
|-------------|--------|--------|
| GLPI | REST API | Sync hardware assets → GLPI CMDB |
| Odoo | REST API | Asset purchase → Odoo inventory |
| FreeIPA LDAP | LDAP | Assign assets to directory users |
| Keycloak | SAML | SSO login |

---

## Module 17: GLPI

**Repo:** [it-stack-glpi](https://github.com/it-stack-dev/it-stack-glpi)  
**Port:** 443 (via Traefik) · **Subdomain:** `itsm.example.com`  
**Replaces:** ServiceNow, BMC Remedy, Cherwell

### GLPI Modules Used

| Module | Purpose |
|--------|---------|
| Helpdesk | IT incident and request tickets |
| CMDB | Configuration item database |
| Asset Management | Supplement to Snipe-IT (CMDB view) |
| Change Management | RFC process, CAB approvals |
| Problem Management | Root cause analysis tracking |
| SLA Management | Response/resolution time targets |

### Key Integrations

| Integration | Method | Detail |
|-------------|--------|--------|
| Snipe-IT | REST API | Hardware assets → CMDB CIs |
| Zammad | REST API | Escalate IT incidents, sync updates |
| FreeIPA LDAP | LDAP | User authentication |
| Mattermost | Webhook | Critical ticket alerts |
| Keycloak | SAML | SSO login |
'@
Write-Host "[OK] docs/01-core/06-it-management.md" -ForegroundColor Green

# ── 07. Infrastructure ────────────────────────────────────────────────────────
Set-Content "$docs\07-infrastructure.md" -Encoding UTF8 @'
---
doc: "01-core-07"
title: "Infrastructure — Traefik + Zabbix + Graylog"
category: infrastructure
phase: 1 (Traefik) / 4 (Zabbix, Graylog)
servers: [lab-proxy1]
date: 2026-02-27
---

# Infrastructure

> **Category:** Infrastructure — Layer 7  
> **Phase:** 1 (Traefik) · 4 (Zabbix, Graylog)  
> **Servers:** `lab-proxy1` (10.0.50.15, 8 GB RAM)  
> **Modules:** Traefik (18) · Zabbix (19) · Graylog (20)

---

## Module 18: Traefik

**Repo:** [it-stack-traefik](https://github.com/it-stack-dev/it-stack-traefik)  
**Ports:** 80 (HTTP→HTTPS redirect), 443 (HTTPS), 8080 (dashboard)  
**Phase:** 1 (Foundation — required before all other services)

### Subdomain Routing

| Subdomain | Backend Service | Port |
|-----------|----------------|------|
| `cloud.example.com` | Nextcloud | 80 |
| `chat.example.com` | Mattermost | 8065 |
| `meet.example.com` | Jitsi | 443 |
| `mail.example.com` | iRedMail | 443 |
| `desk.example.com` | Zammad | 3000 |
| `crm.example.com` | SuiteCRM | 443 |
| `erp.example.com` | Odoo | 8069 |
| `docs.example.com` | OpenKM | 8080 |
| `pm.example.com` | Taiga | 443 |
| `assets.example.com` | Snipe-IT | 443 |
| `itsm.example.com` | GLPI | 443 |
| `monitor.example.com` | Zabbix | 3000 |
| `logs.example.com` | Graylog | 9000 |
| `id.example.com` | Keycloak | 8443 |

### TLS Strategy

```yaml
# traefik.yml
certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@example.com
      storage: /data/acme.json
      tlsChallenge: {}
  # Internal CA for lab environments (no public DNS)
  internal:
    acme:
      caServer: https://lab-id1/ipa/acme/directory
```

---

## Module 19: Zabbix

**Repo:** [it-stack-zabbix](https://github.com/it-stack-dev/it-stack-zabbix)  
**Port:** 10051 (agent), 3000 (Grafana dashboard) · **Subdomain:** `monitor.example.com`  
**Phase:** 4  
**Replaces:** Datadog, Nagios, PRTG

### Monitored Hosts

All 8 servers monitored via Zabbix Agent 2:

| Host | Key Metrics |
|------|------------|
| lab-id1 | FreeIPA LDAP response, Kerberos TGT, DNS |
| lab-db1 | PostgreSQL connections, Redis memory, ES cluster health |
| lab-app1 | Nextcloud cron, Mattermost websockets, Jitsi JVB |
| lab-comm1 | Postfix queue, Dovecot connections, Zammad jobs |
| lab-proxy1 | Traefik active connections, cert expiry, Graylog lag |
| lab-pbx1 | Asterisk channels, SIP trunk status, RTP packet loss |
| lab-biz1 | Odoo workers, SuiteCRM cron, OpenKM JVM heap |
| lab-mgmt1 | Taiga Celery workers, GLPI cron, Snipe-IT queue |

### Alert Routing

```
Zabbix problem → Webhook → Mattermost #ops-alerts
              → Email  → ops-team@example.com
              → (Critical) SMS via Zabbix SMS media
```

---

## Module 20: Graylog

**Repo:** [it-stack-graylog](https://github.com/it-stack-dev/it-stack-graylog)  
**Ports:** 9000 (web UI), 1514 (Syslog), 12201 (GELF) · **Subdomain:** `logs.example.com`  
**Phase:** 4  
**Replaces:** Splunk, Datadog Logs, Elastic Stack (ELK)

### Log Sources

| Source | Protocol | Input |
|--------|----------|-------|
| All 8 servers | Syslog UDP | Port 1514 |
| Docker containers | GELF | Port 12201 |
| Nginx/Traefik | Syslog | Port 1514 |
| Mattermost | GELF | Port 12201 |
| Zammad | Filebeat | Port 12201 |
| Odoo | GELF | Port 12201 |

### Streams & Alerts

| Stream | Criteria | Alert To |
|--------|----------|---------|
| Security Events | `auth_failure`, `sudo`, SSH login | Mattermost #security |
| Application Errors | `level:error`, `level:critical` | Mattermost #ops-alerts |
| Slow Queries | PostgreSQL `duration > 1000ms` | Zabbix trigger |

### Graylog → Zabbix Integration

Graylog alert callbacks call the Zabbix external check API, allowing log-based events
to trigger Zabbix problem states and go through the standard alert routing.
'@
Write-Host "[OK] docs/01-core/07-infrastructure.md" -ForegroundColor Green

Write-Host "`nAll 7 category spec docs created in docs/01-core/" -ForegroundColor Cyan
