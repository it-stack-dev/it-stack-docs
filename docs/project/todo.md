# IT-Stack — Master TODO & Implementation Checklist
## Project: `it-stack` | GitHub Org: `it-stack-dev`
**Created:** February 27, 2026  
**Status:** Phase 0 Complete · Phase 1 Starting

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

> **Estimate:** 2–4 hours  
> **Prerequisites:** GitHub account with org `it-stack-dev`, GitHub CLI (`gh`) installed and authenticated

### 1.1 Organization-Level `.github` Repository

- [ ] Create repository: `github.com/it-stack-dev/.github`
- [ ] Create `profile/README.md` — org homepage (see template in `PROJECT-FRAMEWORK-TEMPLATE.md` Appendix A)
- [ ] Create `CONTRIBUTING.md` — contribution guidelines
- [ ] Create `CODE_OF_CONDUCT.md` — Contributor Covenant
- [ ] Create `SECURITY.md` — vulnerability reporting policy
- [ ] Create `workflows/ci.yml` — reusable CI workflow
- [ ] Create `workflows/release.yml` — reusable release workflow
- [ ] Create `workflows/security-scan.yml` — Trivy security scanning
- [ ] Create `workflows/docker-build.yml` — Docker image build & push to GHCR

### 1.2 Meta Repositories (6)

- [ ] Create `it-stack-docs` — push existing `C:\IT-Stack\docs\` content here
  - [ ] Initialize git in `C:\IT-Stack\`
  - [ ] `git remote add origin https://github.com/it-stack-dev/it-stack-docs.git`
  - [ ] Push `main` branch
- [ ] Create `it-stack-installer` — bootstrap & automation scripts
  - [ ] Add placeholder `README.md`
  - [ ] Add `install.sh` stub
  - [ ] Add PowerShell setup script stubs
- [ ] Create `it-stack-testing` — integration & e2e testing suite
- [ ] Create `it-stack-ansible` — Ansible playbooks for all 20 services
- [ ] Create `it-stack-terraform` — Terraform modules (VM provisioning)
- [ ] Create `it-stack-helm` — Helm charts for all services

### 1.3 GitHub Projects (5)

- [ ] Create **Project #1** — "Phase 1: Foundation" (Kanban + Table + Roadmap views)
- [ ] Create **Project #2** — "Phase 2: Collaboration"
- [ ] Create **Project #3** — "Phase 3: Back Office"
- [ ] Create **Project #4** — "Phase 4: IT Management"
- [ ] Create **Project #5** — "Master Dashboard" (all modules)

### 1.4 Organization-Level Labels

Apply to all repos via script:
- [ ] `lab` — all lab issues
- [ ] `module-01` … `module-20` — per-module labels
- [ ] `phase-1` … `phase-4` — deployment phase
- [ ] `identity` / `database` / `collaboration` / `communications` / `business` / `it-management` / `infrastructure`
- [ ] `priority-high` / `priority-med` / `priority-low`
- [ ] `status-todo` / `status-in-progress` / `status-done` / `status-blocked`

### 1.5 Milestones

- [ ] Create milestone: "Phase 1: Foundation" (target: Week 4)
- [ ] Create milestone: "Phase 2: Collaboration" (target: Week 8)
- [ ] Create milestone: "Phase 3: Back Office" (target: Week 14)
- [ ] Create milestone: "Phase 4: IT Management" (target: Week 20)

---

## Phase 2: Local Development Environment

> **Estimate:** 30–60 minutes

- [ ] Run `setup-directory-structure.ps1` to create `C:\it-stack-dev\`
  - [ ] `repos\meta\`, `repos\01-identity\`, `repos\02-database\`, `repos\03-collaboration\`
  - [ ] `repos\04-communications\`, `repos\05-business\`, `repos\06-it-management\`, `repos\07-infrastructure\`
  - [ ] `workspaces\current-sprint\`, `workspaces\labs-testing\`, `workspaces\integration\`
  - [ ] `deployments\local\`, `deployments\dev\`, `deployments\staging\`, `deployments\production\`
  - [ ] `lab-environments\tier-1-lab\`, `lab-environments\tier-1-school\`
  - [ ] `lab-environments\tier-2-department\`, `lab-environments\tier-3-enterprise\`
  - [ ] `configs\global\`, `configs\modules\`, `configs\environments\`, `configs\secrets\`
  - [ ] `scripts\setup\`, `scripts\github\`, `scripts\operations\`, `scripts\testing\`
  - [ ] `scripts\deployment\`, `scripts\utilities\`
  - [ ] `logs\application\`, `logs\infrastructure\`, `logs\testing\`
- [ ] Clone all 6 meta repos into `C:\it-stack-dev\repos\meta\`
- [ ] Create `C:\it-stack-dev\claude.md` — AI assistant context file
- [ ] Create `C:\it-stack-dev\README.md` — Dev environment quick start
- [ ] Create `C:\it-stack-dev\configs\global\it-stack.yaml` — Global config
- [ ] Add PowerShell aliases to profile (`it-stack-dev`, `it-stack-repos`, `it-stack-labs`, etc.)
- [ ] Install required tools (verify all present):
  - [ ] Git
  - [ ] GitHub CLI (`gh`) — authenticated to `it-stack-dev`
  - [ ] Docker Desktop
  - [ ] kubectl
  - [ ] Helm
  - [ ] k3d or minikube (local Kubernetes)
  - [ ] Ansible (WSL or native)
  - [ ] Terraform
  - [ ] Python 3.x
  - [ ] Make (via Chocolatey or WSL)

---

## Phase 3: Documentation Migration

> **Estimate:** 2–4 hours  
> **Goal:** Organize existing 14-doc set into the standard `docs/` hierarchy in `it-stack-docs`

### 3.1 Create Standard Docs Folder Structure

- [ ] Create `docs/01-core/` — one spec doc per category (7 docs)
- [ ] Create `docs/02-implementation/` — deployment and integration guides
- [ ] Create `docs/03-labs/` — lab framework, databases, indices
- [ ] Create `docs/04-github/` — org structure, setup automation, project guides
- [ ] Create `docs/05-guides/` — master organization guide, AI instructions
- [ ] Create `docs/06-technical-reference/` — deep technical docs
- [ ] Create `docs/07-architecture/` — ADRs and diagrams

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

- [ ] Copy/move each document to new path
- [ ] Update `MASTER-INDEX.md` with new paths and numbers
- [ ] Add front-matter (document number, category, date) to each doc
- [ ] Create `docs/README.md` — documentation index and quick navigation

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

> **Estimate:** 3–5 hours  
> **Modules:** freeipa (01), keycloak (02), postgresql (03), redis (04), traefik (18)  
> **Goal:** 5 repos created, 30 lab issues filed, all in GitHub Project #1

### 4.1 Create GitHub Repositories (Phase 1)

- [ ] `it-stack-freeipa` — Identity Provider
- [ ] `it-stack-keycloak` — SSO Broker
- [ ] `it-stack-postgresql` — Relational Database
- [ ] `it-stack-redis` — Cache & Session Store
- [ ] `it-stack-traefik` — Reverse Proxy & TLS

For each repo above:
- [ ] Create with `gh repo create it-stack-dev/REPO --public --description "DESC"`
- [ ] Add topics: `it-stack`, category tag, `module-NN`, `phase-1`, `self-hosted`, `open-source`
- [ ] Scaffold with `create-repo-template.ps1 -ModuleName NAME -Category CATEGORY`
- [ ] Initialize git, initial commit, push `main` and `develop` branches
- [ ] Create `it-stack-REPO.yml` manifest file
- [ ] Create `README.md` using template from `PROJECT-FRAMEWORK-TEMPLATE.md`
- [ ] Create 6 lab guide stubs in `docs/labs/`
- [ ] Create 6 `docker-compose.*.yml` files in `docker/`
- [ ] Create 6 `test-lab-XX.sh` scripts in `tests/labs/`
- [ ] Create `Makefile`

### 4.2 Create Lab Issues (Phase 1 — 30 total)

For each of the 5 repos × 6 labs:
- [ ] Lab 01: Standalone Deployment
- [ ] Lab 02: External Dependencies
- [ ] Lab 03: Advanced Features
- [ ] Lab 04: SSO Integration
- [ ] Lab 05: Advanced Integration
- [ ] Lab 06: Production Deployment

- [ ] Run `create-phase1-modules.ps1 -CreateIssues`
- [ ] Add all 30 issues to GitHub Project #1
- [ ] Apply labels to all issues (`lab`, `module-NN`, `phase-1`)

---

## Phase 5: Module Scaffolding — Deployment Phase 2 (Collaboration)

> **Modules:** nextcloud (06), mattermost (07), jitsi (08), iredmail (09), zammad (11)  
> **Goal:** 5 repos created, 30 lab issues in GitHub Project #2

- [ ] Create `it-stack-nextcloud` — Collaboration Platform (replaces M365)
- [ ] Create `it-stack-mattermost` — Team Chat (replaces Slack/Teams)
- [ ] Create `it-stack-jitsi` — Video Conferencing (replaces Zoom)
- [ ] Create `it-stack-iredmail` — Email Server (replaces Exchange)
- [ ] Create `it-stack-zammad` — Help Desk (replaces Zendesk)

For each repo: (same checklist as Phase 4 — scaffold, manifest, labs, issues)

- [ ] Run `create-phase2-modules.ps1 -CreateRepos`
- [ ] Run `create-phase2-modules.ps1 -CreateIssues`
- [ ] Add 30 issues to GitHub Project #2

---

## Phase 6: Module Scaffolding — Deployment Phase 3 (Back Office)

> **Modules:** freepbx (10), suitecrm (12), odoo (13), openkm (14)  
> **Goal:** 4 repos created, 24 lab issues in GitHub Project #3

- [ ] Create `it-stack-freepbx` — VoIP PBX (replaces RingCentral)
- [ ] Create `it-stack-suitecrm` — CRM (replaces Salesforce)
- [ ] Create `it-stack-odoo` — ERP (replaces SAP/QuickBooks)
- [ ] Create `it-stack-openkm` — Document Management (replaces SharePoint)

- [ ] Run `create-phase3-modules.ps1 -CreateRepos`
- [ ] Run `create-phase3-modules.ps1 -CreateIssues`
- [ ] Add 24 issues to GitHub Project #3

---

## Phase 7: Module Scaffolding — Deployment Phase 4 (IT Management)

> **Modules:** taiga (15), snipeit (16), glpi (17), elasticsearch (05), zabbix (19), graylog (20)  
> **Goal:** 6 repos created, 36 lab issues in GitHub Project #4

- [ ] Create `it-stack-taiga` — Project Management (replaces Jira)
- [ ] Create `it-stack-snipeit` — Asset Management
- [ ] Create `it-stack-glpi` — IT Service Management (replaces ServiceNow)
- [ ] Create `it-stack-elasticsearch` — Search & Log Index
- [ ] Create `it-stack-zabbix` — Infrastructure Monitoring
- [ ] Create `it-stack-graylog` — Log Management

- [ ] Run `create-phase4-modules.ps1 -CreateRepos`
- [ ] Run `create-phase4-modules.ps1 -CreateIssues`
- [ ] Add 36 issues to GitHub Project #4

---

## CI/CD & Automation Setup

> **Applies to all 20 component repos once created**

### Per-Repository CI/CD

- [ ] `.github/workflows/ci.yml` (inherit from org or copy)  
  - Triggers: push to `main`/`develop`, all PRs  
  - Jobs: unit tests → integration tests → Docker build  
- [ ] `.github/workflows/release.yml`  
  - Triggers: push tag `v*`  
  - Jobs: build & push image to GHCR → create GitHub Release  
- [ ] `.github/workflows/security-scan.yml`  
  - Triggers: push to `main`, weekly schedule  
  - Jobs: Trivy filesystem scan  

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
| 01 · FreeIPA | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 02 · Keycloak | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

### Category 02: Database & Cache

| Module | Lab 01 | Lab 02 | Lab 03 | Lab 04 | Lab 05 | Lab 06 |
|--------|--------|--------|--------|--------|--------|--------|
| 03 · PostgreSQL | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 04 · Redis | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 05 · Elasticsearch | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

### Category 03: Collaboration

| Module | Lab 01 | Lab 02 | Lab 03 | Lab 04 | Lab 05 | Lab 06 |
|--------|--------|--------|--------|--------|--------|--------|
| 06 · Nextcloud | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 07 · Mattermost | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 08 · Jitsi | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

### Category 04: Communications

| Module | Lab 01 | Lab 02 | Lab 03 | Lab 04 | Lab 05 | Lab 06 |
|--------|--------|--------|--------|--------|--------|--------|
| 09 · iRedMail | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 10 · FreePBX | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 11 · Zammad | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

### Category 05: Business Systems

| Module | Lab 01 | Lab 02 | Lab 03 | Lab 04 | Lab 05 | Lab 06 |
|--------|--------|--------|--------|--------|--------|--------|
| 12 · SuiteCRM | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 13 · Odoo | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 14 · OpenKM | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

### Category 06: IT & Project Management

| Module | Lab 01 | Lab 02 | Lab 03 | Lab 04 | Lab 05 | Lab 06 |
|--------|--------|--------|--------|--------|--------|--------|
| 15 · Taiga | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 16 · Snipe-IT | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 17 · GLPI | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

### Category 07: Infrastructure

| Module | Lab 01 | Lab 02 | Lab 03 | Lab 04 | Lab 05 | Lab 06 |
|--------|--------|--------|--------|--------|--------|--------|
| 18 · Traefik | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 19 · Zabbix | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| 20 · Graylog | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |

**Lab Progress:** 0/120 (0%)

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

**Document Version:** 1.0  
**Project:** IT-Stack | **Org:** it-stack-dev  
**Next Review:** After Phase 1 GitHub Bootstrap completion
