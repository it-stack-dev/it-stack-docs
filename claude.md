# IT-Stack Project Instructions for AI Assistant

> **Purpose:** This document provides AI assistants with full context about the IT-Stack project.  
> **Last Updated:** February 27, 2026 (rev 2)  
> **Location:** Place at the workspace root (`C:\IT-Stack\claude.md` or `C:\it-stack-dev\claude.md`)

---

## Quick Reference

| Key | Value |
|-----|-------|
| **Project** | IT-Stack — Complete open-source enterprise IT infrastructure |
| **GitHub Org** | [`it-stack-dev`](https://github.com/it-stack-dev) (26 repositories) |
| **Scale** | 20 modules · 7 categories · 120 lab tests · 4 deployment phases |
| **License** | Apache 2.0 |
| **Status** | Phase 0 complete, Phase 1 (GitHub bootstrap) starting |
| **Dev Machine** | Windows · PowerShell · `C:\IT-Stack\` (docs) · `C:\it-stack-dev\` (dev workspace) |
| **Target** | 50–1,000+ users · 8–9 Ubuntu 24.04 servers · 20 integrated services |

---

## What Is IT-Stack?

IT-Stack is a **production-ready enterprise IT platform** built entirely from open-source software — **$0 in software licensing**. It provides every service a mid-to-large organization needs:

- **Identity & SSO** — FreeIPA (LDAP/Kerberos) + Keycloak (OAuth2/OIDC/SAML)
- **Database layer** — PostgreSQL (10+ service databases) + Redis (cache) + Elasticsearch (search/logs)
- **Collaboration** — Nextcloud (files/calendar/office) + Mattermost (chat) + Jitsi (video)
- **Communications** — iRedMail (email) + FreePBX (VoIP/PBX) + Zammad (help desk)
- **Business systems** — SuiteCRM (CRM) + Odoo (ERP) + OpenKM (document management)
- **IT management** — Taiga (projects) + Snipe-IT (assets) + GLPI (ITSM)
- **Infrastructure** — Traefik (reverse proxy) + Zabbix (monitoring) + Graylog (logs)

### What It Replaces

| Commercial Product | IT-Stack Replacement | Annual Cost Saved (100 users) |
|--------------------|---------------------|-------------------------------|
| Microsoft 365 | Nextcloud + iRedMail | ~$24,000 |
| Slack / Teams | Mattermost | ~$15,000 |
| Zoom | Jitsi | ~$24,000 |
| Salesforce | SuiteCRM | ~$90,000 |
| SAP / QuickBooks | Odoo | ~$50,000 |
| RingCentral | FreePBX | ~$36,000 |
| ServiceNow | GLPI + Zammad | ~$120,000 |
| Jira | Taiga | ~$12,000 |
| Active Directory | FreeIPA + Keycloak | ~$10,000 |
| Datadog / Splunk | Zabbix + Graylog | ~$25,000 |

**5-year TCO savings: ~$2,000,000 vs. commercial equivalent**

---

## Architecture: 7-Layer Stack

```
Layer 7: Infrastructure     — Traefik · Zabbix · Graylog
Layer 6: IT & Project Mgmt  — Taiga · Snipe-IT · GLPI
Layer 5: Business Systems    — SuiteCRM · Odoo · OpenKM
Layer 4: Communications      — iRedMail · FreePBX · Zammad
Layer 3: Collaboration       — Nextcloud · Mattermost · Jitsi
Layer 2: Database & Cache    — PostgreSQL · Redis · Elasticsearch
Layer 1: Identity & Security — FreeIPA · Keycloak
```

### 8-Server Production Layout

| Server | Hostname | IP | Services | RAM |
|--------|----------|-----|----------|-----|
| 1 - Identity | lab-id1 | 10.0.50.11 | FreeIPA, Keycloak | 16 GB |
| 2 - Database | lab-db1 | 10.0.50.12 | PostgreSQL, Redis, Elasticsearch | 32 GB |
| 3 - Collaboration | lab-app1 | 10.0.50.13 | Nextcloud, Mattermost, Jitsi | 24 GB |
| 4 - Communications | lab-comm1 | 10.0.50.14 | iRedMail, Zammad, Zabbix | 16 GB |
| 5 - Reverse Proxy | lab-proxy1 | 10.0.50.15 | Traefik, Graylog | 8 GB |
| 6 - VoIP | lab-pbx1 | 10.0.50.16 | FreePBX (Asterisk) | 8 GB |
| 7 - Business | lab-biz1 | 10.0.50.17 | SuiteCRM, Odoo, OpenKM | 24 GB |
| 8 - IT Mgmt | lab-mgmt1 | 10.0.50.18 | Taiga, Snipe-IT, GLPI | 16 GB |

**OS:** Ubuntu 24.04 Server LTS (all nodes)  
**Network:** 10.0.50.0/24 · Internal DNS via FreeIPA

---

## Complete Module Reference

| # | Module | Repo Name | Category | Phase | Key Ports |
|---|--------|-----------|----------|-------|-----------|
| 01 | FreeIPA | `it-stack-freeipa` | identity | 1 | 389, 636, 88, 53 |
| 02 | Keycloak | `it-stack-keycloak` | identity | 1 | 8080, 8443 |
| 03 | PostgreSQL | `it-stack-postgresql` | database | 1 | 5432 |
| 04 | Redis | `it-stack-redis` | database | 1 | 6379 |
| 05 | Elasticsearch | `it-stack-elasticsearch` | database | 4 | 9200, 9300 |
| 06 | Nextcloud | `it-stack-nextcloud` | collaboration | 2 | 80, 443 |
| 07 | Mattermost | `it-stack-mattermost` | collaboration | 2 | 8065 |
| 08 | Jitsi | `it-stack-jitsi` | collaboration | 2 | 443, 10000/udp |
| 09 | iRedMail | `it-stack-iredmail` | communications | 2 | 25, 143, 993, 587 |
| 10 | FreePBX | `it-stack-freepbx` | communications | 3 | 5060, 5061, 10000-20000/udp |
| 11 | Zammad | `it-stack-zammad` | communications | 2 | 3000 |
| 12 | SuiteCRM | `it-stack-suitecrm` | business | 3 | 80, 443 |
| 13 | Odoo | `it-stack-odoo` | business | 3 | 8069, 8072 |
| 14 | OpenKM | `it-stack-openkm` | business | 3 | 8080 |
| 15 | Taiga | `it-stack-taiga` | it-management | 4 | 80, 443 |
| 16 | Snipe-IT | `it-stack-snipeit` | it-management | 4 | 80, 443 |
| 17 | GLPI | `it-stack-glpi` | it-management | 4 | 80, 443 |
| 18 | Traefik | `it-stack-traefik` | infrastructure | 1 | 80, 443, 8080 |
| 19 | Zabbix | `it-stack-zabbix` | infrastructure | 4 | 10051, 3000 |
| 20 | Graylog | `it-stack-graylog` | infrastructure | 4 | 9000, 1514, 12201 |

---

## GitHub Organization Structure

### Repos (26 total)

**6 Meta Repositories:**

| Repo | Purpose |
|------|---------|
| `it-stack-docs` | Full documentation (~600 pages, 14 source docs) |
| `it-stack-installer` | Bootstrap scripts, automation, setup tools |
| `it-stack-testing` | Integration & end-to-end test suite |
| `it-stack-ansible` | Ansible playbooks for all 20 services |
| `it-stack-terraform` | Terraform modules for VM provisioning |
| `it-stack-helm` | Helm charts for Kubernetes deployment |

**20 Component Repositories:** one per module (see table above).

### Naming Convention

**Pattern:** `it-stack-{component}` (kebab-case, always)

### GitHub Projects (5)

| # | Name | Modules | Lab Issues |
|---|------|---------|------------|
| 1 | Phase 1: Foundation | freeipa, keycloak, postgresql, redis, traefik | 30 |
| 2 | Phase 2: Collaboration | nextcloud, mattermost, jitsi, iredmail, zammad | 30 |
| 3 | Phase 3: Back Office | freepbx, suitecrm, odoo, openkm | 24 |
| 4 | Phase 4: IT Management | taiga, snipeit, glpi, elasticsearch, zabbix, graylog | 36 |
| 5 | Master Dashboard | All 20 modules | 120 |

### Labels

- `lab` — all lab issues
- `module-01` through `module-20`
- `phase-1` through `phase-4`
- Category: `identity`, `database`, `collaboration`, `communications`, `business`, `it-management`, `infrastructure`
- Priority: `priority-high`, `priority-med`, `priority-low`
- Status: `status-todo`, `status-in-progress`, `status-done`, `status-blocked`

### Branch Strategy

```
main       ← production-ready, protected
develop    ← integration branch, default for PRs
feature/*  ← feature work (from develop)
bugfix/*   ← bug fixes
release/*  ← release prep
hotfix/*   ← emergency fixes from main
```

---

## Standard Repository Structure

Every component repo (`it-stack-{module}`) has this identical layout:

```
it-stack-{module}/
├── src/                          # Application source code
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── e2e/
│   └── labs/
│       ├── test-lab-01.sh        # Standalone
│       ├── test-lab-02.sh        # External dependencies
│       ├── test-lab-03.sh        # Advanced features
│       ├── test-lab-04.sh        # SSO integration
│       ├── test-lab-05.sh        # Advanced integration
│       └── test-lab-06.sh        # Production deployment
├── docker/
│   ├── docker-compose.standalone.yml   # Lab 01
│   ├── docker-compose.lan.yml          # Lab 02
│   ├── docker-compose.advanced.yml     # Lab 03
│   ├── docker-compose.sso.yml          # Lab 04
│   ├── docker-compose.integration.yml  # Lab 05
│   └── docker-compose.production.yml   # Lab 06
├── kubernetes/
│   ├── base/
│   └── overlays/ (dev, staging, production)
├── helm/templates/
├── ansible/ (roles, playbooks)
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DEPLOYMENT.md
│   ├── TROUBLESHOOTING.md
│   └── labs/ (01-standalone.md … 06-production.md)
├── .github/workflows/ (ci.yml, release.yml)
├── it-stack-{module}.yml         # Module manifest (YAML metadata)
├── Makefile                      # make install/test/build/deploy/clean
├── Dockerfile
├── .gitignore
├── CHANGELOG.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
├── SUPPORT.md
├── LICENSE                       # Apache 2.0
└── README.md
```

---

## 6-Lab Testing Progression

**Every module has exactly 6 labs.** This is the universal, non-negotiable testing methodology.

| Lab | Name | Duration | Machines | Purpose |
|-----|------|----------|----------|---------|
| **XX-01** | Standalone | 30–60 min | 1 | Basic functionality in complete isolation |
| **XX-02** | External Dependencies | 45–90 min | 2–3 | Network integration, external DB/services |
| **XX-03** | Advanced Features | 60–120 min | 2–3 | Production features, performance, scaling |
| **XX-04** | SSO Integration | 90–120 min | 3–4 | Keycloak OIDC/SAML authentication |
| **XX-05** | Advanced Integration | 90–150 min | 4–5 | Deep multi-module ecosystem integration |
| **XX-06** | Production Deployment | 120–180 min | 5+ | HA cluster, monitoring, DR, load testing |

**Lab numbering:** `XX-YY` where XX = module number (01–20), YY = lab number (01–06).  
**Example:** Lab `03-04` = PostgreSQL, SSO Integration.

**Progression logic:**
```
Lab 01: Can it run at all?                  (standalone)
Lab 02: Can it talk to external services?   (network, multi-machine)
Lab 03: Can it handle production features?  (performance, advanced config)
Lab 04: Can it authenticate via SSO?        (Keycloak integration)
Lab 05: Can it integrate with the ecosystem? (multi-module)
Lab 06: Can it run in production?           (HA, monitoring, DR)
```

**Total: 120 labs (20 modules × 6 labs)**

---

## 4-Phase Implementation Roadmap

| Phase | Name | Timeline | Modules | Deliverable |
|-------|------|----------|---------|-------------|
| **1** | Foundation | Weeks 1–4 | FreeIPA, Keycloak, PostgreSQL, Redis, Traefik | SSO + DB + reverse proxy end-to-end |
| **2** | Collaboration | Weeks 5–8 | Nextcloud, Mattermost, Jitsi, iRedMail, Zammad | Full collaboration suite with SSO |
| **3** | Back Office | Weeks 9–14 | FreePBX, SuiteCRM, Odoo, OpenKM | VoIP + CRM + ERP + DMS integrated |
| **4** | IT Management | Weeks 15–20 | Taiga, Snipe-IT, GLPI, Elasticsearch, Zabbix, Graylog | Full observability + IT management |

---

## Deployment Tiers

| Tier | Name | Nodes | Labs Covered |
|------|------|-------|-------------|
| 1A | Lab / Home | 1–3 | Labs 01, 02 |
| 1B | School / Small Office | 3–5 | Labs 02, 03, 04 |
| 2 | Department | 5–10 | Labs 04, 05 |
| 3 | Enterprise / Production | 8–20+ | Labs 05, 06 |

---

## Key Integration Points

### SSO Integrations (All via Keycloak)

| Service | Protocol | Realm Client |
|---------|----------|-------------|
| Nextcloud | OIDC | `nextcloud` |
| Mattermost | OIDC | `mattermost` |
| Jitsi | OIDC | `jitsi` |
| SuiteCRM | SAML | `suitecrm` |
| Odoo | OIDC | `odoo` |
| Zammad | OIDC | `zammad` |
| GLPI | SAML | `glpi` |
| Taiga | OIDC | `taiga` |
| Snipe-IT | SAML | `snipeit` |

**Identity flow:** User → Keycloak → FreeIPA (LDAP federation) → Kerberos ticket

### Critical Business Integrations

| Integration | Protocol/Method | Purpose |
|-------------|----------------|---------|
| FreePBX ↔ SuiteCRM | REST API, CTI | Click-to-call, call logging |
| FreePBX ↔ Zammad | Email/Webhook | Auto-create phone tickets |
| SuiteCRM ↔ Odoo | REST API sync | Customer ↔ accounting data |
| SuiteCRM ↔ Nextcloud | CalDAV | Calendar + file sync |
| Odoo ↔ FreeIPA | LDAP | Employee directory sync |
| Odoo ↔ Snipe-IT | REST API | Asset procurement flow |
| Taiga ↔ Mattermost | Webhook | Project notifications |
| Snipe-IT ↔ GLPI | REST API | Asset ↔ CMDB sync |
| GLPI ↔ Zammad | REST API | Ticket escalation |
| Zabbix ↔ Mattermost | Webhook | Infra alerts to `#ops-alerts` |
| Graylog ↔ Zabbix | Syslog | Log-based alert triggers |
| OpenKM ↔ all services | REST API | Central document repository |

---

## Documentation Set

**Location:** `C:\IT-Stack\` (root + `docs\` subfolder)

**Root-level standard files:**

| File | Purpose |
|------|---------|
| `README.md` | Project overview, module table, server layout, documentation map |
| `CHANGELOG.md` | Version history — Keep a Changelog format, per-module version scheme |
| `CONTRIBUTING.md` | Branch strategy, commit conventions, PR process, lab + doc standards |
| `CODE_OF_CONDUCT.md` | Contributor Covenant 2.1 with full enforcement guidelines |
| `SECURITY.md` | Responsible disclosure process, security architecture, hardening checklist |
| `SUPPORT.md` | Debug checklist, per-module common issues, no-SLA disclaimer |
| `LICENSE` | Apache 2.0 full text |
| `.gitignore` | Secrets/keys/certs, Terraform state, Docker volumes, Ansible vault, OS/editor artifacts |
| `claude.md` | This file — AI assistant full context |

**`docs\` subfolder** (14 documents, ~600 pages, ~25,000 lines):

| # | Document | Size | Purpose |
|---|----------|------|---------|
| 1 | `LAB_MANUAL_STRUCTURE.md` | 6 KB | Overview of entire manual series |
| 2 | `lab-deployment-plan.md` | 46 KB | Test deployment strategy (3–5 servers) |
| 3 | `enterprise-it-stack-deployment.md` | 112 KB | Original technical reference (15+ servers) |
| 4 | `enterprise-stack-complete-v2.md` | 35 KB | Updated 8-server architecture |
| 5 | `enterprise-it-lab-manual.md` | 73 KB | Part 1: Network & OS setup |
| 6 | `enterprise-it-lab-manual-part2.md` | 57 KB | Part 2: Identity/DB/SSO (FreeIPA, PG, Keycloak) |
| 7 | `enterprise-it-lab-manual-part3.md` | 35 KB | Part 3: Collaboration (Nextcloud, Mattermost, Jitsi) |
| 8 | `enterprise-it-lab-manual-part4.md` | 49 KB | Part 4: Communications (Email, Proxy, Help Desk, Monitoring) |
| 9 | `enterprise-lab-manual-part5.md` | 37 KB | Part 5: Back Office (VoIP, CRM, ERP, DMS, PM, Assets, ITSM) |
| 10 | `integration-guide-complete.md` | 27 KB | Cross-system integration procedures |
| 11 | `MASTER-INDEX.md` | 20 KB | Master index and reading guide |
| 12 | `PROJECT-FRAMEWORK-TEMPLATE.md` | 65 KB | Project framework blueprint (customized) |
| 13 | `IT-STACK-TODO.md` | 18 KB | Living task checklist |
| 14 | `IT-STACK-GITHUB-GUIDE.md` | 35 KB | GitHub org setup guide with scripts |

### Reading Priority

1. **This file (`claude.md`)** — You're here. Full project context.
2. **`README.md`** — Quick overview, all tables in one place.
3. **`PROJECT-FRAMEWORK-TEMPLATE.md`** — Framework patterns, conventions, templates.
4. **`IT-STACK-TODO.md`** — Current status, what's done, what's next.
5. **`IT-STACK-GITHUB-GUIDE.md`** — GitHub setup scripts and procedures.
6. **`MASTER-INDEX.md`** — Documentation set navigation.
7. **`enterprise-stack-complete-v2.md`** — Architecture and server layout.
8. **Lab manuals (parts 1–5)** — Step-by-step service deployment.
9. **`integration-guide-complete.md`** — Cross-service integration details.
10. **`CONTRIBUTING.md`** — When writing code, scripts, or lab tests.
11. **`SECURITY.md`** — When evaluating security posture or hardening.

---

## Local Workspace Structure

### Docs Workspace (current)

```
C:\IT-Stack\
├── docs\                          # All project documentation
│   ├── MASTER-INDEX.md
│   ├── PROJECT-FRAMEWORK-TEMPLATE.md
│   ├── IT-STACK-TODO.md
│   ├── IT-STACK-GITHUB-GUIDE.md
│   ├── LAB_MANUAL_STRUCTURE.md
│   ├── lab-deployment-plan.md
│   ├── enterprise-it-stack-deployment.md
│   ├── enterprise-stack-complete-v2.md
│   ├── enterprise-it-lab-manual.md
│   ├── enterprise-it-lab-manual-part2.md
│   ├── enterprise-it-lab-manual-part3.md
│   ├── enterprise-it-lab-manual-part4.md
│   ├── enterprise-lab-manual-part5.md
│   └── integration-guide-complete.md
├── README.md                      # Project overview + module/server tables
├── CHANGELOG.md                   # Version history (Keep a Changelog format)
├── CONTRIBUTING.md                # Contribution guidelines + standards
├── CODE_OF_CONDUCT.md             # Contributor Covenant 2.1
├── SECURITY.md                    # Responsible disclosure + hardening guide
├── SUPPORT.md                     # Debug checklist + per-module common issues
├── LICENSE                        # Apache 2.0
├── .gitignore                     # Secrets, certs, volumes, OS/editor artifacts
└── claude.md                      # This file
```

### Dev Workspace (to be created)

```
C:\it-stack-dev\
├── repos/
│   ├── meta/                   # 6 meta repos
│   ├── 01-identity/            # freeipa, keycloak
│   ├── 02-database/            # postgresql, redis, elasticsearch
│   ├── 03-collaboration/       # nextcloud, mattermost, jitsi
│   ├── 04-communications/      # iredmail, freepbx, zammad
│   ├── 05-business/            # suitecrm, odoo, openkm
│   ├── 06-it-management/       # taiga, snipeit, glpi
│   └── 07-infrastructure/      # traefik, zabbix, graylog
├── workspaces/                 # Sprint work, lab testing, integration
├── deployments/                # local, dev, staging, production
├── lab-environments/           # tier-1-lab, tier-1-school, tier-2-department, tier-3-enterprise
├── configs/                    # global, per-module, per-environment, secrets
├── scripts/                    # setup, github, operations, testing, deployment
├── logs/
├── claude.md                   # ← This file (copy here)
└── README.md
```

---

## Configuration Hierarchy (Precedence)

```
1. Environment variables        (highest)
2. Command-line arguments
3. Environment config           (configs/environments/production.yaml)
4. Module config                (configs/modules/{module}.yaml)
5. Global config                (configs/global/it-stack.yaml)
6. Default values in code       (lowest)
```

### Secrets Management

- **Never** commit secrets. `configs/secrets/` is fully `.gitignore`d.
- Use **Ansible Vault** for encrypted credentials.
- SSL certs, API tokens, DB passwords stored in `configs/secrets/` (GPG-encrypted).

---

## Technology Stack Summary

### Server-Side

| Technology | Version | Used For |
|-----------|---------|----------|
| Ubuntu Server | 24.04 LTS | All nodes |
| PostgreSQL | 16.x | Primary DB (10+ databases) |
| Redis | 7.x | Cache, sessions, queues |
| Elasticsearch | 8.x | Search, log indexing |
| Nginx | 1.24+ | Web server (Nextcloud, etc.) |
| PHP | 8.3 | Nextcloud, SuiteCRM |
| Python | 3.12+ | Odoo, Taiga, scripts |
| Node.js | 20 LTS | Mattermost, Jitsi |
| Asterisk | 20.x | FreePBX telephony engine |
| Java | 17 / 21 | Keycloak, OpenKM, Elasticsearch |

### DevOps / Automation

| Tool | Purpose |
|------|---------|
| Docker / Docker Compose | Container orchestration (labs + dev) |
| Ansible | Configuration management (all 20 services) |
| Terraform | Infrastructure provisioning (VMs) |
| Helm | Kubernetes package management |
| k3d / minikube | Local Kubernetes clusters |
| GitHub Actions | CI/CD pipelines |
| GitHub CLI (`gh`) | Repo, issue, project management |
| Trivy | Container security scanning |
| Make | Build automation (every repo has a Makefile) |

---

## Common Tasks & How to Help

### 1. GitHub Organization Setup

Reference: `IT-STACK-GITHUB-GUIDE.md`  
Commands use: `gh repo create`, `gh issue create`, `gh project create`  
All PowerShell scripts — use proper PowerShell syntax (backtick line continuation, `$variables`)

### 2. Creating / Scaffolding a Module

```powershell
.\scripts\utilities\create-repo-template.ps1 -ModuleName "freeipa" -Category "01-identity" -ModuleNumber "01"
```

Creates full directory structure, 6 docker-compose files, 6 lab test scripts, YAML manifest.

### 3. Writing Lab Test Scripts

Every lab test follows 4 phases:
1. **Setup** — `docker compose up -d`
2. **Health check** — `curl -f http://localhost:PORT/health`
3. **Functional tests** — module-specific validation
4. **Cleanup** — `docker compose down -v`

### 4. Writing Ansible Playbooks

- Place in `it-stack-ansible/playbooks/deploy-{module}.yml`
- Use roles from `it-stack-ansible/roles/{module}/`
- Variables in `group_vars/all.yaml` and `host_vars/node-{N}.yaml`
- Always use Ansible Vault for credentials: `ansible-vault encrypt_string`

### 5. Writing Docker Compose Files

- 6 files per module (standalone, lan, advanced, sso, integration, production)
- Standalone (Lab 01) = completely self-contained, no external deps
- Production (Lab 06) = HA ready, healthchecks, resource limits, external volumes

### 6. Documentation

- All docs use Markdown
- Numbered documents for clear referencing
- Step-by-step with CLI commands, expected output, "Understanding" sections
- Lab manual style: exercises → steps → verification → troubleshooting

### 7. Debugging Service Issues

Check in this order:
1. `systemctl status {service}`
2. `journalctl -u {service} -n 50`
3. Service-specific logs (e.g., `/var/log/nginx/error.log`)
4. PostgreSQL connection: `psql -h lab-db1 -U {user} -d {db}`
5. Keycloak admin: `https://lab-id1:8443/admin/`
6. FreeIPA admin: `https://lab-id1/ipa/ui/`
7. Docker: `docker compose logs -f {service}`
8. Firewall: `sudo ufw status` / `sudo iptables -L`
9. DNS: `dig @lab-id1 {hostname}`
10. Certificates: `openssl s_client -connect {host}:443`

---

## Code Review Checklist

When reviewing PRs for any IT-Stack repo:

**Structure**
- [ ] Follows standard repository structure exactly
- [ ] `it-stack-{module}.yml` manifest is correct
- [ ] All 6 lab test scripts present and updated
- [ ] Documentation updated (README, ARCHITECTURE, lab guides)

**Security**
- [ ] No secrets, credentials, or tokens in code
- [ ] Input validation on all endpoints
- [ ] TLS configured where applicable
- [ ] Authentication required on protected endpoints

**Operations**
- [ ] Health check endpoint at `/health`
- [ ] Metrics endpoint at `/metrics` (Prometheus format)
- [ ] Structured logging implemented
- [ ] Graceful shutdown handling
- [ ] Resource limits defined in manifest and compose files

---

## Commit Messages

**Format:** `type(scope): short description`

| Type | Use For |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `test` | Adding/updating tests |
| `refactor` | Code restructuring |
| `chore` | Maintenance, tooling, CI |

**Examples:**
```
feat(keycloak): add SAML client for SuiteCRM
fix(postgresql): correct pg_hba.conf for remote connections
docs(labs): add lab 03 guide for Nextcloud advanced features
test(freeipa): add DNS resolution test to lab-02
chore(ci): add Trivy scanning to release workflow
```

---

## Important Conventions

1. **One module = one repo = one manifest = 6 labs** — always.
2. **Naming:** `it-stack-{component}` kebab-case everywhere (repos, images, charts, namespaces).
3. **Repos are cloned into category directories:** `repos/01-identity/it-stack-freeipa/`
4. **Lab numbering:** `XX-YY` (module-lab), e.g., `07-04` = Mattermost SSO Integration.
5. **All PostgreSQL databases live on lab-db1** — Nextcloud, Mattermost, Keycloak, Zammad, SuiteCRM, Odoo, OpenKM, Taiga, Snipe-IT, GLPI all connect to it.
6. **All services authenticate through Keycloak** — which federates users from FreeIPA LDAP.
7. **Traefik routes all HTTPS traffic** — each service gets a subdomain: `cloud.`, `chat.`, `meet.`, `mail.`, `desk.`, `crm.`, `erp.`, `docs.`, etc.
8. **PowerShell is the primary scripting language** on the dev machine (Windows). Lab servers run Bash.
9. **Documentation is the deliverable** — this is as much a documentation/education project as it is infrastructure.
10. **Search project docs first** — before generating answers about IT-Stack specifics, check the existing docs in `C:\IT-Stack\docs\`.

---

## Current Project Status

**Phase 0: Planning** — ✅ Complete  
- GitHub org `it-stack-dev` created (empty)
- 14 documentation files assembled (~600 pages)
- Framework template (`PROJECT-FRAMEWORK-TEMPLATE.md`) customized for IT-Stack
- TODO checklist (`IT-STACK-TODO.md`) and GitHub guide (`IT-STACK-GITHUB-GUIDE.md`) created
- `claude.md` AI context file created
- Standard repo root files created: `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `SUPPORT.md`, `LICENSE`, `.gitignore`

**Phase 1: GitHub Bootstrap** — Not Started  
- Next: create `.github` repo, then 6 meta repos, then GitHub Projects

**Remaining:** Phases 2–7 (local env, docs migration, module scaffolding × 4 phases), then CI/CD, lab testing, integrations, production readiness.

**See `IT-STACK-TODO.md` for the complete, granular task list.**

---

## Best Practices When Assisting

1. **Search project knowledge first** — check existing docs before generating from scratch.
2. **Use exact file paths** — reference `C:\IT-Stack\docs\{filename}` or repo paths.
3. **Follow conventions exactly** — repo structure, naming, lab numbering.
4. **Provide complete, working examples** — full config files, full scripts, not snippets.
5. **Think in phases** — always know which deployment phase a module belongs to.
6. **PowerShell on Windows, Bash on servers** — match the context.
7. **Remember the dependency chain** — FreeIPA → Keycloak → all apps → integrations.
8. **Labs build on each other** — Lab 04 assumes Labs 01–03 pass.
9. **Test scripts should be idempotent** — re-runnable without manual cleanup.
10. **When in doubt, check `PROJECT-FRAMEWORK-TEMPLATE.md`** — it's the canonical reference.
