# IT-Stack — Master TODO & Implementation Checklist
## Project: `it-stack` | GitHub Org: `it-stack-dev`
**Created:** February 27, 2026  
**Last Updated:** February 27, 2026  
**Status:** Phases 0–5 Complete · Next: Ansible Playbooks

> This is the living task list for implementing the IT-Stack project using the framework defined in `PROJECT-FRAMEWORK-TEMPLATE.md`.  
> Check items off as you complete them. Each section maps to a Phase or infrastructure domain.

---

## Table of Contents

1. [Phase 0: Planning & Setup](#phase-0-planning--setup) — ✅ Complete
2. [Phase 1: GitHub Organization Bootstrap](#phase-1-github-organization-bootstrap) — ✅ Complete
3. [Phase 2: Local Development Environment](#phase-2-local-development-environment) — ✅ Complete
4. [Phase 3: Documentation Migration](#phase-3-documentation-migration) — ✅ Complete (MkDocs site)
5. [Phase 4: Module Scaffolding — Phase 1 (Foundation)](#phase-4-module-scaffolding--deployment-phase-1-foundation) — ✅ Complete
6. [Phase 5: Module Scaffolding — Phase 2 (Collaboration)](#phase-5-module-scaffolding--deployment-phase-2-collaboration) — ✅ Complete
7. [Phase 6: Module Scaffolding — Phase 3 (Back Office)](#phase-6-module-scaffolding--deployment-phase-3-back-office) — ✅ Complete
8. [Phase 7: Module Scaffolding — Phase 4 (IT Management)](#phase-7-module-scaffolding--deployment-phase-4-it-management) — ✅ Complete
9. [CI/CD & Automation Setup](#cicd--automation-setup) — ✅ Workflows complete
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

> **Status: ✅ COMPLETE** — 2026-02-27

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

- [x] Create `it-stack-docs` — all docs pushed @ `f71ee76`
  - [x] Initialize git in `C:\IT-Stack\`
  - [x] `git remote add origin https://github.com/it-stack-dev/it-stack-docs.git`
  - [x] Push `main` branch
- [x] Create `it-stack-installer` — bootstrap & automation scripts
- [x] Create `it-stack-testing` — integration & e2e testing suite
- [x] Create `it-stack-ansible` — Ansible playbooks for all 20 services
- [x] Create `it-stack-terraform` — Terraform modules (VM provisioning)
- [x] Create `it-stack-helm` — Helm charts for all services

### 1.3 GitHub Projects (5)

- [x] Create **Project #6** — "Phase 1: Foundation"
- [x] Create **Project #7** — "Phase 2: Collaboration"
- [x] Create **Project #8** — "Phase 3: Back Office"
- [x] Create **Project #9** — "Phase 4: IT Management"
- [x] Create **Project #10** — "Master Dashboard" (all modules)

### 1.4 Organization-Level Labels

- [x] 39 labels applied to all 6 meta repos (234 applications, 0 failures)
  - `lab`, `module-01`–`module-20`, `phase-1`–`phase-4`
  - Category, priority, and status labels

### 1.5 Milestones

- [x] "Phase 1: Foundation" milestone — all repos
- [x] "Phase 2: Collaboration" milestone — all repos
- [x] "Phase 3: Back Office" milestone — all repos
- [x] "Phase 4: IT Management" milestone — all repos

---

## Phase 2: Local Development Environment

> **Status: ✅ COMPLETE** — 2026-02-27

- [x] Created `C:\IT-Stack\it-stack-dev\` with 35 subdirectories
  - [x] `repos\meta\`, `repos\01-identity\` through `repos\07-infrastructure\`
  - [x] `workspaces\`, `deployments\`, `lab-environments\`, `configs\`, `scripts\`, `logs\`
- [x] Cloned all 6 meta repos into `C:\IT-Stack\it-stack-dev\repos\meta\`
- [x] Created `C:\IT-Stack\it-stack-dev\README.md` — dev environment quick start
- [x] Created `C:\IT-Stack\it-stack-dev\configs\global\it-stack.yaml` — global config
- [x] Created `it-stack.code-workspace` — VS Code multi-root workspace
- [ ] Add PowerShell aliases to profile (`it-stack-dev`, `it-stack-repos`, etc.)
- [ ] Install and verify all required tools:
  - [ ] Docker Desktop
  - [ ] kubectl, Helm, k3d
  - [ ] Ansible (WSL)
  - [ ] Terraform
  - [ ] Make (via Chocolatey or WSL)

---

## Phase 3: Documentation Migration

> **Status: ✅ COMPLETE** — 2026-02-27 (implemented as MkDocs site instead of numbered folder structure)

### What Was Done

- [x] Reorganized all 14 source docs into MkDocs hierarchy under `docs/`
- [x] Created `docs/architecture/` — `overview.md`, `integrations.md`
- [x] Created `docs/deployment/` — `lab-deployment.md`, `enterprise-reference.md`
- [x] Created `docs/labs/` — `overview.md`, `part1` through `part5`
- [x] Created `docs/project/` — `master-index.md`, `github-guide.md`, `todo.md`
- [x] Created `docs/contributing/` — `framework-template.md`
- [x] Created `docs/index.md` — comprehensive home page
- [x] Created `mkdocs.yml` — Material theme config
- [x] Created `.github/workflows/docs.yml` — auto-deploy to GitHub Pages
- [x] **Docs live at: https://it-stack-dev.github.io/it-stack-docs/**

### Not Done (lower priority given MkDocs approach)
- [ ] Category spec docs (`docs/01-core/*.md`) — 7 architecture deep-dives
- [ ] ADRs in `docs/07-architecture/`

---

## Phase 4: Module Scaffolding — Deployment Phase 1 (Foundation)

> **Status: ✅ COMPLETE** — 2026-02-27

- [x] `it-stack-freeipa` — Identity Provider
- [x] `it-stack-keycloak` — SSO Broker
- [x] `it-stack-postgresql` — Relational Database
- [x] `it-stack-redis` — Cache & Session Store
- [x] `it-stack-traefik` — Reverse Proxy & TLS

For each repo: full structure scaffolded, manifest, 6 docker-compose files, 6 lab scripts, 6 lab issues filed and linked to Project #6 + #10.

---

## Phase 5: Module Scaffolding — Deployment Phase 2 (Collaboration)

> **Status: ✅ COMPLETE** — 2026-02-27

- [x] `it-stack-nextcloud` — Collaboration Platform
- [x] `it-stack-mattermost` — Team Chat
- [x] `it-stack-jitsi` — Video Conferencing
- [x] `it-stack-iredmail` — Email Server
- [x] `it-stack-zammad` — Help Desk

All issues linked to Project #7 + #10.

---

## Phase 6: Module Scaffolding — Deployment Phase 3 (Back Office)

> **Status: ✅ COMPLETE** — 2026-02-27

- [x] `it-stack-freepbx` — VoIP PBX
- [x] `it-stack-suitecrm` — CRM
- [x] `it-stack-odoo` — ERP
- [x] `it-stack-openkm` — Document Management

All issues linked to Project #8 + #10.

---

## Phase 7: Module Scaffolding — Deployment Phase 4 (IT Management)

> **Status: ✅ COMPLETE** — 2026-02-27

- [x] `it-stack-taiga` — Project Management
- [x] `it-stack-snipeit` — Asset Management
- [x] `it-stack-glpi` — IT Service Management
- [x] `it-stack-elasticsearch` — Search & Log Index
- [x] `it-stack-zabbix` — Infrastructure Monitoring
- [x] `it-stack-graylog` — Log Management

All issues linked to Project #9 + #10.

**Total across all phases:** 20 repos · 120 issues · 240 project items · 780 label applications · 80 milestones

---

## CI/CD & Automation Setup

> **Status: ✅ Workflows complete (all 20 repos) — Installer scripts pending**

### Per-Repository CI/CD ✅

- [x] `.github/workflows/ci.yml` deployed to all 20 repos
  - Validates all Docker Compose files (`--no-interpolate`)
  - ShellCheck on all lab scripts
  - Validates module manifest YAML
  - Trivy config scan → SARIF → GitHub Security tab
  - Lab 01 smoke test with `continue-on-error: true`
- [x] `.github/workflows/release.yml` deployed to all 20 repos
  - Triggers on semver tags `v*.*.*`
  - Builds and pushes Docker image to GHCR with semver + SHA tags
  - Trivy image scan, GitHub Release with auto-generated notes
- [x] `.github/workflows/security.yml` deployed to all 20 repos
  - Weekly scheduled (Monday 02:00 UTC) Trivy filesystem + config scan
  - SARIF uploaded to GitHub Security tab
- [x] All 20 repos CI status: 20/20 ✅ passing
- [x] `deploy-workflows.ps1` — idempotent deployer for all 3 workflows × 20 repos

### Automation Scripts in `it-stack-installer` — Pending

- [ ] `scripts/setup/install-tools.ps1` — installs Git, gh, Docker, Helm, kubectl, Ansible
- [ ] `scripts/setup/setup-directory-structure.ps1`
- [ ] `scripts/setup/setup-github.ps1`
- [ ] `scripts/operations/clone-all-repos.ps1`
- [ ] `scripts/operations/update-all-repos.ps1`
- [ ] `scripts/deployment/deploy-stack.sh` — full stack deployment
- [ ] `scripts/testing/run-all-labs.sh` — run all 120 lab tests

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
- [ ] Runbooks for each service written or linked
- [ ] Network diagram (with IP addresses) in `docs/architecture/`
- [ ] User onboarding guide (how to get SSO account, access each service)
- [ ] Admin handover guide (passwords in vault, backup procedures)

---

**Document Version:** 1.1  
**Project:** IT-Stack | **Org:** it-stack-dev  
**Last Updated:** 2026-02-27 — Phases 0–5 complete

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
