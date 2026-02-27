# IT-Stack — Enterprise Open-Source IT Infrastructure

> **Complete enterprise IT platform built entirely from open-source software — $0 in software licensing.**

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Phase](https://img.shields.io/badge/Phase-1%20Foundation-orange.svg)](docs/IT-STACK-TODO.md)
[![Modules](https://img.shields.io/badge/Modules-20-green.svg)](docs/MASTER-INDEX.md)
[![Labs](https://img.shields.io/badge/Labs-120-brightgreen.svg)](docs/LAB_MANUAL_STRUCTURE.md)

---

## What Is IT-Stack?

IT-Stack is a **production-ready enterprise IT platform** that replaces the major commercial SaaS subscriptions most organizations depend on. It targets 50–1,000+ users across 8–9 Ubuntu 24.04 servers and integrates 20 open-source services into a cohesive, SSO-connected platform.

**Estimated 5-year TCO savings vs. commercial equivalent: ~$2,000,000**

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

This repository (`it-stack-docs`) contains all IT-Stack documentation.

```
it-stack-docs/
├── docs/                          # All project documentation (~600 pages)
│   ├── MASTER-INDEX.md            # Documentation navigation guide
│   ├── PROJECT-FRAMEWORK-TEMPLATE.md  # Canonical project blueprint
│   ├── IT-STACK-TODO.md           # Living task checklist
│   ├── IT-STACK-GITHUB-GUIDE.md   # GitHub org setup guide + scripts
│   ├── LAB_MANUAL_STRUCTURE.md    # Lab manual overview
│   ├── lab-deployment-plan.md     # Test deployment strategy
│   ├── enterprise-it-stack-deployment.md  # Full technical reference
│   ├── enterprise-stack-complete-v2.md   # 8-server architecture
│   ├── enterprise-it-lab-manual.md       # Lab Part 1: Network & OS
│   ├── enterprise-it-lab-manual-part2.md # Lab Part 2: Identity/DB/SSO
│   ├── enterprise-it-lab-manual-part3.md # Lab Part 3: Collaboration
│   ├── enterprise-it-lab-manual-part4.md # Lab Part 4: Communications
│   ├── enterprise-lab-manual-part5.md    # Lab Part 5: Back Office
│   └── integration-guide-complete.md    # Cross-service integration
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

| Document | Purpose | Start Here If… |
|----------|---------|----------------|
| [MASTER-INDEX.md](docs/MASTER-INDEX.md) | Full navigation guide | You want to understand the full scope |
| [PROJECT-FRAMEWORK-TEMPLATE.md](docs/PROJECT-FRAMEWORK-TEMPLATE.md) | Conventions, patterns, automation | You're building or scaffolding a module |
| [IT-STACK-TODO.md](docs/IT-STACK-TODO.md) | Task tracking checklist | You want to see what's done/in progress |
| [IT-STACK-GITHUB-GUIDE.md](docs/IT-STACK-GITHUB-GUIDE.md) | GitHub org setup scripts | You're bootstrapping the GitHub org |
| [enterprise-stack-complete-v2.md](docs/enterprise-stack-complete-v2.md) | 8-server architecture | You need server specs and IP layout |
| [LAB_MANUAL_STRUCTURE.md](docs/LAB_MANUAL_STRUCTURE.md) | Lab methodology overview | You want to understand the 6-lab system |
| [integration-guide-complete.md](docs/integration-guide-complete.md) | Cross-service integration | You're configuring service-to-service links |

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

## Getting Started

1. **Read** [MASTER-INDEX.md](docs/MASTER-INDEX.md) for the full documentation map
2. **Follow** [IT-STACK-GITHUB-GUIDE.md](docs/IT-STACK-GITHUB-GUIDE.md) to bootstrap the GitHub organization
3. **Track progress** in [IT-STACK-TODO.md](docs/IT-STACK-TODO.md)
4. **Deploy Phase 1** using [enterprise-it-lab-manual-part2.md](docs/enterprise-it-lab-manual-part2.md)

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to IT-Stack documentation and code.

---

## License

This project is licensed under the [Apache License 2.0](LICENSE).

Copyright © 2026 IT-Stack Contributors
