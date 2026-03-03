# ADR-006: 8-Server Production Layout

**Status:** Accepted  
**Date:** 2026-02-27  
**Deciders:** IT-Stack Architecture Team  

---

## Context

IT-Stack runs 20 services. These services have sharply different resource profiles and failure domains. Keeping all services on one server creates:

- Resource contention (FreeIPA DNS latency while Odoo runs payroll)
- Risk of cascading failures (an Odoo crash impacting identity services)
- No clear upgrade/maintenance boundaries
- Impossible HA topology (can't live-migrate one server's workloads without affecting others)

At the same time, one VM per service (20 VMs) is cost-prohibitive for the target organizations (50–1,000 users).

### Grouping Principles

1. **Risk isolation** — identity services must never share a server with noisy-neighbor business applications
2. **Resource affinity** — database-heavy services collocate on high-RAM hardware
3. **Failure domain independence** — taking down one server should affect at most one service category
4. **Maintenance boundary** — patching lab-biz1 should not require a maintenance window for email
5. **Network locality** — services that communicate heavily should be on the same server or adjacent

---

## Decision

**Deploy IT-Stack across 8 dedicated servers, each with a distinct functional role.**

### Production Server Layout

| # | Hostname | IP | RAM | Primary Role | Services |
|---|----------|----|-----|-------------|---------|
| 1 | `lab-id1` | 10.0.50.11 | 16 GB | Identity | FreeIPA, Keycloak |
| 2 | `lab-db1` | 10.0.50.12 | 32 GB | Database | PostgreSQL 16, Redis 7 |
| 3 | `lab-app1` | 10.0.50.13 | 24 GB | Collaboration | Nextcloud, Mattermost, Jitsi |
| 4 | `lab-comm1` | 10.0.50.14 | 16 GB | Communications | iRedMail, Zammad, Zabbix |
| 5 | `lab-proxy1` | 10.0.50.15 | 8 GB | Infrastructure | Traefik, Graylog |
| 6 | `lab-pbx1` | 10.0.50.16 | 8 GB | VoIP | FreePBX (Asterisk) |
| 7 | `lab-biz1` | 10.0.50.17 | 24 GB | Business | SuiteCRM, Odoo, OpenKM |
| 8 | `lab-mgmt1` | 10.0.50.18 | 16 GB | IT Management | Taiga, Snipe-IT, GLPI |

**Network:** `10.0.50.0/24`  
**Gateway:** `10.0.50.1`  
**DNS:** `lab-id1` (10.0.50.11) — FreeIPA authoritative for `it-stack.lab`  

### Key Design Choices

#### lab-id1: Identity is isolated
FreeIPA DNS serves every other server's name resolution. Keycloak handles every user login. These services must be the most reliable in the stack. Collocating them with noisy workloads (ERP batch jobs, video transcoding) would risk identity service latency.

#### lab-db1: Maximum RAM for the database tier
32 GB enables PostgreSQL's `shared_buffers = 8 GB` and leaves headroom for Redis. All 10 application databases live here. This server should never run application workloads.

#### Elasticsearch on lab-db1 (Phase 4)
Elasticsearch is also deployed here despite being a Phase 4 service. It functions as a data tier (Graylog log storage, Zammad search) and benefits from the same RAM headroom as the other database services.

#### lab-pbx1: VoIP requires dedicated hardware
FreePBX/Asterisk handles real-time RTP media. Shared CPUs create jitter. Port range 10000–20000/UDP must be open without NAT. Isolating VoIP prevents quality issues during spikes on other servers.

#### lab-proxy1: Low RAM, high throughput
Traefik + Graylog. Graylog is log aggregation, not user-facing; 8 GB RAM is sufficient. This server can be replaced or scaled horizontally in Phase 6 with an HAProxy pair in front.

### Deployment Phase Sequence

```
Phase 1: lab-id1, lab-db1, lab-proxy1  (identity + database + proxy first)
Phase 2: lab-app1, lab-comm1           (collaboration + communications)
Phase 3: lab-biz1, lab-pbx1           (business + VoIP)
Phase 4: lab-mgmt1 + Elasticsearch    (IT management + full observability)
```

### Lab / Home Tier (reduced)

For Tier 1A lab deployments (1–3 machines), services are collocated:

| VM | Services |
|----|---------|
| vm-01 | FreeIPA, Keycloak, PostgreSQL, Redis, Traefik |
| vm-02 | Nextcloud, Mattermost, Jitsi |
| vm-03 | iRedMail, Zammad |

---

## Consequences

### Positive
- **Clear failure domains** — losing lab-biz1 (ERP/CRM) does not affect email, chat, or identity
- **Resource-appropriate sizing** — 32 GB for the DB tier; only 8 GB for the proxy
- **Upgrade isolation** — patching FreePBX only requires a lab-pbx1 maintenance window
- **Security boundary** — network firewall rules can restrict inter-server traffic to only required ports
- **Ansible inventory maps to servers** — `host_vars/lab-biz1.yml` contains all Odoo/SuiteCRM vars

### Negative / Trade-offs
- **8 servers to manage** — more hardware; more Ansible runs; more certificates
  - Mitigation: Ansible site.yml deploys all 8 in one playbook run
- **Higher baseline cost** — total RAM is 144 GB across 8 servers (~$3,000–8,000 in hardware)
  - Justification: replaces $400K+/year in commercial software licensing
- **Inter-server latency** — services like Odoo → PostgreSQL traverse the LAN
  - Mitigation: 1 Gbps LAN with sub-1ms latency between servers; all on `10.0.50.0/24`

---

## Alternatives Considered

### 3-server layout (identity, app, db)
- Lower cost; easier to manage
- No failure domain isolation between collaboration and business services
- **Rejected:** suitable for Tier 1B but not production (see ADR-004 deployment tiers)

### One server per service (20 servers)
- Maximum isolation and resource control
- Extreme cost; PostgreSQL on each server loses the single-backup advantage (see ADR-002)
- **Rejected:** over-engineered for 50–1,000 users

### Kubernetes (k8s cluster)
- Full workload portability; automatic rescheduling
- Adds significant operational complexity; FreeIPA is not Kubernetes-native
- **Appropriate for Phase 6+ / enterprise scale**; see `it-stack-helm` repo
- **Rejected as default:** bare-metal VM layout is more accessible for the target organizations

---

## References

- [Network Topology Diagram](network-topology.md)
- [Server resource requirements](../02-implementation/enterprise-stack-complete-v2.md)
- [Ansible inventory](https://github.com/it-stack-dev/it-stack-ansible/tree/main/inventory)
- [it-stack-terraform repo](https://github.com/it-stack-dev/it-stack-terraform) — VM provisioning
