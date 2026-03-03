# Architecture Reference

> **Category:** Architecture Decision Records (ADRs) and Technical Diagrams

This directory contains architecture decision records (ADRs) and technical diagrams for IT-Stack, documenting why each major technical choice was made.

---

## ADR Index

| # | Title | Status | Date |
|---|-------|--------|------|
| [ADR-001](adr-001-identity-stack.md) | Use FreeIPA + Keycloak for identity | Accepted | 2026-02-27 |
| [ADR-002](adr-002-postgresql-primary.md) | PostgreSQL as primary database for all services | Accepted | 2026-02-27 |
| [ADR-003](adr-003-traefik-proxy.md) | Traefik as reverse proxy with automatic TLS | Accepted | 2026-02-27 |
| [ADR-004](adr-004-lab-methodology.md) | 6-lab progressive testing methodology | Accepted | 2026-02-27 |
| [ADR-005](adr-005-ubuntu-2404.md) | Ubuntu 24.04 LTS as base OS for all servers | Accepted | 2026-02-27 |
| [ADR-006](adr-006-8server-layout.md) | 8-server production layout | Accepted | 2026-02-27 |
| [ADR-007](adr-007-docker-compose-ansible.md) | Docker Compose for labs, Ansible for production | Accepted | 2026-02-27 |
| [ADR-008](adr-008-apache2-license.md) | Apache 2.0 license for all repositories | Accepted | 2026-02-27 |

---

## Diagram Index

| File | Description |
|------|-------------|
| [network-topology.md](network-topology.md) | Network layout -- 8 servers, IPs, DNS records, firewall rules, Mermaid diagram |
| [service-integration-map.md](service-integration-map.md) | All 22+ cross-service integrations -- Mermaid diagram, integration catalog, startup order |

---

## Quick-Reference: Key Decisions

| Decision | Choice | ADR |
|----------|--------|-----|
| Identity / SSO | FreeIPA (LDAP/Kerberos) + Keycloak (OIDC/SAML) | ADR-001 |
| Primary database | Single PostgreSQL 16 on lab-db1 | ADR-002 |
| Reverse proxy | Traefik v3 with FreeIPA CA (lab) / Let's Encrypt (prod) | ADR-003 |
| Lab methodology | 6 progressive labs per module (120 total) | ADR-004 |
| Base OS | Ubuntu 24.04 LTS (EOL April 2029 / 2036 with Pro) | ADR-005 |
| Server layout | 8 servers, 10.0.50.11-18, it-stack.lab | ADR-006 |
| Automation tooling | Docker Compose (labs 01-05), Ansible (lab 06 + prod) | ADR-007 |
| License | Apache 2.0 (all 26 repos) | ADR-008 |

---

## ADR Format

All ADRs use the MADR style:

- **Status** -- Proposed / Accepted / Deprecated / Superseded
- **Date** -- ISO 8601
- **Deciders** -- Who made the decision
- **Context** -- What problem we were solving
- **Decision** -- What we chose and why
- **Consequences** -- Positive and negative outcomes
- **Alternatives Considered** -- Other options and why they were not selected
- **References** -- Related docs, upstream links

---

## Related Documentation

- [Master Index](../MASTER-INDEX.md)
- [Integration Guide](../integration-guide-complete.md)
- [8-Server Enterprise Architecture](../enterprise-stack-complete-v2.md)
- [Lab Deployment Plan](../lab-deployment-plan.md)
