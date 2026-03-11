# IT-Stack — Master TODO & Implementation Checklist
## Project: `it-stack` | GitHub Org: `it-stack-dev`
**Created:** February 27, 2026  
**Status:** Phases 0–7 Complete · ALL 120 Labs Scripted · Azure Testing: Phase 1 ✅ (18/18) · Phase 2 ✅ (20/20) · Phase 3 ✅ (20/20) · SSO Integrations ✅ (35/35) · Phase 4 ✅ (25/25) · Ansible Integrations ✅ (INT-03–23) · Local Docker Test Runner: Phase 1 ✅

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
- [x] Create `it-stack-ansible` — **Full Ansible roles: all 21 services, 20 playbooks, group_vars+host_vars, full site.yml** (161 files)
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

> **Status: ✅ COMPLETE** — 21 docs total · 14 migrated · 7 category specs written · MkDocs site live · numbered structure committed

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

- [x] `docs/01-core/01-identity.md` — FreeIPA + Keycloak architecture
- [x] `docs/01-core/02-database.md` — PostgreSQL + Redis + Elasticsearch
- [x] `docs/01-core/03-collaboration.md` — Nextcloud + Mattermost + Jitsi
- [x] `docs/01-core/04-communications.md` — iRedMail + FreePBX + Zammad
- [x] `docs/01-core/05-business.md` — SuiteCRM + Odoo + OpenKM
- [x] `docs/01-core/06-it-management.md` — Taiga + Snipe-IT + GLPI
- [x] `docs/01-core/07-infrastructure.md` — Traefik + Zabbix + Graylog

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
- [x] `roles/nextcloud` — deploy + Nginx + PHP-FPM + occ integration
- [x] `roles/mattermost` — deploy + systemd + PostgreSQL config
- [x] `roles/jitsi` — deploy + Prosody XMPP + JWT auth
- [x] `roles/iredmail` — deploy + Postfix + Dovecot + PostgreSQL lookups
- [x] `roles/zammad` — deploy + apt + Elasticsearch integration
- [x] `roles/elasticsearch` — deploy + cluster config + JVM heap
- [x] `roles/freepbx` — deploy + Asterisk + PJSIP transports
- [x] `roles/suitecrm` — deploy + Nginx + PHP-FPM + cron
- [x] `roles/odoo` — deploy + systemd + workers + PostgreSQL
- [x] `roles/openkm` — deploy + Tomcat/systemd + Java opts
- [x] `roles/taiga` — deploy + Gunicorn + LDAP + events
- [x] `roles/snipeit` — deploy + Laravel + PHP-FPM + env config
- [x] `roles/glpi` — deploy + Nginx + PHP-FPM + cron
- [x] `roles/zabbix` — deploy + server + frontend + agent config
- [x] `roles/graylog` — deploy + MongoDB + Elasticsearch integration
- [x] `site.yml` — full 20-service phased playbook (6 phases, 16 plays)
- [x] 20 targeted playbooks (one per service)
- [x] `inventory/` — 8 servers, group_vars (7 files), host_vars (5 files)
- [x] `vault/secrets.yml.example` — all 40+ vault variable stubs
- [x] `Makefile` — `deploy-phase2`, `deploy-phase3`, `deploy-phase4` group targets

---

## Phase 5: Module Scaffolding — Deployment Phase 2 (Collaboration)

> **Status: ✅ COMPLETE** — All 6 labs done · 5 modules · 30 labs · Phase 2 COMPLETE 🎉

- [x] `it-stack-nextcloud` — scaffolded · Lab 01 ✅ (SQLite standalone, occ/WebDAV/OCS tests) · Lab 02 ✅ (PostgreSQL + Redis external) · Lab 03 ✅ (PHP tuning, cron worker, resource limits) · Lab 04 ✅ (Keycloak OIDC, user_oidc) · Lab 05 ✅ (LDAP federation + OIDC, Redis sessions, cron worker) · Lab 06 ✅ (production: PHP 1G/512M, Redis persist, KC metrics)
- [x] `it-stack-mattermost` — scaffolded · Lab 01 ✅ (PG sidecar, API/team/channel/post tests) · Lab 02 ✅ (PostgreSQL + Redis external) · Lab 03 ✅ (advanced config, resource limits) · Lab 04 ✅ (Keycloak OIDC) · Lab 05 ✅ (LDAP sync + OIDC, MinIO S3) · Lab 06 ✅ (production: MM metrics :8067, MinIO S3 9110/9111, mm-prod-config vol)
- [x] `it-stack-jitsi` — scaffolded · Lab 01 ✅ (4-container stack, TLS/BOSH/config.js tests) · Lab 02 ✅ (external dependencies) · Lab 03 ✅ (advanced features, resource limits) · Lab 04 ✅ (JWT/JWKS via Keycloak) · Lab 05 ✅ (Traefik reverse proxy + Keycloak JWT, coturn TURN :3478) · Lab 06 ✅ (production: Traefik 8280/8209, JVB UDP 10002, coturn 3479)
- [x] `it-stack-iredmail` — scaffolded · Lab 01 ✅ (SMTP/IMAP/webmail, Postfix/Dovecot/MariaDB tests) · Lab 02 ✅ (external dependencies) · Lab 03 ✅ (advanced features, resource limits) · Lab 04 ✅ (Keycloak LDAP Federation) · Lab 05 ✅ (LDAP primary auth + Keycloak LDAP fed, Mailhog SMTP relay) · Lab 06 ✅ (production: ClamAV, Mailhog relay 9026, vmail+backup volumes)
- [x] `it-stack-zammad` — scaffolded · Lab 01 ✅ (PG+ES+memcached, API/railsserver/scheduler tests) · Lab 02 ✅ (external dependencies) · Lab 03 ✅ (advanced features, resource limits) · Lab 04 ✅ (Keycloak OIDC channel) · Lab 05 ✅ (LDAP user import + OIDC channel, Elasticsearch + Mailhog) · Lab 06 ✅ (production: Elasticsearch 2G, zammad-init pattern, Redis persist)
- [x] 30 issues filed, added to Project #7 + #10
- [x] Write real `docker-compose.standalone.yml` + `test-lab-XX-01.sh` ✅ (Sprint 7 complete)
- [x] Write real `docker-compose.lan.yml` + `test-lab-XX-02.sh` + `lab-02-smoke` CI ✅ (Sprint 8 complete)
- [x] Write real `docker-compose.advanced.yml` + `test-lab-XX-03.sh` + `lab-03-smoke` CI ✅ (Sprint 9 complete)
- [x] Write real `docker-compose.sso.yml` + `test-lab-XX-04.sh` + `lab-04-smoke` CI ✅ (Sprint 10 complete)
- [x] Write real `docker-compose.integration.yml` + `test-lab-XX-05.sh` + `lab-05-smoke` CI ✅ (Sprint 11 complete)
- [x] Write real `docker-compose.production.yml` + `test-lab-XX-06.sh` + `lab-06-smoke` CI ✅ (Sprint 12 complete)

---

## Phase 6: Module Scaffolding — Deployment Phase 3 (Back Office)

> **Status: ✅ COMPLETE** — All 6 labs done · 4 modules · 24 labs · Phase 3 COMPLETE 🎉

- [x] `it-stack-freepbx` — scaffolded · Lab 01 ✅ · Lab 02 ✅ · Lab 03 ✅ (AMI + recordings/MOH/voicemail + resource limits) · Lab 04 ✅ (Keycloak OIDC) · Lab 05 ✅ (SuiteCRM CTI + Zammad webhook) · Lab 06 ✅ (production: restart policy, resource limits)
- [x] `it-stack-suitecrm` — scaffolded · Lab 01 ✅ · Lab 02 ✅ · Lab 03 ✅ (Redis session cache + cron container + resource limits) · Lab 04 ✅ (Keycloak SAML) · Lab 05 ✅ (Odoo JSONRPC + Nextcloud CalDAV) · Lab 06 ✅ (production: restart policy, resource limits)
- [x] `it-stack-odoo` — scaffolded · Lab 01 ✅ · Lab 02 ✅ · Lab 03 ✅ (multi-worker + gevent longpolling + resource limits) · Lab 04 ✅ (Keycloak OIDC) · Lab 05 ✅ (WireMock API mocks) · Lab 06 ✅ (production: restart policy, resource limits)
- [x] `it-stack-openkm` — scaffolded · Lab 01 ✅ · Lab 02 ✅ · Lab 03 ✅ (Elasticsearch 8.x + resource limits) · Lab 04 ✅ (Keycloak SAML) · Lab 05 ✅ (WireMock API mocks) · Lab 06 ✅ (production: restart policy, resource limits)
- [x] 24 issues filed, added to Project #8 + #10
- [x] Write real `docker-compose.standalone.yml` + `test-lab-XX-01.sh` ✅ (Sprint 13 complete)
- [x] Write real `docker-compose.lan.yml` + `test-lab-XX-02.sh` + `lab-02-smoke` CI ✅ (Sprint 14 complete)
- [x] Write real `docker-compose.advanced.yml` + `test-lab-XX-03.sh` + `lab-03-smoke` CI ✅ (Sprint 15 complete)
- [x] Write real `docker-compose.sso.yml` + `test-lab-XX-04.sh` + `lab-04-smoke` CI ✅ (Sprint 16 complete)
- [x] Write real `docker-compose.integration.yml` + `test-lab-XX-05.sh` + `lab-05-smoke` CI ✅ (Sprint 17 complete)
- [x] Write real `docker-compose.production.yml` + `test-lab-XX-06.sh` + `lab-06-smoke` CI ✅ (Sprint 18 complete)

---

## Phase 7: Module Scaffolding — Deployment Phase 4 (IT Management)

> **Status: ✅ COMPLETE** — All 6 labs done for all 6 modules · 36/36 labs · Phase 4 COMPLETE 🎉

- [x] `it-stack-taiga` — scaffolded · Lab 01 ✅ · Lab 02 ✅ (PostgreSQL + Redis + Mailhog) · Lab 03 ✅ (async events worker + Redis persistence) · Lab 04 ✅ (Keycloak OIDC + OpenLDAP) · Lab 05 ✅ (WireMock Mattermost webhook mock) · Lab 06 ✅ (production: restart policy, resource limits, Celery events worker)
- [x] `it-stack-snipeit` — scaffolded · Lab 01 ✅ · Lab 02 ✅ (MariaDB + Mailhog) · Lab 03 ✅ (SESSION/CACHE_DRIVER=redis + queue worker) · Lab 04 ✅ (Keycloak SAML + OpenLDAP) · Lab 05 ✅ (WireMock Odoo REST mock) · Lab 06 ✅ (production: restart policy, resource limits, queue worker)
- [x] `it-stack-glpi` — scaffolded · Lab 01 ✅ · Lab 02 ✅ (MariaDB + Mailhog) · Lab 03 ✅ (dedicated cron scheduler container) · Lab 04 ✅ (Keycloak SAML + OpenLDAP) · Lab 05 ✅ (WireMock Zammad REST mock) · Lab 06 ✅ (production: restart policy, resource limits, cron container)
- [x] `it-stack-elasticsearch` — scaffolded · Lab 01 ✅ · Lab 02 ✅ (ES + Kibana LAN tier) · Lab 03 ✅ (ES+Kibana+Logstash pipeline + resource limits) · Lab 04 ✅ (Kibana OIDC + OpenLDAP) · Lab 05 ✅ (WireMock Graylog API mock) · Lab 06 ✅ (production: restart policy, resource limits, ILM env vars)
- [x] `it-stack-zabbix` — scaffolded · Lab 01 ✅ · Lab 02 ✅ (MySQL + Mailhog) · Lab 03 ✅ (Zabbix Agent2 self-monitoring) · Lab 04 ✅ (Keycloak SAML + OpenLDAP) · Lab 05 ✅ (WireMock Mattermost webhook mock) · Lab 06 ✅ (production: restart policy, resource limits, server+web)
- [x] `it-stack-graylog` — scaffolded · Lab 01 ✅ · Lab 02 ✅ (MongoDB + Elasticsearch) · Lab 03 ✅ (tuned heap + UDP syslog/GELF inputs + resource limits) · Lab 04 ✅ (Keycloak OIDC + OpenLDAP) · Lab 05 ✅ (WireMock Zabbix HTTP API mock) · Lab 06 ✅ (production: restart policy, resource limits, syslog+GELF UDP inputs)
- [x] 36 issues filed, added to Project #9 + #10
- [x] Write real `docker-compose.standalone.yml` + `test-lab-XX-01.sh` ✅ (Sprint 19 complete)
- [x] Write real `docker-compose.lan.yml` + `test-lab-XX-02.sh` + `lab-02-smoke` CI ✅ (Sprint 20 complete)
- [x] Write real `docker-compose.advanced.yml` + `test-lab-XX-03.sh` + `lab-03-smoke` CI ✅ (Sprint 21 complete)
- [x] Write real `docker-compose.sso.yml` + `test-lab-XX-04.sh` + `lab-04-smoke` CI ✅ (Sprint 22 complete)
- [x] Write real `docker-compose.integration.yml` + `test-lab-XX-05.sh` + `lab-05-smoke` CI ✅ (Sprint 23 complete)
- [x] Write real `docker-compose.production.yml` + `test-lab-XX-06.sh` + `lab-06-smoke` CI ✅ (Sprint 24 complete)

---

## CI/CD & Automation Setup

> **Status: ✅ WORKFLOWS COMPLETE** — 3 workflows × 20 repos = 60 workflow files pushed and passing

### Per-Repository CI/CD

- [x] `.github/workflows/ci.yml` — ShellCheck · Compose validate · Trivy config scan · Lab 01 smoke test
- [x] `.github/workflows/release.yml` — Docker build + GHCR push + GitHub Release on semver tags
- [x] `.github/workflows/security.yml` — Weekly Trivy filesystem + config scan, SARIF → GitHub Security tab
- [x] All Phase 1 repos: CI passing ✅ (3 rounds of debugging required — see session notes)

### Automation Scripts (in `it-stack-installer`)

- [x] `scripts/setup/install-tools.ps1` — Installs Git, gh, Docker, Helm, kubectl, Ansible
- [x] `scripts/setup/setup-directory-structure.ps1` — Creates `C:\it-stack-dev\` tree
- [x] `scripts/setup/setup-github.ps1` — Authenticates `gh`, sets default org
- [x] `scripts/github/create-phase1-modules.ps1`
- [x] `scripts/github/create-phase2-modules.ps1`
- [x] `scripts/github/create-phase3-modules.ps1`
- [x] `scripts/github/create-phase4-modules.ps1`
- [x] `scripts/github/add-phase1-issues.ps1`
- [x] `scripts/github/add-phase2-issues.ps1`
- [x] `scripts/github/add-phase3-issues.ps1`
- [x] `scripts/github/add-phase4-issues.ps1`
- [x] `scripts/github/create-github-projects.ps1`
- [x] `scripts/github/create-milestones.ps1`
- [x] `scripts/github/apply-labels.ps1`
- [x] `scripts/operations/clone-all-repos.ps1`
- [x] `scripts/operations/update-all-repos.ps1`
- [x] `scripts/utilities/create-repo-template.ps1` — Scaffold a new module repo
- [x] `scripts/deployment/deploy-stack.sh` — Full stack deployment
- [x] `scripts/testing/run-all-labs.sh` — Run all 120 lab tests
- [x] `scripts/testing/lab-phase1.sh` — Phase 1 standalone test runner (18 tests) · **18/18 PASS on Azure Standard_D4s_v4** ✅ (commit `e3ddab0`)
- [x] `scripts/testing/lab-phase2.sh` — Phase 2 standalone test runner (20 tests: Nextcloud·Mattermost·Jitsi·iRedMail·Zammad) · **20/20 PASS on Azure Standard_D4s_v4** ✅
- [x] `scripts/testing/lab-phase3.sh` — Phase 3 standalone test runner (20 tests: FreePBX·SuiteCRM·Odoo·OpenKM) · **20/20 PASS on Azure Standard_D4s_v4** ✅ (commit `7751fcc`)
- [x] `scripts/testing/lab-sso-integrations.sh` — SSO integration test runner (35 tests across FreeIPA·Keycloak·Nextcloud·Mattermost·Jitsi·iRedMail·Zammad·SuiteCRM·Odoo·Taiga+Snipe-IT+GLPI stubs) · **35/35 PASS on Azure Standard_D4s_v4** ✅
- [x] `scripts/testing/freeipa-patch/Dockerfile` — FreeIPA custom image for Docker 29.x + cgroupv2-only kernels (Fix 1: cgroupv2 RAM check; Fix 2: PrivateTmp=false in httpd.service)
- [x] `scripts/test-local-docker.ps1` — PowerShell local Docker test runner for all 4 phases
- [-] Local Docker test runner Phase 2 failures — Zammad healthcheck `[ ]`
- [-] Local Docker test runner Phase 3 failures — FreePBX init time `[ ]`
- [-] Local Docker test runner Phase 4 failures — Graylog/Snipe-IT healthcheck tuning `[ ]`

---

## Azure Lab Testing

> Track actual hardware validation of lab scripts on Azure VMs.
> These are distinct from lab *script* completion (all 120 done) — this tracks verifying scripts run correctly on target hardware.

### Azure VM: `lab-single` (Phase 1 — Standard_D4s_v4, Ubuntu 24.04, Docker 29.3)

| Module | Lab 01 (Azure) | Notes |
|--------|---------------|-------|
| 01 · FreeIPA | [x] ✅ | patched image (`it-stack-freeipa-patched:almalinux-9`), 390s install |
| 02 · Keycloak | [x] ✅ | HTTP 302, OIDC token, /health/ready |
| 03 · PostgreSQL | [x] ✅ | pg_isready, CRUD, multi-db |
| 04 · Redis | [x] ✅ | PING, SET/GET, LPUSH/LLEN, AOF |
| 18 · Traefik | [x] ✅ | file provider (Docker 29.x API incompatibility), /ping, dashboard, reverse proxy |

**Azure Phase 1 result: 18/18 PASS** (2026-03-07, commit `e3ddab0`)

### Azure VM Phase 2 — `lab-phase2.sh` ✅

| Module | Result | Notes |
|--------|--------|-------|
| 06 · Nextcloud | [x] ✅ | HTTP 200, WebDAV, OCS API |
| 07 · Mattermost | [x] ✅ | API ping, team/channel/post created |
| 08 · Jitsi | [x] ✅ | 4-container stack, TLS/BOSH/config.js |
| 09 · iRedMail | [x] ✅ | SMTP:25, IMAP:143, webmail |
| 11 · Zammad | [x] ✅ | Rails server, ES index, API token |

**Azure Phase 2 result: 20/20 PASS** (`lab-phase2.sh`)

### Azure VM Phase 3 — `lab-phase3.sh` ✅

| Module | Result | Notes |
|--------|--------|-------|
| 10 · FreePBX | [x] ✅ | Admin HTTP, Asterisk CLI, dashboard content |
| 12 · SuiteCRM | [x] ✅ | Apache, login page, config.php, DB |
| 13 · Odoo | [x] ✅ | Web client, XML-RPC, database list |
| 14 · OpenKM | [x] ✅ | Tomcat :8080, REST API (port check via /proc/net/tcp) |

**Azure Phase 3 result: 20/20 PASS** (2026-03-09, commit `7751fcc`)

### Azure VM SSO Integrations — `lab-sso-integrations.sh` ✅

**Azure SSO result: 35/35 PASS** (`lab-sso-integrations.sh`)

### Azure VM Phase 4 — `lab-phase4.sh` ✅

| Module | Result | Notes |
|--------|--------|-------|
| 05 · Elasticsearch | ✅ | single-node, xpack disabled, vm.max_map_count, index CRUD |
| 15 · Taiga | ✅ | PostgreSQL + Django back API + nginx front, wait_http polling |
| 16 · Snipe-IT | ✅ | MariaDB healthcheck, HTTP 200, branding |
| 17 · GLPI | ✅ | MariaDB + wait_http (no Docker healthcheck in image) |
| 19 · Zabbix | ✅ | PostgreSQL + web-nginx-pgsql, API jsonrpc v7.2.15 |
| 20 · Graylog | ✅ | MongoDB + ES 7.17, journal size 512mb, lbstatus ALIVE |

**Azure Phase 4 result: 25/25 PASS** (2026-03-10, commit `22fac0f`)

Key fixes: Taiga direct HTTP poll (Django migrations 8–10 min), Graylog journal size cap (`GRAYLOG_MESSAGE_JOURNAL_MAX_SIZE=512mb`) for disk-constrained labs, correct SHA256 hash for Graylog root password.

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
| 05 · Elasticsearch | [x] | [x] | [x] | [x] | [x] | [x] |

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
| 10 · FreePBX | [x] | [x] | [x] | [x] | [x] | [x] |
| 11 · Zammad | [x] | [x] | [x] | [x] | [x] | [x] |

### Category 05: Business Systems

| Module | Lab 01 | Lab 02 | Lab 03 | Lab 04 | Lab 05 | Lab 06 |
|--------|--------|--------|--------|--------|--------|--------|
| 12 · SuiteCRM | [x] | [x] | [x] | [x] | [x] | [x] |
| 13 · Odoo | [x] | [x] | [x] | [x] | [x] | [x] |
| 14 · OpenKM | [x] | [x] | [x] | [x] | [x] | [x] |

### Category 06: IT & Project Management

| Module | Lab 01 | Lab 02 | Lab 03 | Lab 04 | Lab 05 | Lab 06 |
|--------|--------|--------|--------|--------|--------|--------|
| 15 · Taiga | [x] | [x] | [x] | [x] | [x] | [x] |
| 16 · Snipe-IT | [x] | [x] | [x] | [x] | [x] | [x] |
| 17 · GLPI | [x] | [x] | [x] | [x] | [x] | [x] |

### Category 07: Infrastructure

| Module | Lab 01 | Lab 02 | Lab 03 | Lab 04 | Lab 05 | Lab 06 |
|--------|--------|--------|--------|--------|--------|--------|
| 18 · Traefik | [x] | [x] | [x] | [x] | [x] | [x] |
| 19 · Zabbix | [x] | [x] | [x] | [x] | [x] | [x] |
| 20 · Graylog | [x] | [x] | [x] | [x] | [x] | [x] |

**Lab Progress:** 120/120 (100.0%) — Phase 1 complete (30/120) ✅ · Phase 2 complete (30/120) ✅ · Phase 3 COMPLETE (24/120) ✅🎉 · **Phase 4 COMPLETE (36/120) ✅🎉 — ALL 120 LABS DONE!**

---

## Integration Milestones

> From `integration-guide-complete.md` — cross-service integrations  
> **GitHub Issues created** via `create-integration-issues.ps1` (Sprint 29) — checkboxes below track *implementation* status.

### SSO Integrations (via Keycloak)
- [x] FreeIPA ↔ Keycloak LDAP Federation  ← **INT-01 DONE** (Sprint 30: Ansible tasks + integration test)
- [x] Nextcloud ↔ Keycloak OIDC  ← **INT-02 DONE** (Sprint 31: Ansible tasks + integration test)
- [x] Mattermost ↔ Keycloak OIDC  ← **INT-03 DONE** (`roles/mattermost/tasks/keycloak-oidc.yml`, 172 lines; `it-stack-ansible` #1 closed)
- [x] SuiteCRM ↔ Keycloak SAML  ← **INT-04 DONE** (`roles/suitecrm/tasks/keycloak-saml.yml`, 98 lines; `it-stack-ansible` #2 closed)
- [x] Odoo ↔ Keycloak OIDC  ← **INT-05 DONE** (`roles/odoo/tasks/keycloak-oidc.yml`, 364 lines; `it-stack-ansible` #3 closed)
- [x] Zammad ↔ Keycloak OIDC  ← **INT-06 DONE** (`roles/zammad/tasks/keycloak-oidc.yml`, 241 lines; `it-stack-ansible` #4 closed)
- [x] GLPI ↔ Keycloak SAML  ← **INT-07 DONE** (`roles/glpi/tasks/keycloak-saml.yml`, 177 lines; `it-stack-ansible` #5 closed)
- [x] Taiga ↔ Keycloak OIDC  ← **INT-08 DONE** (`roles/taiga/tasks/keycloak-oidc.yml`, 142 lines; `it-stack-ansible` #6 closed)

### Business Workflow Integrations
- [x] FreePBX ↔ SuiteCRM (click-to-call, call logging)  ← **INT-09 DONE** (`roles/freepbx/tasks/suitecrm-cti.yml`, 89 lines; `it-stack-ansible` #7 closed)
- [x] FreePBX ↔ Zammad (automatic phone tickets)  ← **INT-10 DONE** (`roles/freepbx/tasks/zammad-webhook.yml`, 76 lines; `it-stack-ansible` #8 closed)
- [x] FreePBX ↔ FreeIPA (extension provisioning from directory)  ← **INT-11 DONE** (`roles/freepbx/tasks/freeipa-sync.yml`, 102 lines; `it-stack-ansible` #9 closed)
- [x] SuiteCRM ↔ Odoo (customer data sync)  ← **INT-12 DONE** (`roles/suitecrm/tasks/odoo-sync.yml`; `it-stack-ansible` #10 closed)
- [x] SuiteCRM ↔ Nextcloud (calendar sync)  ← **INT-13 DONE** (Sprint 43: nextcloud-caldav.yml + suitecrm-nextcloud-caldav.py.j2 + suitecrm-share.yml + compose WireMock nc-int-mock:8105 + SuiteCRM Phase 3f + Nextcloud Section 13)
- [x] SuiteCRM ↔ OpenKM (document linking)  ← **INT-14 DONE** (Sprints 26-35: openkm-docs.yml + suitecrm-openkm-docs.py.j2)
- [x] Odoo ↔ FreeIPA (employee sync)  ← **INT-15 DONE** (Sprints 26-35: freeipa-ldap.yml + odoo-freeipa-ldap.conf.j2 + setup.py.j2 + sync.timer.j2)
- [x] Odoo ↔ Taiga (time tracking export)  ← **INT-16 DONE** (Sprints 26-35: taiga-timetrack.yml + odoo-taiga-timetrack.py.j2)
- [x] Odoo ↔ Snipe-IT (asset procurement)  ← **INT-17 DONE** (Sprints 26-35: snipeit-assets.yml + odoo-snipeit-assets.py.j2)
- [x] Taiga ↔ Mattermost (notifications)  ← **INT-18 DONE** (Sprints 26-35: mattermost-webhook.yml — pure REST API, no template)
- [x] Snipe-IT ↔ GLPI (asset sync)  ← **INT-19 DONE** (Sprints 26-35: glpi-sync.yml + snipeit-glpi-sync.py.j2)
- [x] GLPI ↔ Zammad (ticket sync / escalation)  ← **INT-20 DONE** (Sprints 26-35: zammad-escalation.yml + glpi-zammad-escalation.php.j2 + glpi-zammad-sync.py.j2)
- [x] OpenKM ↔ Nextcloud (document storage backend)  ← **INT-21 DONE** (Sprints 26-35: nextcloud-storage.yml + openkm-nextcloud-bridge.py.j2)
- [x] Zabbix ↔ Mattermost (infrastructure alerts)  ← **INT-22 DONE** (Sprints 26-35: mattermost-alerts.yml + zabbix-mattermost-media.xml.j2)
- [x] Graylog ↔ Zabbix (log-based alerting)  ← **INT-23 DONE** (Sprints 26-35: zabbix-alerts.yml + graylog-zabbix-sender.sh.j2)

---

## Production Readiness

### Security Hardening
- [x] TLS on all services (via Traefik internal CA)  ← `playbooks/tls-setup.yml` + `make tls`
- [x] All secrets managed via Ansible Vault (no plaintext credentials in repos)
- [x] Firewall rules documented and applied  ← `roles/common/tasks/firewall.yml` + UFW per-host
- [x] SSH key-only authentication on all servers  ← `playbooks/harden.yml` + `vault_ssh_authorized_keys`
- [ ] FreeIPA Kerberos tickets for internal service auth
- [ ] Regular security scan (Trivy) on all Docker images in CI

### Monitoring & Alerting
- [ ] Zabbix monitoring all 8-9 servers (CPU, RAM, disk, network)
- [ ] Zabbix service checks for all 20 services
- [ ] Graylog collecting logs from all services (Syslog / Filebeat)
- [x] Alerting to Mattermost channel `#ops-alerts`  ← **INT-22/23 DONE** (`roles/zabbix/tasks/mattermost-alerts.yml` 135 lines + `roles/graylog/tasks/zabbix-alerts.yml` 126 lines; `it-stack-ansible` #13 closed)
- [ ] On-call escalation policy documented

### Backup & Recovery
- [x] PostgreSQL automated daily backup (all 10+ databases)  ← `playbooks/backup.yml` Play 1 + cron 02:00 UTC
- [x] Nextcloud file backup scheduled  ← `playbooks/backup.yml` Play 2 + cron 03:00 UTC
- [x] Configuration backups (Ansible playbook: `playbooks/backup.yml`)  ← Play 3 + optional GPG encrypt
- [ ] Backup restoration tested (RPO/RTO documented)
- [x] Disaster recovery runbook written  ← `docs/05-guides/17-admin-runbook.md`

### Capacity Planning
- [x] Hardware/VM inventory documented  ← `docs/02-implementation/15-capacity-planning.md`
- [x] Resource utilization baselines captured  ← service RAM/CPU table in capacity-planning.md
- [x] Growth projections (user count × service resource needs)  ← 50/100/200/500/1000-user tables
- [x] Scale-out plan per service documented  ← scale-out plan table in capacity-planning.md

### Documentation & Handover
- [x] All `docs/` content pushed to `it-stack-docs` repo  ← **DONE** (55/55 docs files verified tracked in git, confirmed 2026-03-10)
- [x] Runbooks for each service written or linked  ← `docs/05-guides/17-admin-runbook.md`
- [x] Network diagram (with IP addresses) in `docs/07-architecture/`
- [x] User onboarding guide (how to get SSO account, access each service)  ← `docs/05-guides/16-user-onboarding.md`
- [x] Admin handover guide (passwords in vault, backup procedures)  ← `docs/05-guides/17-admin-runbook.md`

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
| Sprint 15 ✅ | Phase 3 Lab 03 (advanced features) | freepbx·suitecrm·odoo·openkm Lab 03 done |
| Sprint 16 ✅ | Phase 3 Lab 04 (SSO integration) | freepbx·suitecrm·odoo·openkm Lab 04 done |
| Sprint 17 ✅ | Phase 3 Lab 05 (advanced integration) | freepbx·suitecrm·odoo·openkm Lab 05 done |
| Sprint 18 ✅ | Phase 3 Lab 06 (production deployment) | freepbx·suitecrm·odoo·openkm Lab 06 done — **Phase 3 COMPLETE 🎉** |
| Sprint 19 ✅ | Phase 4 Lab 01 (standalone) | taiga·snipeit·glpi·elasticsearch·zabbix·graylog Lab 01 done |
| Sprint 20 ✅ | Phase 4 Lab 02 (external deps) | taiga·snipeit·glpi·elasticsearch·zabbix·graylog Lab 02 done |
| Sprint 21 ✅ | Phase 4 Lab 03 (advanced features) | taiga·snipeit·glpi·elasticsearch·zabbix·graylog Lab 03 done |
| Sprint 22 ✅ | Phase 4 Lab 04 (SSO integration) | taiga·snipeit·glpi·elasticsearch·zabbix·graylog Lab 04 done |
| Sprint 23 ✅ | Phase 4 Lab 05 (advanced integration) | taiga·snipeit·glpi·elasticsearch·zabbix·graylog Lab 05 done |
| Sprint 24 ✅ | Phase 4 Lab 06 (production deployment) | taiga·snipeit·glpi·elasticsearch·zabbix·graylog Lab 06 done — **PHASE 4 COMPLETE** 🎉 |
| Sprint 14 ✅ | Phase 3 Lab 02 (external deps) | freepbx·suitecrm·odoo·openkm Lab 02 done |

---

**Document Version:** 2.4  
**Project:** IT-Stack | **Org:** it-stack-dev  
**Last Updated:** 2026-03-10 — Ansible integration milestones confirmed complete: all 6 SSO (INT-03–08) + 3 FreePBX (INT-09–11) + SuiteCRM↔Odoo (INT-12) + alerting pipeline (INT-22/23); 11 `it-stack-ansible` GitHub issues closed (#1–10, #13); docs migration verified (55/55 files tracked)
