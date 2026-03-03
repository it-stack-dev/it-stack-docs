# ADR-002: PostgreSQL as the Primary Database for All Services

**Status:** Accepted  
**Date:** 2026-02-27  
**Deciders:** IT-Stack Architecture Team  

---

## Context

IT-Stack runs 20 services. Ten of them require a relational database:

| Service | Database Name | Primary Uses |
|---------|--------------|-------------|
| Keycloak | `keycloak` | Realm config, users, sessions |
| Nextcloud | `nextcloud` | File metadata, shares, calendar |
| Mattermost | `mattermost` | Messages, channels, users |
| Zammad | `zammad` | Tickets, customers, articles |
| SuiteCRM | `suitecrm` | Contacts, leads, campaigns |
| Odoo | `odoo` | Accounting, HR, inventory |
| OpenKM | `openkm` | Document metadata, workflows |
| Taiga | `taiga` | Projects, issues, sprints |
| Snipe-IT | `snipeit` | Assets, licenses, locations |
| GLPI | `glpi` | CMDB, tickets, changes |

### Requirements

- Single DB engine to reduce operational overhead (one set of backup scripts, one monitoring config, one skills requirement)
- Strong relational integrity and foreign-key support
- JSON column support (Keycloak, Nextcloud, Odoo all store JSON blobs)
- Performance at 50–1,000 users
- All 10 upstream applications explicitly support it
- Open-source, no licensing cost

---

## Decision

**Use a single PostgreSQL 16 instance on `lab-db1` (10.0.50.12) for all 10 service databases.**

### Configuration

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Version | PostgreSQL 16 | Latest LTS; all target apps support it |
| Host | `lab-db1` (10.0.50.12) | Dedicated 32 GB RAM server |
| Shared buffers | `8 GB` | 25% of RAM, standard PG tuning |
| Connections | `200 max` | 10 services × ~15 connections each + headroom |
| pg_hba.conf | `scram-sha-256` | No md5, no trust; encrypted auth only |
| Listen | `10.0.50.12` | Bind to LAN IP, not 0.0.0.0 |
| backup | `pg_dumpall` nightly to `/var/backups/postgresql/` | All databases in one shot |

### Database Isolation

Each service gets its own database and role with no cross-database privileges:

```sql
-- Example pattern (Nextcloud)
CREATE DATABASE nextcloud OWNER nextcloud_user;
CREATE USER nextcloud_user WITH PASSWORD '...vault...';
GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud_user;
-- nextcloud_user cannot access keycloak or mattermost
```

### Redis for Non-Relational Data

Redis (`lab-db1`, port 6379) handles:
- **Sessions** — Keycloak, Nextcloud, Mattermost, Zammad
- **Queues** — Mattermost job server, Zammad background workers
- **Cache** — Nextcloud file metadata, APCu overflow

Redis does **not** replace PostgreSQL for persistent data.

---

## Consequences

### Positive
- **One backup target** — `pg_dumpall` backs up all 10 databases in a single script
- **One monitoring config** — Zabbix postgresql template covers all databases
- **One Ansible role** — `roles/postgresql` manages the entire database tier
- **One upgrade event** — upgrading PostgreSQL upgrades all service databases simultaneously
- **Skills concentration** — team learns one DB, not 3+ (MySQL, SQLite, MongoDB)
- **No MySQL licensing ambiguity** — PostgreSQL has an unambiguous open-source license (PostgreSQL License)

### Negative / Trade-offs
- **Single point of failure** — all 10 services lose database connectivity if `lab-db1` goes down
  - Mitigation: PostgreSQL streaming replication to a standby (Phase 6 / production hardening)
- **Resource contention** — during heavy Odoo batch jobs, other services may see latency
  - Mitigation: `pg_hba.conf` connection limits per role; `work_mem = 32MB` prevents single-query RAM monopoly
- **Large `pg_dumpall` backups** — 10 databases, could exceed 50+ GB at scale
  - Mitigation: `pg_dump` per-database with compression; WAL archiving for point-in-time recovery

---

## Alternatives Considered

### MySQL / MariaDB
- SuiteCRM and GLPI prefer MySQL and have historically had PostgreSQL quirks
- **Rejected:** Both now fully support PostgreSQL; MySQL's licensing history (Oracle) conflicts with IT-Stack's open-source ethos

### Separate DB server per service
- Maximum isolation; one DB failure doesn't affect others
- Requires 10× the operational overhead for backup, monitoring, patching
- **Rejected:** over-engineered for 50–1,000 users; Phase 6 replication is sufficient

### SQLite for small services
- Some services (Snipe-IT, GLPI) can use SQLite in single-user mode
- No multi-user concurrency; no replication; no `pg_dump` integration
- **Rejected:** production use requires a proper RDBMS

---

## References

- [PostgreSQL 16 Release Notes](https://www.postgresql.org/docs/16/release-16.html)
- [it-stack-postgresql repo](https://github.com/it-stack-dev/it-stack-postgresql)
- [Ansible role: postgresql](../../it-stack-dev/repos/meta/it-stack-ansible/roles/postgresql/)
- [Server layout](adr-006-8server-layout.md)
