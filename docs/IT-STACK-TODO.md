# IT-Stack — Master TODO & Implementation Checklist
## Project: `it-stack` | GitHub Org: `it-stack-dev`
**Created:** February 27, 2026  
**Status:** Phases 0–4 Complete · Phase 1 Labs In Progress · Direction: Go Deep on Phase 1

> This is the living task list for implementing the IT-Stack project using the framework defined in `PROJECT-FRAMEWORK-TEMPLATE.md`.  
> Check items off as you complete them. Each section maps to a Phase or infrastructure domain.

---

## Table of Contents

1. [Phase 0: Planning & Setup](#phase-0-planning--setup) — ✅ Complete
2. [Phase 1: GitHub Organization Bootstrap](#phase-1-github-organization-bootstrap)
3. [Phase 2: Local Development Environment](#phase-2-local-development-environment)
4. [Phase 3: Documentation Migration](#phase-3-documentation-migration)
5. [Phase 4: Module Scaffolding — Phase 1 (Foundation)](#phase-4-module-scaffolding--deployment-phase-1-foundation)
6. [Phase 5: Module Scaffolding — Phase 2 (Collaboration)](#phase-5-module-scaffolding--deployment-phase-2-collaboration)
7. [Phase 6: Module Scaffolding — Phase 3 (Back Office)](#phase-6-module-scaffolding--deployment-phase-3-back-office)
8. [Phase 7: Module Scaffolding — Phase 4 (IT Management)](#phase-7-module-scaffolding--deployment-phase-4-it-management)
9. [CI/CD & Automation Setup](#cicd--automation-setup)
10. [Lab Testing Milestones](#lab-testing-milestones)
11. [Integration Milestones](#integration-milestones)
12. [Production Readiness](#production-readiness)

---

## Legend

| Symbol | Meaning |
|--------|---------|
| `[ ]` | Not started |
| `[x]` | Complete |
| `[-]` | In progress |
| `[!]` | Blocked / needs decision |
| `[~]` | Optional / nice-to-have |

---

## Phase 0: Planning & Setup

> **Status: ✅ COMPLETE**  
> GitHub org `it-stack-dev` created and empty. Documentation set complete (14 docs).

- [x] Define project name: `it-stack`
- [x] Create GitHub organization: `it-stack-dev`
- [x] Define 7 categories (identity, database, collaboration, communications, business, it-management, infrastructure)
- [x] List and number 20 modules (01–20)
- [x] Map all modules to categories
- [x] Define 4 deployment phases (Foundation → Collaboration → Back Office → IT Management)
- [x] Define 4 deployment tiers (lab → school → department → enterprise)
- [x] Complete documentation set assembled (~600 pages, 14 documents in `C:\IT-Stack\docs\`)
- [x] `PROJECT-FRAMEWORK-TEMPLATE.md` revised for IT-Stack

---

## Phase 1: GitHub Organization Bootstrap

> **Status: ✅ COMPLETE** — 26 repos · 5 projects · 39 labels · 4 milestones · 120 issues

### 1.1 Organization-Level `.github` Repository

- [x] Create repository: `github.com/it-stack-dev/.github`
- [x] Create `profile/README.md` — org homepage
- [x] Create `CONTRIBUTING.md` — contribution guidelines
- [x] Create `CODE_OF_CONDUCT.md` — Contributor Covenant
- [x] Create `SECURITY.md` — vulnerability reporting policy
- [x] Create `workflows/ci.yml` — reusable CI workflow
- [x] Create `workflows/release.yml` — reusable release workflow
- [x] Create `workflows/security-scan.yml` — Trivy security scanning
- [x] Create `workflows/docker-build.yml` — Docker image build & push to GHCR

### 1.2 Meta Repositories (6)

- [x] Create `it-stack-docs` — MkDocs site live at https://it-stack-dev.github.io/it-stack-docs/
  - [x] Initialize git in `C:\IT-Stack\`
  - [x] `git remote add origin https://github.com/it-stack-dev/it-stack-docs.git`
  - [x] Push `main` branch + GitHub Pages enabled
- [x] Create `it-stack-installer` — bootstrap & automation scripts
- [x] Create `it-stack-testing` — integration & e2e testing suite
- [x] Create `it-stack-ansible` — **Full Ansible roles: common, freeipa·keycloak·postgresql·redis·traefik** (76 files, 3,332 lines)
- [x] Create `it-stack-terraform` — Terraform modules (VM provisioning)
- [x] Create `it-stack-helm` — Helm charts for all services

### 1.3 GitHub Projects (5)

- [x] Create **Project #6** — "Phase 1: Foundation" (Kanban + Table + Roadmap views)
- [x] Create **Project #7** — "Phase 2: Collaboration"
- [x] Create **Project #8** — "Phase 3: Back Office"
- [x] Create **Project #9** — "Phase 4: IT Management"
- [x] Create **Project #10** — "Master Dashboard" (all modules)

### 1.4 Organization-Level Labels

- [x] 39 labels × 20+ repos — `lab`, `module-01…20`, `phase-1…4`, category tags, priority, status

### 1.5 Milestones

- [x] Create milestone: "Phase 1: Foundation" (target: Week 4)
- [x] Create milestone: "Phase 2: Collaboration" (target: Week 8)
- [x] Create milestone: "Phase 3: Back Office" (target: Week 14)
- [x] Create milestone: "Phase 4: IT Management" (target: Week 20)

---

## Phase 2: Local Development Environment

> **Status: ✅ COMPLETE** — `C:\IT-Stack\it-stack-dev\` · 35 subdirs · all 6 meta repos cloned

- [x] Created `C:\IT-Stack\it-stack-dev\` with 35 subdirectories
  - [x] `repos\meta\`, `repos\01-identity\` through `repos\07-infrastructure\`
  - [x] `workspaces\`, `deployments\`, `lab-environments\`, `configs\`, `scripts\`, `logs\`
- [x] All 6 meta repos cloned into `repos\meta\`
- [x] `claude.md` — AI assistant context file
- [x] `README.md` — Dev environment quick start
- [x] `configs\global\it-stack.yaml` — Global config (all 8 servers, subdomains, ports, versions)
- [x] `it-stack.code-workspace` — VS Code multi-root workspace
- [~] PowerShell profile aliases — optional, not yet done
- [x] Tools verified: Git · GitHub CLI · Docker Desktop

---

## Phase 3: Documentation Migration

> **Status: ✅ COMPLETE** — 14 docs migrated · MkDocs site live · numbered structure committed

### 3.1 Create Standard Docs Folder Structure

- [x] `docs/01-core/` — category specs
- [x] `docs/02-implementation/` — deployment and integration guides
- [x] `docs/03-labs/` — lab manuals (parts 1–5)
- [x] `docs/04-github/` — org structure and setup guides
- [x] `docs/05-guides/` — master index, AI instructions
- [x] `docs/06-technical-reference/` — deep technical docs
- [x] `docs/07-architecture/` — ADRs and diagrams

### 3.2 Migrate & Number Existing Documents

| New Path | Source Document |
|----------|----------------|
| `docs/05-guides/01-master-index.md` | `MASTER-INDEX.md` |
| `docs/05-guides/02-lab-manual-structure.md` | `LAB_MANUAL_STRUCTURE.md` |
| `docs/02-implementation/03-lab-deployment-plan.md` | `lab-deployment-plan.md` |
| `docs/02-implementation/04-lab-deployment-plan-v2.md` | `lab-deployment-plan(1).md` |
| `docs/06-technical-reference/05-stack-deployment.md` | `enterprise-it-stack-deployment.md` |
| `docs/02-implementation/06-stack-complete-v2.md` | `enterprise-stack-complete-v2.md` |
| `docs/03-labs/07-lab-manual-part1.md` | `enterprise-it-lab-manual.md` |
| `docs/03-labs/08-lab-manual-part2.md` | `enterprise-it-lab-manual-part2.md` |
| `docs/03-labs/09-lab-manual-part3.md` | `enterprise-it-lab-manual-part3.md` |
| `docs/03-labs/10-lab-manual-part4.md` | `enterprise-it-lab-manual-part4.md` |
| `docs/03-labs/11-lab-manual-part5.md` | `enterprise-lab-manual-part5.md` |
| `docs/02-implementation/12-integration-guide.md` | `integration-guide-complete.md` |
| `docs/04-github/13-github-guide.md` | `IT-STACK-GITHUB-GUIDE.md` (new) |
| `docs/05-guides/14-project-framework.md` | `PROJECT-FRAMEWORK-TEMPLATE.md` |

- [x] All 14 documents migrated to numbered paths
- [x] `MASTER-INDEX.md` updated with new paths
- [x] `docs/README.md` created
- [~] Front-matter on individual docs — optional, not yet added

### 3.3 Create Missing Category Spec Documents (7)

- [ ] `docs/01-core/01-identity.md` — FreeIPA + Keycloak architecture
- [ ] `docs/01-core/02-database.md` — PostgreSQL + Redis + Elasticsearch
- [ ] `docs/01-core/03-collaboration.md` — Nextcloud + Mattermost + Jitsi
- [ ] `docs/01-core/04-communications.md` — iRedMail + FreePBX + Zammad
- [ ] `docs/01-core/05-business.md` — SuiteCRM + Odoo + OpenKM
- [ ] `docs/01-core/06-it-management.md` — Taiga + Snipe-IT + GLPI
- [ ] `docs/01-core/07-infrastructure.md` — Traefik + Zabbix + Graylog

---

## Phase 4: Module Scaffolding — Deployment Phase 1 (Foundation)

> **Status: ✅ COMPLETE** — 5 repos scaffolded · 30 issues filed · CI passing · Labs 01–05 real content done (25/120 labs)

- [x] `it-stack-freeipa` — Labs 01–03 + **`docker-compose.sso.yml` + `test-lab-01-04.sh`** (LDAP federation) + **`docker-compose.integration.yml` + `test-lab-01-05.sh`** (FreeIPA+KC+PG+Redis ecosystem) + CI ✅
- [x] `it-stack-keycloak` — Labs 01–03 + **`docker-compose.sso.yml` + `test-lab-02-04.sh`** (OIDC/SAML hub) + **`docker-compose.integration.yml` + `test-lab-02-05.sh`** (OpenLDAP federation+MailHog+multi-app) + CI ✅
- [x] `it-stack-postgresql` — Labs 01–03 + **`docker-compose.sso.yml` + `test-lab-03-04.sh`** (pgAdmin+oauth2-proxy) + **`docker-compose.integration.yml` + `test-lab-03-05.sh`** (PG multi-DB+Redis+KC+Traefik+Prometheus) + CI ✅
- [x] `it-stack-redis` — Labs 01–03 + **`docker-compose.sso.yml` + `test-lab-04-04.sh`** (redis-commander+oauth2-proxy) + **`docker-compose.integration.yml` + `test-lab-04-05.sh`** (cache+session+LRU+keyspace+KC+Traefik) + CI ✅
- [x] `it-stack-traefik` — Labs 01–03 + **`docker-compose.sso.yml` + `test-lab-18-04.sh`** (ForwardAuth) + **`docker-compose.integration.yml` + `test-lab-18-05.sh`** (ForwardAuth+KC+oauth2-proxy+Prometheus) + CI ✅

All 5 repos have:
- [x] Full directory structure, manifest YAML, Makefile, Dockerfile
- [x] 6 Docker Compose files (standalone + lan + advanced + sso + integration + **production real**)
- [x] 6 lab test scripts (Labs 01–06 all real and complete)
- [x] 3 GitHub Actions workflows: `ci.yml`, `release.yml`, `security.yml`
- [x] `lab-01` through `lab-06-smoke` CI jobs (all 5 modules)
- [x] CI/ShellCheck passing (all 5 green)

### 4.2 Lab Issues (30 total)

- [x] 30 issues created (6 labs × 5 repos), all labeled and milestoned
- [x] All added to GitHub Project #6 (Phase 1: Foundation) and #10 (Master Dashboard)

### 4.3 Ansible (it-stack-ansible)

- [x] `roles/common` — base OS hardening, sysctl, locale, Docker, NTP
- [x] `roles/freeipa` — install + DNS + realm + admin user
- [x] `roles/postgresql` — install + users + databases + pg_hba
- [x] `roles/redis` — install + auth + AOF persistence + maxmemory
- [x] `roles/keycloak` — deploy + realm + LDAP federation
- [x] `roles/traefik` — deploy + TLS + Let's Encrypt + dashboard
- [x] `site.yml` + 5 targeted playbooks + `inventory/` (8 servers) + `vault.yml.template`

---

## Phase 5: Module Scaffolding — Deployment Phase 2 (Collaboration)

> **Status: ✅ LAB 01 COMPLETE** — repos scaffolded · 30 issues filed · Lab 01 (Standalone) fully implemented for all 5 modules

- [x] `it-stack-nextcloud` — Lab 01 done · SQLite standalone · occ/WebDAV/OCS tests · CI updated ✅
- [x] `it-stack-mattermost` — Lab 01 done · PG sidecar · API/team/channel/post tests · CI updated ✅
- [x] `it-stack-jitsi` — Lab 01 done · 4-container stack · TLS/BOSH/config.js tests · CI updated ✅
- [x] `it-stack-iredmail` — Lab 01 done · SMTP/IMAP/webmail · Postfix/Dovecot/MariaDB tests · CI updated ✅
- [x] `it-stack-zammad` — Lab 01 done · PG+ES+memcached · API/railsserver/scheduler tests · CI updated ✅
- [x] 30 issues filed, added to Project #7 + #10
- [x] Real `docker-compose.standalone.yml` + `test-lab-XX-01.sh` written and pushed to main

---

## Phase 6: Module Scaffolding — Deployment Phase 3 (Back Office)

> **Status: 🟡 IN PROGRESS** — Lab 01 complete for all 4 modules · Lab 02–06 pending

- [x] `it-stack-freepbx` — Lab 01 ✅ (compose + test + CI) · Lab 02–06 pending
- [x] `it-stack-suitecrm` — Lab 01 ✅ (compose + test + CI) · Lab 02–06 pending
- [x] `it-stack-odoo` — Lab 01 ✅ (compose + test + CI) · Lab 02–06 pending
- [x] `it-stack-openkm` — Lab 01 ✅ (compose + test + CI) · Lab 02–06 pending
- [x] 24 issues filed, added to Project #8 + #10
- [x] Write real `docker-compose.standalone.yml` + `test-lab-XX-01.sh` ✅ (Sprint 13 complete)

---

## Phase 7: Module Scaffolding — Deployment Phase 4 (IT Management)

> **Status: 🟡 IN PROGRESS** — Lab 01 complete for all 4 modules · Lab 02–06 pending

- [x] `it-stack-taiga` — scaffolded · 6 compose stubs · 6 lab script stubs · CI ✅
- [x] `it-stack-snipeit` — scaffolded · 6 compose stubs · 6 lab script stubs · CI ✅
- [x] `it-stack-glpi` — scaffolded · 6 compose stubs · 6 lab script stubs · CI ✅
- [x] `it-stack-elasticsearch` — scaffolded · 6 compose stubs · 6 lab script stubs · CI ✅
- [x] `it-stack-zabbix` — scaffolded · 6 compose stubs · 6 lab script stubs · CI ✅
- [x] `it-stack-graylog` — scaffolded · 6 compose stubs · 6 lab script stubs · CI ✅
- [x] 36 issues filed, added to Project #9 + #10
- [x] Write real `docker-compose.standalone.yml` + `test-lab-XX-01.sh` ✅ (Sprint 13 complete)

---

## CI/CD & Automation Setup

> **Status: ✅ WORKFLOWS COMPLETE** — 3 workflows × 20 repos = 60 workflow files pushed and passing

### Per-Repository CI/CD

- [x] `.github/workflows/ci.yml` — ShellCheck · Compose validate · Trivy config scan · Lab 01 smoke test
- [x] `.github/workflows/release.yml` — Docker build + GHCR push + GitHub Release on semver tags
- [x] `.github/workflows/security.yml` — Weekly Trivy filesystem + config scan, SARIF → GitHub Security tab
- [x] All Phase 1 repos: CI passing ✅ (3 rounds of debugging required — see session notes)

### Automation Scripts (in `it-stack-installer`)

- [ ] `scripts/setup/install-tools.ps1` — Installs Git, gh, Docker, Helm, kubectl, Ansible
- [ ] `scripts/setup/setup-directory-structure.ps1` — Creates `C:\it-stack-dev\` tree
- [ ] `scripts/setup/setup-github.ps1` — Authenticates `gh`, sets default org
- [ ] `scripts/github/create-phase1-modules.ps1`
- [ ] `scripts/github/create-phase2-modules.ps1`
- [ ] `scripts/github/create-phase3-modules.ps1`
- [ ] `scripts/github/create-phase4-modules.ps1`
- [ ] `scripts/github/add-phase1-issues.ps1`
- [ ] `scripts/github/add-phase2-issues.ps1`
- [ ] `scripts/github/add-phase3-issues.ps1`
- [ ] `scripts/github/add-phase4-issues.ps1`
- [ ] `scripts/github/create-github-projects.ps1`
- [ ] `scripts/github/create-milestones.ps1`
- [ ] `scripts/github/apply-labels.ps1`
- [ ] `scripts/operations/clone-all-repos.ps1`
- [ ] `scripts/operations/update-all-repos.ps1`
- [ ] `scripts/utilities/create-repo-template.ps1` — Scaffold a new module repo
- [ ] `scripts/deployment/deploy-stack.sh` — Full stack deployment
- [ ] `scripts/testing/run-all-labs.sh` — Run all 120 lab tests

---

## Lab Testing Milestones

> Track lab completion status here as you work through the 6-lab progression for each module.
> **Format:** `[x]` = lab passed, `[ ]` = not started, `[-]` = in progress

### Category 01: Identity & Authentication

| Module | Lab 01 | Lab 02 | Lab 03 | Lab 04 | Lab 05 | Lab 06 |
|--------|--------|--------|--------|--------|--------|--------|
| 01 · FreeIPA | [x] | [x] | [x] | [x] | [x] | [x] |
| 02 · Keycloak | [x] | [x] | [x] | [x] | [x] | [x] |

### Category 02: Database & Cache

| Module | Lab 01 | Lab 02 | Lab 03 | Lab 04 | Lab 05 | Lab 06 |
|--------|--------|--------|--------|--------|--------|--------|
| 03 · PostgreSQL | [x] | [x] | [x] | [x] | [x] | [x] |
| 04 · Redis | [x] | [x] | [x] | [x] | [x] | [x] |
| 05 · Elasticsearch | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

### Category 03: Collaboration

| Module | Lab 01 | Lab 02 | Lab 03 | Lab 04 | Lab 05 | Lab 06 |
|--------|--------|--------|--------|--------|--------|--------|
| 06 · Nextcloud | [x] | [x] | [x] | [x] | [x] | [x] |
| 07 · Mattermost | [x] | [x] | [x] | [x] | [x] | [x] |
| 08 · Jitsi | [x] | [x] | [x] | [x] | [x] | [x] |

### Category 04: Communications

| Module | Lab 01 | Lab 02 | Lab 03 | Lab 04 | Lab 05 | Lab 06 |
|--------|--------|--------|--------|--------|--------|--------|
| 09 · iRedMail | [x] | [x] | [x] | [x] | [x] | [x] |
| 10 · FreePBX | [x] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 11 · Zammad | [x] | [x] | [x] | [x] | [x] | [x] |

### Category 05: Business Systems

| Module | Lab 01 | Lab 02 | Lab 03 | Lab 04 | Lab 05 | Lab 06 |
|--------|--------|--------|--------|--------|--------|--------|
| 12 · SuiteCRM | [x] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 13 · Odoo | [x] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 14 · OpenKM | [x] | [ ] | [ ] | [ ] | [ ] | [ ] |

### Category 06: IT & Project Management

| Module | Lab 01 | Lab 02 | Lab 03 | Lab 04 | Lab 05 | Lab 06 |
|--------|--------|--------|--------|--------|--------|--------|
| 15 · Taiga | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 16 · Snipe-IT | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 17 · GLPI | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

### Category 07: Infrastructure

| Module | Lab 01 | Lab 02 | Lab 03 | Lab 04 | Lab 05 | Lab 06 |
|--------|--------|--------|--------|--------|--------|--------|
| 18 · Traefik | [x] | [x] | [x] | [x] | [x] | [x] |
| 19 · Zabbix | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 20 · Graylog | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

**Lab Progress:** 64/120 (53.3%) — Phase 1 complete (30/120) ✅ · Phase 2 complete (30/120) ✅ · Phase 3 Lab 01 complete (4/120) ✅ · All 4 Phase 3 modules (FreePBX, SuiteCRM, Odoo, OpenKM) standalone done

---

## Integration Milestones

> From `integration-guide-complete.md` — cross-service integrations

### SSO Integrations (via Keycloak)
- [ ] FreeIPA ↔ Keycloak LDAP Federation
- [ ] Nextcloud ↔ Keycloak OIDC
- [ ] Mattermost ↔ Keycloak OIDC
- [ ] SuiteCRM ↔ Keycloak SAML
- [ ] Odoo ↔ Keycloak OIDC
- [ ] Zammad ↔ Keycloak OIDC
- [ ] GLPI ↔ Keycloak SAML
- [ ] Taiga ↔ Keycloak OIDC

### Business Workflow Integrations
- [ ] FreePBX ↔ SuiteCRM (click-to-call, call logging)
- [ ] FreePBX ↔ Zammad (automatic phone tickets)
- [ ] FreePBX ↔ FreeIPA (extension provisioning from directory)
- [ ] SuiteCRM ↔ Odoo (customer data sync)
- [ ] SuiteCRM ↔ Nextcloud (calendar sync)
- [ ] SuiteCRM ↔ OpenKM (document linking)
- [ ] Odoo ↔ FreeIPA (employee sync)
- [ ] Odoo ↔ Taiga (time tracking export)
- [ ] Odoo ↔ Snipe-IT (asset procurement)
- [ ] Taiga ↔ Mattermost (notifications)
- [ ] Snipe-IT ↔ GLPI (asset sync)
- [ ] GLPI ↔ Zammad (ticket sync / escalation)
- [ ] OpenKM ↔ Nextcloud (document storage backend)
- [ ] Zabbix ↔ Mattermost (infrastructure alerts)
- [ ] Graylog ↔ Zabbix (log-based alerting)

---

## Production Readiness

### Security Hardening
- [ ] TLS on all services (via Traefik Let's Encrypt or internal CA)
- [ ] All secrets managed via Ansible Vault (no plaintext credentials in repos)
- [ ] Firewall rules documented and applied
- [ ] SSH key-only authentication on all servers
- [ ] FreeIPA Kerberos tickets for internal service auth
- [ ] Regular security scan (Trivy) on all Docker images in CI

### Monitoring & Alerting
- [ ] Zabbix monitoring all 8-9 servers (CPU, RAM, disk, network)
- [ ] Zabbix service checks for all 20 services
- [ ] Graylog collecting logs from all services (Syslog / Filebeat)
- [ ] Alerting to Mattermost channel `#ops-alerts`
- [ ] On-call escalation policy documented

### Backup & Recovery
- [ ] PostgreSQL automated daily backup (all 10+ databases)
- [ ] Nextcloud file backup scheduled
- [ ] Configuration backups (Ansible playbook: `backup-configs.yml`)
- [ ] Backup restoration tested (RPO/RTO documented)
- [ ] Disaster recovery runbook written

### Capacity Planning
- [ ] Hardware/VM inventory documented
- [ ] Resource utilization baselines captured
- [ ] Growth projections (user count × service resource needs)
- [ ] Scale-out plan per service documented

### Documentation & Handover
- [ ] All `docs/` content pushed to `it-stack-docs` repo
- [ ] Runbooks for each service written or linked
- [ ] Network diagram (with IP addresses) in `docs/07-architecture/`
- [ ] User onboarding guide (how to get SSO account, access each service)
- [ ] Admin handover guide (passwords in vault, backup procedures)

---

## Quick Reference: Module → Repo Mapping

| # | Service | Repo | Category | Phase |
|---|---------|------|----------|-------|
| 01 | FreeIPA | `it-stack-freeipa` | identity | 1 |
| 02 | Keycloak | `it-stack-keycloak` | identity | 1 |
| 03 | PostgreSQL | `it-stack-postgresql` | database | 1 |
| 04 | Redis | `it-stack-redis` | database | 1 |
| 05 | Elasticsearch | `it-stack-elasticsearch` | database | 4 |
| 06 | Nextcloud | `it-stack-nextcloud` | collaboration | 2 |
| 07 | Mattermost | `it-stack-mattermost` | collaboration | 2 |
| 08 | Jitsi | `it-stack-jitsi` | collaboration | 2 |
| 09 | iRedMail | `it-stack-iredmail` | communications | 2 |
| 10 | FreePBX | `it-stack-freepbx` | communications | 3 |
| 11 | Zammad | `it-stack-zammad` | communications | 2 |
| 12 | SuiteCRM | `it-stack-suitecrm` | business | 3 |
| 13 | Odoo | `it-stack-odoo` | business | 3 |
| 14 | OpenKM | `it-stack-openkm` | business | 3 |
| 15 | Taiga | `it-stack-taiga` | it-management | 4 |
| 16 | Snipe-IT | `it-stack-snipeit` | it-management | 4 |
| 17 | GLPI | `it-stack-glpi` | it-management | 4 |
| 18 | Traefik | `it-stack-traefik` | infrastructure | 1 |
| 19 | Zabbix | `it-stack-zabbix` | infrastructure | 4 |
| 20 | Graylog | `it-stack-graylog` | infrastructure | 4 |

---

---

## Direction Decision

**Chosen path: Go deep on Phase 1 — complete Labs 01→06 for all 5 Phase 1 modules before writing Lab 01 for Phase 2.**

**Rationale:**
1. Phase 2 services (Nextcloud, Mattermost) *depend on* Phase 1 (PostgreSQL, Keycloak) — Phase 1 must be solid first
2. Lab 04 for Phase 1 *is* the SSO integration test — proves Keycloak and FreeIPA are production-ready
3. Lab 06 for PostgreSQL proves the database tier that everything else builds on
4. Completing Labs 01–06 for 5 small/well-understood services proves the lab methodology before applying it to 15 more complex services

**Sequence:**

| Sprint | Goal | Labs |
|--------|------|------|
| ~~Sprint 2~~ | ~~Phase 1 Lab 02 (external deps)~~ | ~~freeipa·keycloak·postgresql·redis·traefik Lab 02~~ ✅ |
| ~~Sprint 3~~ | ~~Phase 1 Lab 03 (advanced features)~~ | ~~freeipa·keycloak·postgresql·redis·traefik Lab 03~~ ✅ |
| ~~Sprint 4~~ | ~~Phase 1 Lab 04 (SSO integration)~~ | ~~freeipa·keycloak·postgresql·redis·traefik Lab 04~~ ✅ |
| ~~Sprint 5~~ | ~~Phase 1 Lab 05 (integrations)~~ | ~~All 5 Lab 05~~ ✅ |
| ~~Sprint 6~~ | ~~Phase 1 Lab 06 (production)~~ | ~~All 5 Lab 06 → Phase 1 complete~~ ✅ |
| ~~Sprint 7~~ | ~~Phase 2 Lab 01 (standalone)~~ | ~~nextcloud·mattermost·jitsi·iredmail·zammad Lab 01~~ ✅ |
| ~~Sprint 8~~ | ~~Phase 2 Lab 02 (external deps)~~ | ~~nextcloud·mattermost·jitsi·iredmail·zammad Lab 02~~ ✅ |
| ~~Sprint 9~~ | ~~Phase 2 Lab 03 (advanced features)~~ | ~~nextcloud·mattermost·jitsi·iredmail·zammad Lab 03~~ ✅ |
| ~~Sprint 10~~ | ~~Phase 2 Lab 04 (SSO integration)~~ | ~~nextcloud·mattermost·jitsi·iredmail·zammad Lab 04~~ ✅ |
| ~~Sprint 11~~ | ~~Phase 2 Lab 05 (integrations)~~ | ~~nextcloud·mattermost·jitsi·iredmail·zammad Lab 05~~ ✅ |
| ~~Sprint 12~~ | ~~Phase 2 Lab 06 (production deployment)~~ | ~~nextcloud·mattermost·jitsi·iredmail·zammad Lab 06~~ ✅ · Phase 2 COMPLETE 🎉 |
| Sprint 13 ✅ | Phase 3 Lab 01 (standalone) | freepbx·suitecrm·odoo·openkm Lab 01 done |
| Next session | Phase 3 Lab 02 (external deps) | freepbx·suitecrm·odoo·openkm Lab 02 |

---

**Document Version:** 1.8  
**Project:** IT-Stack | **Org:** it-stack-dev  
**Last Updated:** 2026-03-01 — Phase 3 Lab 01 COMPLETE (64/120 labs, 53.3%) — Sprint 13 done ✅
