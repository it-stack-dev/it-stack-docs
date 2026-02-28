---
doc: "01-core-02"
title: "Database & Cache — PostgreSQL + Redis + Elasticsearch"
category: database
phase: 1 (PostgreSQL, Redis) / 4 (Elasticsearch)
servers: [lab-db1]
date: 2026-02-27
---

# Database & Cache

> **Category:** Database & Cache — Layer 2  
> **Servers:** `lab-db1` (10.0.50.12, 32 GB RAM)  
> **Modules:** PostgreSQL (03) · Redis (04) · Elasticsearch (05)

---

## Overview

All stateful data lives on `lab-db1`. Every application service connects here for its primary database,
caching layer, and search/log index. Centralizing storage on one high-memory server simplifies backup,
monitoring, and disaster recovery.

---

## Module 03: PostgreSQL

**Repo:** [it-stack-postgresql](https://github.com/it-stack-dev/it-stack-postgresql)  
**Version:** PostgreSQL 16.x  
**Port:** 5432

### Service Databases

| Database | Owner | Used By |
|----------|-------|---------|
| `keycloak` | keycloak | Keycloak SSO |
| `nextcloud` | nextcloud | Nextcloud files/calendar |
| `mattermost` | mattermost | Mattermost chat |
| `zammad` | zammad | Zammad help desk |
| `suitecrm` | suitecrm | SuiteCRM CRM |
| `odoo` | odoo | Odoo ERP |
| `openkm` | openkm | OpenKM DMS |
| `taiga` | taiga | Taiga project management |
| `snipeit` | snipeit | Snipe-IT assets |
| `glpi` | glpi | GLPI ITSM |
| `zabbix` | zabbix | Zabbix monitoring |

### Access Control (`pg_hba.conf`)

```
# All app servers connect via md5 from the 10.0.50.0/24 subnet
host    all    all    10.0.50.0/24    scram-sha-256
# Replication
host    replication    replicator    10.0.50.12/32    scram-sha-256
```

### Backup Strategy

```bash
# Daily pg_dumpall via cron (04:00 UTC)
pg_dumpall -U postgres | gzip > /backups/pg-$(date +%Y%m%d).sql.gz
# Retention: 30 daily, 12 weekly, 6 monthly
```

---

## Module 04: Redis

**Repo:** [it-stack-redis](https://github.com/it-stack-dev/it-stack-redis)  
**Version:** Redis 7.x  
**Port:** 6379

### Usage by Service

| Service | Redis Use |
|---------|-----------|
| Nextcloud | File locking, session cache |
| Mattermost | Session store, rate limiting |
| Zammad | Job queues (Sidekiq) |
| Taiga | Async task queue (Celery) |
| Keycloak | Session sticky cache (optional) |

### Configuration

```
maxmemory 4gb
maxmemory-policy allkeys-lru
requirepass <vault>
bind 10.0.50.12
```

---

## Module 05: Elasticsearch

**Repo:** [it-stack-elasticsearch](https://github.com/it-stack-dev/it-stack-elasticsearch)  
**Version:** Elasticsearch 8.x  
**Ports:** 9200 (HTTP), 9300 (transport)  
**Phase:** 4

### Usage by Service

| Service | Elasticsearch Index | Purpose |
|---------|---------------------|---------|
| Zammad | `zammad-*` | Full-text ticket search |
| Graylog | `graylog_*` | Log storage and search |
| Mattermost | `mattermost_*` (optional) | Message search |

### JVM Configuration

```
-Xms8g -Xmx8g   # Set to half of lab-db1 RAM
```

---

## Lab Progression

| Lab | Module | Key Task |
|-----|--------|----------|
| 03-01 | PostgreSQL | Standalone, create all 11 databases |
| 03-02 | PostgreSQL | Remote access from app servers |
| 03-04 | PostgreSQL | FreeIPA LDAP auth for DB users |
| 04-01 | Redis | Standalone, verify keyspace |
| 04-02 | Redis | Nextcloud + Mattermost connecting |
| 05-01 | Elasticsearch | Standalone, verify cluster health |
| 05-02 | Elasticsearch | Graylog + Zammad indexing |
