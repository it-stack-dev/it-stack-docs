# IT-Stack — Enterprise Open-Source IT Infrastructure

> **Complete enterprise IT platform built entirely from open-source software — $0 in software licensing.**

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen.svg)](docs/IT-STACK-TODO.md)
[![Modules](https://img.shields.io/badge/Modules-20%20Complete-green.svg)](https://github.com/orgs/it-stack-dev/repositories)
[![Labs](https://img.shields.io/badge/Labs-120%2F120%20PASS-success.svg)](docs/03-labs/)
[![Integrations](https://img.shields.io/badge/Integrations-23%2F23%20PASS-success.svg)](docs/02-implementation/12-integration-guide.md)
[![CI](https://img.shields.io/badge/CI-20%2F20%20passing-success.svg)](https://github.com/orgs/it-stack-dev/repositories)
[![Docs](https://img.shields.io/badge/Docs-GitHub%20Pages-informational.svg)](https://it-stack-dev.github.io/it-stack-docs/)

---

## What Is IT-Stack?

IT-Stack is a **production-ready enterprise IT platform** that replaces the major commercial SaaS subscriptions most organizations depend on. It targets 50–1,000+ users across 8–9 Ubuntu 24.04 servers and integrates 20 open-source services into a cohesive, SSO-connected platform.

---

## The Stack at a Glance

```
Layer 7: Infrastructure     — Traefik · Zabbix · Graylog
Layer 6: IT & Project Mgmt  — Taiga · Snipe-IT · GLPI
Layer 5: Business Systems    — SuiteCRM · Odoo · OpenKM
Layer 4: Communications      — iRedMail · FreePBX · Zammad
Layer 3: Collaboration       — Nextcloud · Mattermost · Jitsi
Layer 2: Database & Cache    — PostgreSQL · Redis · Elasticsearch
Layer 1: Identity & Security — FreeIPA · Keycloak
```

---

## What It Replaces

| Commercial Product | IT-Stack Replacement | ~Annual Savings (100 users) |
|--------------------|---------------------|------------------------------|
| Microsoft 365 | Nextcloud + iRedMail | $24,000 |
| Slack / Teams | Mattermost | $15,000 |
| Zoom | Jitsi | $24,000 |
| Salesforce | SuiteCRM | $90,000 |
| SAP / QuickBooks | Odoo | $50,000 |
| RingCentral | FreePBX | $36,000 |
| ServiceNow | GLPI + Zammad | $120,000 |
| Jira | Taiga | $12,000 |
| Active Directory | FreeIPA + Keycloak | $10,000 |
| Datadog / Splunk | Zabbix + Graylog | $25,000 |

---

## 20 Modules, 7 Categories

| # | Module | Category | Phase |
|---|--------|----------|-------|
| 01 | FreeIPA | identity | 1 |
| 02 | Keycloak | identity | 1 |
| 03 | PostgreSQL | database | 1 |
| 04 | Redis | database | 1 |
| 05 | Elasticsearch | database | 4 |
| 06 | Nextcloud | collaboration | 2 |
| 07 | Mattermost | collaboration | 2 |
| 08 | Jitsi | collaboration | 2 |
| 09 | iRedMail | communications | 2 |
| 10 | FreePBX | communications | 3 |
| 11 | Zammad | communications | 2 |
| 12 | SuiteCRM | business | 3 |
| 13 | Odoo | business | 3 |
| 14 | OpenKM | business | 3 |
| 15 | Taiga | it-management | 4 |
| 16 | Snipe-IT | it-management | 4 |
| 17 | GLPI | it-management | 4 |
| 18 | Traefik | infrastructure | 1 |
| 19 | Zabbix | infrastructure | 4 |
| 20 | Graylog | infrastructure | 4 |

---

## Repository Structure

This repository (`it-stack-docs`) is the documentation and bootstrap hub for the IT-Stack organization.

```
it-stack-docs/
├── docs/                          # MkDocs source — live at it-stack-dev.github.io/it-stack-docs
│   ├── index.md                   # Home page
│   ├── architecture/
│   │   ├── overview.md            # 8-server layout, 7-layer stack
│   │   └── integrations.md        # All 15 cross-service integrations
│   ├── deployment/
│   │   ├── lab-deployment.md      # Lab/test deployment (3–5 servers)
│   │   └── enterprise-reference.md # Full technical reference (112 KB)
│   ├── labs/
│   │   ├── overview.md            # 6-lab methodology
│   │   ├── part1-network-os.md    # Part 1: Network & OS
│   │   ├── part2-identity-database.md
│   │   ├── part3-collaboration.md
│   │   ├── part4-communications.md
│   │   └── part5-business-management.md
│   ├── project/
│   │   ├── master-index.md        # Documentation navigation
│   │   ├── github-guide.md        # GitHub org setup guide + scripts
│   │   └── todo.md                # Living task checklist
│   └── contributing/
│       └── framework-template.md  # Canonical project blueprint
├── mkdocs.yml                     # MkDocs Material config
├── requirements-docs.txt          # MkDocs dependencies
├── .github/workflows/docs.yml     # Auto-deploy to GitHub Pages
├── deploy-workflows.ps1           # CI/CD deployer (all 20 repos)
├── README.md                      # This file
├── CHANGELOG.md                   # Version history
├── CONTRIBUTING.md                # Contribution guidelines
├── CODE_OF_CONDUCT.md             # Community standards
├── SECURITY.md                    # Security policy
├── SUPPORT.md                     # How to get help
├── LICENSE                        # Apache 2.0
└── .gitignore
```

---

## Documentation Map

**Docs site:** https://it-stack-dev.github.io/it-stack-docs/

| Document | Purpose | Start Here If… |
|----------|---------|----------------|
| [docs/project/master-index.md](docs/project/master-index.md) | Full navigation guide | You want to understand the full scope |
| [docs/contributing/framework-template.md](docs/contributing/framework-template.md) | Conventions, patterns, automation | You're building or scaffolding a module |
| [docs/project/todo.md](docs/project/todo.md) | Task tracking checklist | You want to see what's done/in progress |
| [docs/project/github-guide.md](docs/project/github-guide.md) | GitHub org setup scripts | You're bootstrapping the GitHub org |
| [docs/architecture/overview.md](docs/architecture/overview.md) | 8-server architecture | You need server specs and IP layout |
| [docs/labs/overview.md](docs/labs/overview.md) | Lab methodology overview | You want to understand the 6-lab system |
| [docs/architecture/integrations.md](docs/architecture/integrations.md) | Cross-service integration | You're configuring service-to-service links |

---

## Implementation Phases

| Phase | Name | Timeline | Modules |
|-------|------|----------|---------|
| 1 | Foundation | Weeks 1–4 | FreeIPA, Keycloak, PostgreSQL, Redis, Traefik |
| 2 | Collaboration | Weeks 5–8 | Nextcloud, Mattermost, Jitsi, iRedMail, Zammad |
| 3 | Back Office | Weeks 9–14 | FreePBX, SuiteCRM, Odoo, OpenKM |
| 4 | IT Management | Weeks 15–20 | Taiga, Snipe-IT, GLPI, Elasticsearch, Zabbix, Graylog |

---

## 6-Lab Testing Methodology

Every module has exactly **6 labs** progressing from isolated to production-ready:

| Lab | Name | Purpose |
|-----|------|---------|
| XX-01 | Standalone | Basic functionality in complete isolation |
| XX-02 | External Dependencies | Network integration, external DB/services |
| XX-03 | Advanced Features | Production features, performance, scaling |
| XX-04 | SSO Integration | Keycloak OIDC/SAML authentication |
| XX-05 | Advanced Integration | Deep multi-module ecosystem integration |
| XX-06 | Production Deployment | HA cluster, monitoring, DR, load testing |

**Total: 120 labs (20 modules × 6 labs)**

---

## Server Layout

| Server | Hostname | IP | Services | RAM |
|--------|----------|-----|----------|-----|
| 1 – Identity | lab-id1 | 10.0.50.11 | FreeIPA, Keycloak | 16 GB |
| 2 – Database | lab-db1 | 10.0.50.12 | PostgreSQL, Redis, Elasticsearch | 32 GB |
| 3 – Collaboration | lab-app1 | 10.0.50.13 | Nextcloud, Mattermost, Jitsi | 24 GB |
| 4 – Communications | lab-comm1 | 10.0.50.14 | iRedMail, Zammad, Zabbix | 16 GB |
| 5 – Reverse Proxy | lab-proxy1 | 10.0.50.15 | Traefik, Graylog | 8 GB |
| 6 – VoIP | lab-pbx1 | 10.0.50.16 | FreePBX (Asterisk) | 8 GB |
| 7 – Business | lab-biz1 | 10.0.50.17 | SuiteCRM, Odoo, OpenKM | 24 GB |
| 8 – IT Mgmt | lab-mgmt1 | 10.0.50.18 | Taiga, Snipe-IT, GLPI | 16 GB |

**OS:** Ubuntu 24.04 Server LTS — **Network:** 10.0.50.0/24

---

## Related Repositories

| Repository | Purpose |
|------------|---------|
| [it-stack-installer](https://github.com/it-stack-dev/it-stack-installer) | Bootstrap scripts and setup automation |
| [it-stack-ansible](https://github.com/it-stack-dev/it-stack-ansible) | Ansible playbooks for all 20 services |
| [it-stack-terraform](https://github.com/it-stack-dev/it-stack-terraform) | Terraform modules for VM provisioning |
| [it-stack-helm](https://github.com/it-stack-dev/it-stack-helm) | Helm charts for Kubernetes deployment |
| [it-stack-testing](https://github.com/it-stack-dev/it-stack-testing) | Integration and end-to-end test suite |

See the full list of [26 repositories](https://github.com/orgs/it-stack-dev/repositories) in the GitHub organization.

---

## Cloud Lab Deployment (Live — March 2026)

> **12 services are currently running** on a single Azure VM as a live demo/lab environment.

| Property | Value |
|----------|-------|
| VM | `lab-single` — Standard_D4s_v4 (4 vCPU / 16 GB RAM) |
| Public IP | `4.154.17.25` |
| Region | West US 2 |
| Status | ✅ Running — auto-shuts down 22:00 UTC |

**Live services:** Keycloak · Nextcloud (57 apps) · Mattermost · SuiteCRM · Odoo · Snipe-IT · Jitsi Meet · Taiga · Zabbix · Graylog · Traefik · docker-mailserver

See [docs/05-guides/18-azure-lab-deployment.md](docs/05-guides/18-azure-lab-deployment.md) — **Current Live Deployment** section — for all ports, credentials, compose commands, and cost breakdown.

---

## Project Status

| Phase | Description | Status |
|-------|-------------|--------|
| 0 | Planning & documentation (~600 pages, 14 source docs) | ✅ Complete |
| 1 | GitHub org bootstrap (26 repos, 120 issues, 5 projects, labels) | ✅ Complete |
| 2 | Local dev environment (`C:\IT-Stack\it-stack-dev\`) | ✅ Complete |
| 3 | Docs site (MkDocs Material, GitHub Pages) | ✅ Complete |
| 4 | All 20 module repos scaffolded + CI/CD (20/20 passing) | ✅ Complete |
| 5 | Ansible playbooks — all 20 modules (76+ files, 20 roles, 23 integrations) | ✅ Complete |
| 6 | Lab 01–06 Docker Compose + test scripts — all 20 modules (120 labs) | ✅ Complete — 120/120 PASS on Azure |
| 7 | SSO integrations tested (FreeIPA→Keycloak→all 9 services) | ✅ Complete — 35/35 PASS on Azure |
| 8 | Production readiness (Security · Monitoring · Backup · DR · Capacity) | ✅ Complete |
| Cloud | Single-VM Azure lab — 12/20 services live on 4.154.17.25 | ✅ Live — March 2026 |
| 9 | Phase 5: Kubernetes / Helm deployment | 🔲 Next |

---

## Getting Started

1. **Deploy now** — follow [docs/05-guides/00-quick-start-deploy.md](docs/05-guides/00-quick-start-deploy.md) for cloud (Azure) or on-prem step-by-step setup
2. **Browse** the docs at https://it-stack-dev.github.io/it-stack-docs/
3. **Read** [docs/05-guides/01-master-index.md](docs/05-guides/01-master-index.md) for the full documentation map
4. **Walk through the UI** — see [docs/05-guides/22-gui-walkthrough.md](docs/05-guides/22-gui-walkthrough.md) for every service with credentials
5. **Track progress** in [docs/IT-STACK-TODO.md](docs/IT-STACK-TODO.md)
6. **Troubleshoot** using the [Production Troubleshooting Guide](docs/05-guides/21-production-troubleshooting.md)

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to IT-Stack documentation and code.

---

## License

This project is licensed under the [Apache License 2.0](LICENSE).

Copyright © 2026 IT-Stack Contributors
