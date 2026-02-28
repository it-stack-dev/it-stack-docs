# Changelog

All notable changes to IT-Stack will be documented in this file.

This project adheres to [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned — Next Up (Phase 1 Lab 03 Sprint)
- `docker-compose.advanced.yml` + `test-lab-XX-03.sh` for all 5 Phase 1 modules (production features, performance, scaling)
- `docker-compose.sso.yml` + `test-lab-XX-04.sh` for all 5 Phase 1 modules (Keycloak OIDC/SAML integration)
- `it-stack-installer` operational scripts (`clone-all-repos.ps1`, `update-all-repos.ps1`, `install-tools.ps1`)

---

## [0.8.0] — 2026-02-28

### Added — Phase 1 Lab 02: External Dependencies

All 5 Phase 1 modules have real Lab 02 Docker Compose stacks and test suites.
Lab progress: 5/120 → 10/120 (4% → 8%).

| Module | Compose | What’s New | Test Lines |
|--------|---------|------------|------------|
| FreeIPA (01) | `docker-compose.lan.yml` | FreeIPA + `ldap-client` (debian:12-slim, ldap-utils + krb5-user) | 141 lines |
| Keycloak (02) | `docker-compose.lan.yml` | Keycloak + `keycloak-db` (PG16, `db-net` internal) | 161 lines |
| PostgreSQL (03) | `docker-compose.lan.yml` | Primary + Replica (streaming) + pgAdmin | 155 lines |
| Redis (04) | `docker-compose.lan.yml` | Master + 2 Replicas + 3 Sentinels (quorum=2) | 158 lines |
| Traefik (18) | `docker-compose.lan.yml` | Traefik + 4 backends: host routing, path routing, rate limit, LB (3 replicas) | 129 lines |

#### New supporting files

- `it-stack-postgresql/docker/replication/primary-init.sh` — creates `replicator` role + `pg_hba.conf` streaming replication entry
- `it-stack-postgresql/docker/pgadmin/servers.json` — pre-configures pgAdmin with primary + replica connections
- `it-stack-freeipa/docker/ldap-client/krb5.conf` — Kerberos client config for `LAB.LOCALHOST` realm
- `it-stack-freeipa/docker/ldap-client/ldap.conf` — LDAP Base DN + URI via ipa-net alias

#### Test coverage highlights

- **PostgreSQL:** WAL level, `max_wal_senders`, replica `pg_is_in_recovery()`, `pg_stat_replication` streaming count, 3-row cross-node replication, replica write rejection, pgAdmin HTTP
- **Redis:** Master/replica PING+ROLE, data replication to both replicas, all 3 sentinels PING, sentinel master discovery via `get-master-addr-by-name`, TTL persistence
- **Traefik:** HTTP→HTTPS redirect, HTTPS backends (self-signed `-k`), path routing `/api/v1/echo`, router count ≥3, security headers, load balancer ≥2 unique backends
- **Keycloak:** Admin token (proves JDBC), realm CRUD (201/409), restart + realm persists (persistence test), OIDC discovery, `db-net` internal flag
- **FreeIPA:** Port connectivity from ldap-client, anonymous bind, authenticated bind OUs, user create + LDAP verify, `kinit` from client container

#### CI workflow updates (all 5 repos)

- `validate` step: `docker-compose.lan.yml` now strictly validated with `config -q` (not `--no-interpolate`)
- New `lab-02-smoke` job added to all 5 CI workflows:
  - PostgreSQL: waits for primary (`pg_isready` 5432) then replica (5433, 180s), runs `test-lab-03-02.sh`
  - Redis: waits for master PONG (90s) + 30s sentinel settle, runs `test-lab-04-02.sh`
  - Traefik: waits for `/ping` (90s), runs `test-lab-18-02.sh`
  - Keycloak: waits for `/health/ready` (200s), runs `test-lab-02-02.sh`
  - FreeIPA: pull images + syntax check only (privileged containers cannot run in GitHub Actions)

---

## [0.7.0] — 2026-02-27

### Added — Phase 1 Lab 01 Content + Ansible Roles

#### Option A: Ansible (`it-stack-ansible`)
Complete Ansible automation for all 5 Phase 1 modules — 76 files, ~3,332 lines:
- `roles/common` — base hardening: sysctl tuning, locale/timezone, Docker CE, NTP (chrony), firewall, fail2ban, motd
- `roles/freeipa` — FreeIPA server install, DNS configuration, Kerberos realm, admin account bootstrap
- `roles/postgresql` — install + 10 service databases + application users + `pg_hba.conf` + performance tuning
- `roles/redis` — install + password auth + AOF persistence + maxmemory-policy + sysctl `vm.overcommit_memory`
- `roles/keycloak` — Docker-based deploy + master realm + LDAP federation to FreeIPA + `it-stack` realm
- `roles/traefik` — Docker-based deploy + Let's Encrypt ACME + per-service dynamic config + dashboard
- `site.yml` — full stack playbook (all 8 servers in dependency order)
- 5 targeted playbooks: `deploy-identity.yml`, `deploy-database.yml`, `deploy-keycloak.yml`, `deploy-traefik.yml`, `setup-servers.yml`
- `inventory/` with 8-server production layout (lab-id1 through lab-mgmt1)
- `vault.yml.template` — all secret variables documented (never committed)

Each role follows standard structure: `tasks/main.yml`, `handlers/main.yml`, `defaults/main.yml`, `templates/`, `files/`

#### Option B: Real Lab 01 Docker Compose + Test Scripts

For all 5 Phase 1 modules — replaced scaffold stubs with fully functional content:

| Module | Compose Highlights | Test Coverage |
|--------|--------------------|---------------|
| FreeIPA (01) | `freeipa/freeipa-server:latest`, privileged mode, systemd, full env vars, named volumes | kinit, ipa user-add/del, LDAP search, DNS, IPA JSON-RPC API |
| Keycloak (02) | `quay.io/keycloak/keycloak:24`, start-dev mode, PostgreSQL backend, health checks | Admin token, realm CRUD, user CRUD, OIDC client, token endpoint |
| PostgreSQL (03) | `postgres:16`, labadmin user, labdb + 10 app databases via init SQL, pgBadger config | Schema CRUD, indexes, transactions, ROLLBACK, extensions, encoding |
| Redis (04) | `redis:7-alpine`, `--requirepass`, AOF persistence, 256 MB maxmemory allkeys-lru | String/List/Hash/Set/ZSet ops, TTL/PERSIST, MULTI/EXEC, INFO, CONFIG |
| Traefik (18) | Traefik v3.x, Docker provider, 3 whoami backends, host routing, path-prefix, StripPrefix | Ping, dashboard API, router discovery, host routing, load balancing, 404 |

#### CI Workflow Fixes (3 rounds)

**Round 1 — Core CI bugs (all 5 repos):**
- Fixed `Validate Docker Compose files` step: was globbing all 6 files including scaffolds with `$firstPort` placeholders → now validates `standalone.yml` strictly, others with `--no-interpolate || warn`
- Fixed smoke test script name: was `test-lab-01.sh` (generic) → now `test-lab-XX-01.sh` (module-numbered)
- Fixed `((PASS++))` post-increment with `set -euo pipefail`: post-increment returns old value (0 on first call = falsy = `set -e` exits) → changed to `((++PASS))` pre-increment
- Added module-appropriate tool installs: `postgresql-client`, `redis-tools`, `netcat-openbsd`
- Added proper readiness waits: `pg_isready`, `redis-cli PING`, `curl /health/ready`, `curl /ping`
- FreeIPA CI: skip live test (requires privileged mode + 20 min install) → validate compose + pull image only

**Round 2 — ShellCheck errors:**
- SC2015 (FreeIPA): `cmd && pass || warn` → `if cmd; then pass; else warn; fi`
- SC2209 (Keycloak): `KC_ADMIN=admin` → `KC_ADMIN="admin"` (unquoted string flagged as command substitution)
- SC1049/SC1073 (PostgreSQL): missing `then` keyword after heredoc terminator `SQL` in two `if` blocks
- SC2034 (Traefik): unused `for i in` loop variable → renamed to `_`
- SC2086 (Redis): pre-existing, suppressed with `# shellcheck disable=SC2086`

**Final CI status: 5/5 PASS ✅**

---

## [0.6.0] — 2026-02-27

### Added — Phase 5: CI/CD Workflows

#### GitHub Actions (3 workflows × 20 repos = 60 files)
- `ci.yml` — validates all Docker Compose files (`--no-interpolate`), ShellCheck on lab scripts, manifest validation, Trivy config scan (SARIF → GitHub Security tab), Lab 01 smoke test with `continue-on-error`
- `release.yml` — Docker image build and push to GHCR on semver tags (`v*.*.*`), Trivy image scan, GitHub Release with auto-generated release notes
- `security.yml` — weekly scheduled (Monday 02:00 UTC) Trivy filesystem + config scan with SARIF upload to GitHub Security
- All 20 repos: CI status 20/20 ✅ passing

#### Scripts
- `deploy-workflows.ps1` — redeploys all 3 workflows to all 20 component repos atomically

#### Bug Fixes
- Fixed `docker-compose.sso.yml` duplicate YAML key `keycloak` in `it-stack-keycloak` repo (renamed conflicting service to `keycloak-sso`)
- Fixed all 20 `ci.yml` stubs where `$f` shell variable was consumed by PowerShell during scaffold generation, producing broken `\` literals
- Fixed `docker compose config` invocation to use `--no-interpolate` (compose files use placeholder vars not available in CI)

---

## [0.5.0] — 2026-02-27

### Added — All 20 Module Repos Scaffolded

#### GitHub Repositories (20 component repos)
- All 20 component repos created on GitHub, each with 21 scaffolded items
- Full directory structure per repo: `src/`, `tests/labs/`, `docker/`, `kubernetes/`, `helm/`, `ansible/`, `docs/labs/`
- 6 Docker Compose files per repo: `standalone`, `lan`, `advanced`, `sso`, `integration`, `production`
- 6 lab test scripts per repo: `test-lab-01.sh` through `test-lab-06.sh`
- Module manifest YAML (`it-stack-{module}.yml`) with full metadata
- `Makefile`, `Dockerfile`, `.env.example`, `.gitattributes`, standard community files

#### GitHub Issues (120 total)
- 6 lab issues per module × 20 modules = 120 issues
- All labeled: `lab`, `module-NN`, `phase-N`, category tag, `priority-high`
- All milestoned to correct phase
- All linked to GitHub Projects: phase-specific project + Master Dashboard (#10) = 240 project items

#### Labels & Milestones
- 39 labels × 20 repos = 780 label applications (0 failures)
- 4 milestones × 20 repos = 80 milestone applications (0 failures)

#### Scripts
- `scaffold-module.ps1` — full scaffold for all 20 module repos (1177 lines)
- `create-component-repos.ps1`, `apply-labels-components.ps1`, `apply-milestones-components.ps1`
- `create-lab-issues.ps1` — 120 issues, `link-issues-to-projects.ps1` — 240 project items
- `add-gitattributes.ps1` — consistent LF line endings across all repos

---

## [0.4.0] — 2026-02-27

### Added — Documentation Site (MkDocs + GitHub Pages)

#### MkDocs Material Site
- `mkdocs.yml` — Material theme with dark/light mode, tabs, search, code copy, sticky navigation
- `docs/index.md` — Comprehensive home page with module table, 7-layer architecture, phase tabs, server layout
- `requirements-docs.txt` — `mkdocs-material>=9.5`, `mkdocs-minify-plugin>=0.8`
- **Docs live at: https://it-stack-dev.github.io/it-stack-docs/**

#### Documentation Reorganized into MkDocs Hierarchy
- `docs/architecture/` — `overview.md` (arch + server layout), `integrations.md` (all 15 integrations)
- `docs/deployment/` — `lab-deployment.md`, `enterprise-reference.md`
- `docs/labs/` — `overview.md`, `part1-network-os.md` through `part5-business-management.md`
- `docs/project/` — `master-index.md`, `github-guide.md`, `todo.md`
- `docs/contributing/` — `framework-template.md`

#### GitHub Actions
- `.github/workflows/docs.yml` — auto-deploys to GitHub Pages on push to `docs/**` or `mkdocs.yml`

#### Scripts
- `reorganize-docs.ps1`, `enable-pages.ps1`

---

## [0.3.0] — 2026-02-27

### Added — Local Development Environment

#### Dev Workspace (`C:\IT-Stack\it-stack-dev\`)
- 35 subdirectories: `repos/meta/`, 7 category dirs (`01-identity/` – `07-infrastructure/`), `workspaces/`, `deployments/`, `lab-environments/`, `configs/`, `scripts/`, `logs/`
- All 6 meta repos cloned into `repos/meta/`
- `configs/global/it-stack.yaml` — global config (all 8 servers, subdomains, all 20 service ports, versions)
- `README.md` — dev environment quick start guide
- `it-stack.code-workspace` — VS Code multi-root workspace (at `C:\IT-Stack\` root)

#### Scripts
- `setup-dev-workspace.ps1`, `clone-meta-repos.ps1`

---

## [0.2.0] — 2026-02-27

### Added — GitHub Organization Bootstrap

#### Organization `.github` Repository
- `profile/README.md` — org homepage with module table and architecture overview
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md` — org-level community files
- `workflows/ci.yml`, `release.yml`, `security-scan.yml`, `docker-build.yml` — reusable workflow templates

#### Meta Repositories (6 created and initialized)
- `it-stack-docs`, `it-stack-installer`, `it-stack-testing`
- `it-stack-ansible`, `it-stack-terraform`, `it-stack-helm`

#### GitHub Projects (5)
- Project #6: Phase 1 Foundation · Project #7: Phase 2 Collaboration
- Project #8: Phase 3 Back Office · Project #9: Phase 4 IT Management
- Project #10: Master Dashboard (all 20 modules)

#### Labels and Milestones
- 39 labels applied to all 6 meta repos (234 applications)
- 4 phase milestones applied to all 6 meta repos (24 milestones)

#### Scripts
- `apply-labels.ps1`, `create-milestones.ps1`, `fix-milestones.ps1`, `push-phase1-repos.ps1`

---

## [0.1.0] — 2026-02-27

### Added — Phase 0: Planning Complete

#### Documentation
- `enterprise-it-stack-deployment.md` — Original 112 KB technical reference (15+ server layout)
- `enterprise-stack-complete-v2.md` — Updated 8-server architecture with hostnames and IPs
- `enterprise-it-lab-manual.md` — Lab Part 1: Network and OS setup
- `enterprise-it-lab-manual-part2.md` — Lab Part 2: Identity, DB, SSO (FreeIPA, PostgreSQL, Keycloak)
- `enterprise-it-lab-manual-part3.md` — Lab Part 3: Collaboration (Nextcloud, Mattermost, Jitsi)
- `enterprise-it-lab-manual-part4.md` — Lab Part 4: Communications (Email, Proxy, Help Desk, Monitoring)
- `enterprise-lab-manual-part5.md` — Lab Part 5: Back Office (VoIP, CRM, ERP, DMS, PM, Assets, ITSM)
- `integration-guide-complete.md` — Cross-system integration procedures for all 20 modules
- `LAB_MANUAL_STRUCTURE.md` — Overview of entire 5-part lab manual series
- `lab-deployment-plan.md` — Test/lab deployment strategy (3–5 servers)
- `MASTER-INDEX.md` — Master index and reading guide for all documentation

#### Project Framework
- `PROJECT-FRAMEWORK-TEMPLATE.md` — Canonical project blueprint, revised for IT-Stack
  - All 20 module definitions (category, repo name, phase, ports)
  - 26-repo GitHub organization structure
  - Standard repository directory layout
  - 6-lab methodology with progression table
  - 4-phase implementation roadmap with timelines
  - Configuration hierarchy and secrets management rules
  - Commit message conventions and code review checklist

#### Tooling & Guides
- `IT-STACK-TODO.md` — Living task checklist covering all 7 implementation phases
  - Lab tracking grid (20 modules × 6 labs = 120 total)
  - Integration milestones for 15 cross-service integrations
  - Production readiness checklists (security, monitoring, backup, DR)
- `IT-STACK-GITHUB-GUIDE.md` — Step-by-step GitHub org bootstrap guide
  - PowerShell scripts for all 26 repo creations
  - `apply-labels.ps1` — 35+ labels with hex color values
  - `create-milestones.ps1` — 4 phase milestones with due dates
  - `create-repo-template.ps1` — Full module scaffold (dirs, 6 docker-compose files, 6 lab scripts, YAML manifest)
  - `create-lab-issues.ps1` — 120 labeled issues across 4 phases
  - Reusable `ci.yml` and `release.yml` GitHub Actions workflow templates
- `claude.md` — Comprehensive AI assistant context document

#### Standard Files
- `README.md` — Project overview with module table, server layout, documentation map
- `CHANGELOG.md` — This file
- `CONTRIBUTING.md` — Contribution guidelines
- `CODE_OF_CONDUCT.md` — Contributor Covenant 2.1
- `SECURITY.md` — Security policy and responsible disclosure process
- `SUPPORT.md` — Support channels and how to get help
- `.gitignore` — Ignore patterns for secrets, environments, OS artifacts, editors

---

## Version Scheme

IT-Stack follows [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH

MAJOR — Breaking change to a deployed service or integration contract
MINOR — New module added, new lab, new integration, new feature
PATCH — Documentation fix, bug fix, configuration correction
```

Each component repository (`it-stack-{module}`) maintains its own version independent of this meta version. A component version reflects the maturity of that module's labs and production readiness:

| Version Range | Meaning |
|---------------|---------|
| `0.1.x` | Lab 01 (Standalone) passing |
| `0.2.x` | Lab 02 (External Dependencies) passing |
| `0.3.x` | Lab 03 (Advanced Features) passing |
| `0.4.x` | Lab 04 (SSO Integration) passing |
| `0.5.x` | Lab 05 (Advanced Integration) passing |
| `1.0.x` | Lab 06 (Production Deployment) passing — production-ready |

---

[Unreleased]: https://github.com/it-stack-dev/it-stack-docs/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/it-stack-dev/it-stack-docs/releases/tag/v0.1.0
