# Changelog

All notable changes to IT-Stack will be documented in this file.

This project adheres to [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned — Phase 1: Foundation
- Scaffold `it-stack-freeipa` repository with full 6-lab structure
- Scaffold `it-stack-keycloak` repository with full 6-lab structure
- Scaffold `it-stack-postgresql` repository with full 6-lab structure
- Scaffold `it-stack-redis` repository with full 6-lab structure
- Scaffold `it-stack-traefik` repository with full 6-lab structure
- Create GitHub Projects (#1–#5) for all four phases plus master dashboard
- Apply organization-wide labels to all repos
- Create phase milestones with target dates
- GitHub Actions CI/CD workflows (ci.yml, release.yml) for all repos

### Planned — Phase 2: Collaboration
- Scaffold `it-stack-nextcloud`, `it-stack-mattermost`, `it-stack-jitsi`
- Scaffold `it-stack-iredmail`, `it-stack-zammad`
- Lab 04 SSO integration tests for all Phase 2 modules

### Planned — Phase 3: Back Office
- Scaffold `it-stack-freepbx`, `it-stack-suitecrm`, `it-stack-odoo`, `it-stack-openkm`

### Planned — Phase 4: IT Management
- Scaffold `it-stack-taiga`, `it-stack-snipeit`, `it-stack-glpi`
- Scaffold `it-stack-elasticsearch`, `it-stack-zabbix`, `it-stack-graylog`

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
