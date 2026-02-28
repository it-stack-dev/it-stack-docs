# IT-Stack Documentation

**Open-source enterprise IT platform — $0 in software licensing**

IT-Stack replaces every commercial tool your organization needs with self-hosted, fully integrated open-source services. Identity management, collaboration, communications, business systems, IT management, and infrastructure monitoring — all in one stack.

---

## What IT-Stack Replaces

| Commercial Product | IT-Stack Replacement | Annual Savings (100 users) |
|--------------------|---------------------|---------------------------|
| Microsoft 365 | Nextcloud + iRedMail | ~$24,000 |
| Slack / Teams | Mattermost | ~$15,000 |
| Zoom | Jitsi | ~$24,000 |
| Salesforce | SuiteCRM | ~$90,000 |
| SAP / QuickBooks | Odoo | ~$50,000 |
| RingCentral | FreePBX | ~$36,000 |
| ServiceNow | GLPI + Zammad | ~$120,000 |
| Active Directory | FreeIPA + Keycloak | ~$10,000 |

!!! success "5-year TCO savings: ~$2,000,000 vs commercial equivalent"

---

## 7-Layer Architecture

```
Layer 7: Infrastructure      Traefik · Zabbix · Graylog
Layer 6: IT & Project Mgmt   Taiga · Snipe-IT · GLPI
Layer 5: Business Systems    SuiteCRM · Odoo · OpenKM
Layer 4: Communications      iRedMail · FreePBX · Zammad
Layer 3: Collaboration       Nextcloud · Mattermost · Jitsi
Layer 2: Database & Cache    PostgreSQL · Redis · Elasticsearch
Layer 1: Identity & Security FreeIPA · Keycloak
```

---

## 20 Modules

| # | Module | Category | Phase | Server |
|---|--------|----------|-------|--------|
| 01 | [FreeIPA](https://github.com/it-stack-dev/it-stack-freeipa) | Identity | 1 | lab-id1 |
| 02 | [Keycloak](https://github.com/it-stack-dev/it-stack-keycloak) | Identity | 1 | lab-id1 |
| 03 | [PostgreSQL](https://github.com/it-stack-dev/it-stack-postgresql) | Database | 1 | lab-db1 |
| 04 | [Redis](https://github.com/it-stack-dev/it-stack-redis) | Database | 1 | lab-db1 |
| 05 | [Elasticsearch](https://github.com/it-stack-dev/it-stack-elasticsearch) | Database | 4 | lab-db1 |
| 06 | [Nextcloud](https://github.com/it-stack-dev/it-stack-nextcloud) | Collaboration | 2 | lab-app1 |
| 07 | [Mattermost](https://github.com/it-stack-dev/it-stack-mattermost) | Collaboration | 2 | lab-app1 |
| 08 | [Jitsi](https://github.com/it-stack-dev/it-stack-jitsi) | Collaboration | 2 | lab-app1 |
| 09 | [iRedMail](https://github.com/it-stack-dev/it-stack-iredmail) | Communications | 2 | lab-comm1 |
| 10 | [FreePBX](https://github.com/it-stack-dev/it-stack-freepbx) | Communications | 3 | lab-pbx1 |
| 11 | [Zammad](https://github.com/it-stack-dev/it-stack-zammad) | Communications | 2 | lab-comm1 |
| 12 | [SuiteCRM](https://github.com/it-stack-dev/it-stack-suitecrm) | Business | 3 | lab-biz1 |
| 13 | [Odoo](https://github.com/it-stack-dev/it-stack-odoo) | Business | 3 | lab-biz1 |
| 14 | [OpenKM](https://github.com/it-stack-dev/it-stack-openkm) | Business | 3 | lab-biz1 |
| 15 | [Taiga](https://github.com/it-stack-dev/it-stack-taiga) | IT Management | 4 | lab-mgmt1 |
| 16 | [Snipe-IT](https://github.com/it-stack-dev/it-stack-snipeit) | IT Management | 4 | lab-mgmt1 |
| 17 | [GLPI](https://github.com/it-stack-dev/it-stack-glpi) | IT Management | 4 | lab-mgmt1 |
| 18 | [Traefik](https://github.com/it-stack-dev/it-stack-traefik) | Infrastructure | 1 | lab-proxy1 |
| 19 | [Zabbix](https://github.com/it-stack-dev/it-stack-zabbix) | Infrastructure | 4 | lab-comm1 |
| 20 | [Graylog](https://github.com/it-stack-dev/it-stack-graylog) | Infrastructure | 4 | lab-proxy1 |

---

## 4-Phase Rollout

=== "Phase 1 — Foundation"
    **Weeks 1–4** · FreeIPA · Keycloak · PostgreSQL · Redis · Traefik

    SSO, database, and reverse proxy. Everything else depends on this.

=== "Phase 2 — Collaboration"
    **Weeks 5–8** · Nextcloud · Mattermost · Jitsi · iRedMail · Zammad

    Full collaboration suite with SSO. Replaces Microsoft 365, Slack, Zoom.

=== "Phase 3 — Back Office"
    **Weeks 9–14** · FreePBX · SuiteCRM · Odoo · OpenKM

    VoIP, CRM, ERP, and document management.

=== "Phase 4 — IT Management"
    **Weeks 15–20** · Taiga · Snipe-IT · GLPI · Elasticsearch · Zabbix · Graylog

    Full observability, asset tracking, and IT service management.

---

## 6-Lab Testing Methodology

Every module has exactly **6 labs** that must be completed in order:

| Lab | Name | Machines | Purpose |
|-----|------|----------|---------|
| XX-01 | Standalone | 1 | Basic functionality, complete isolation |
| XX-02 | External Dependencies | 2–3 | Network integration, external DB |
| XX-03 | Advanced Features | 2–3 | TLS, performance, backup/restore |
| XX-04 | SSO Integration | 3–4 | Keycloak OIDC/SAML authentication |
| XX-05 | Advanced Integration | 4–5 | Cross-service ecosystem integration |
| XX-06 | Production Deployment | 5+ | HA, monitoring, disaster recovery |

**Total: 120 labs across 20 modules**

---

## 8-Server Production Layout

| Server | IP | Services | RAM |
|--------|-----|----------|-----|
| lab-id1 | 10.0.50.11 | FreeIPA, Keycloak | 16 GB |
| lab-db1 | 10.0.50.12 | PostgreSQL, Redis, Elasticsearch | 32 GB |
| lab-app1 | 10.0.50.13 | Nextcloud, Mattermost, Jitsi | 24 GB |
| lab-comm1 | 10.0.50.14 | iRedMail, Zammad, Zabbix | 16 GB |
| lab-proxy1 | 10.0.50.15 | Traefik, Graylog | 8 GB |
| lab-pbx1 | 10.0.50.16 | FreePBX | 8 GB |
| lab-biz1 | 10.0.50.17 | SuiteCRM, Odoo, OpenKM | 24 GB |
| lab-mgmt1 | 10.0.50.18 | Taiga, Snipe-IT, GLPI | 16 GB |

**OS:** Ubuntu 24.04 Server LTS · **Network:** 10.0.50.0/24

---

## Quick Links

- [GitHub Organization](https://github.com/it-stack-dev)  
- [Master Index](project/master-index.md)  
- [TODO & Roadmap](project/todo.md)  
- [Contributing](contributing/framework-template.md)  
- [License](https://github.com/it-stack-dev/it-stack-docs/blob/main/LICENSE)
