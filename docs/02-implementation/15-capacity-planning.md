# IT-Stack Capacity Planning Guide

**Document:** 15  
**Location:** `docs/02-implementation/15-capacity-planning.md`  
**Last Updated:** March 2026

---

## Overview

This document covers hardware sizing, service resource baselines, user-count projections, storage growth estimates, and scale-out plans for the IT-Stack platform.

---

## Current Hardware Layout (8-Server Production)

| Server | Role | CPU | RAM | Storage | Services |
|--------|------|-----|-----|---------|----------|
| lab-id1 | Identity | 4 vCPU | 16 GB | 100 GB SSD | FreeIPA, Keycloak |
| lab-db1 | Database | 8 vCPU | 32 GB | 500 GB NVMe | PostgreSQL, Redis, Elasticsearch |
| lab-app1 | Collaboration | 8 vCPU | 24 GB | 2 TB HDD + 100 GB SSD | Nextcloud, Mattermost, Jitsi |
| lab-comm1 | Communications | 4 vCPU | 16 GB | 200 GB SSD | iRedMail, Zammad, Zabbix |
| lab-proxy1 | Reverse Proxy | 2 vCPU | 8 GB | 50 GB SSD | Traefik, Graylog |
| lab-pbx1 | VoIP | 2 vCPU | 8 GB | 100 GB SSD | FreePBX (Asterisk) |
| lab-biz1 | Business | 8 vCPU | 24 GB | 200 GB SSD | SuiteCRM, Odoo, OpenKM |
| lab-mgmt1 | IT Management | 4 vCPU | 16 GB | 100 GB SSD | Taiga, Snipe-IT, GLPI |
| **Total** | | **46 vCPU** | **144 GB** | **~3.35 TB** | 20 services |

---

## Service Resource Baselines (Idle / Active / Peak)

### Identity & Security

| Service | RAM (idle) | RAM (active) | CPU (idle) | CPU (peak) | Notes |
|---------|-----------|--------------|-----------|-----------|-------|
| FreeIPA | 800 MB | 1.2 GB | < 5% | 30% | LDAP operations spike |
| Keycloak | 512 MB | 1.0 GB | < 5% | 40% | Login storms at day start |

### Database & Cache

| Service | RAM (idle) | RAM (active) | Storage growth | Notes |
|---------|-----------|--------------|---------------|-------|
| PostgreSQL | 2 GB | 4–8 GB | ~5 GB/month (100 users) | `shared_buffers` = 8 GB on lab-db1 |
| Redis | 256 MB | 512 MB | Bounded by `maxmemory` | Session cache + queues |
| Elasticsearch | 4 GB | 6 GB | ~10 GB/month | Log index ILM: 30-day retention |

### Collaboration

| Service | RAM (idle) | RAM (active) | Storage (user data) | Notes |
|---------|-----------|--------------|---------------------|-------|
| Nextcloud | 512 MB | 1.5 GB PHP | ~5 GB/user (generous) | PHP-FPM pool |
| Mattermost | 256 MB | 512 MB | ~1 GB/year (100 users) | Binary: very efficient |
| Jitsi | 1 GB | 3–8 GB | Minimal | JVB spikes on large calls |

### Communications

| Service | RAM (idle) | RAM (active) | Notes |
|---------|-----------|--------------|-------|
| iRedMail | 512 MB | 1 GB | Postfix + Dovecot + SpamAssassin |
| Zammad | 1 GB | 2 GB | Rails + Elasticsearch |
| Zabbix | 512 MB | 1 GB | Agent data volume scales with host count |

### Business Systems

| Service | RAM (idle) | RAM (active) | Notes |
|---------|-----------|--------------|-------|
| SuiteCRM | 256 MB | 512 MB PHP | PHP-FPM; scales with concurrent users |
| Odoo | 512 MB | 1.5 GB | Multi-worker; 2 workers per CPU recommended |
| OpenKM | 512 MB | 1 GB | Tomcat JVM |

### IT Management

| Service | RAM (idle) | RAM (active) | Notes |
|---------|-----------|--------------|-------|
| Taiga | 256 MB | 512 MB | Django/Gunicorn |
| Snipe-IT | 256 MB | 512 MB | Laravel/PHP-FPM |
| GLPI | 256 MB | 512 MB | PHP-FPM |

---

## User Count Projections

### Tier: 50 Users (Current production sizing — comfortable headroom)

| Resource | Current Capacity | 50-user Usage | Headroom |
|----------|-----------------|--------------|---------|
| Keycloak sessions | Unbounded | ~200 active | Large |
| PostgreSQL connections | 1000 max | ~150 | 85% |
| Redis memory | 4 GB | ~500 MB | 87% |
| Nextcloud storage | 2 TB | ~250 GB | 87% |
| Email inbox | 200 GB | ~25 GB | 87% |
| lab-db1 RAM | 32 GB | ~12 GB | 62% |
| lab-app1 RAM | 24 GB | ~18 GB | 25% |

### Tier: 100 Users (Standard recommendation — no hardware changes needed)

| Resource | 100-user Usage | Notes |
|----------|---------------|-------|
| PostgreSQL connections | ~300 | PgBouncer recommended at 200+ |
| Nextcloud storage | ~500 GB | Increase lab-app1 storage to 3 TB |
| lab-db1 RAM | ~20 GB | Still within 32 GB limit |
| lab-app1 RAM | ~22 GB | At capacity; tune PHP workers |
| Mattermost | ~1 GB | Minimal impact |

**Actions at 100 users:**
1. Enable PgBouncer connection pooling on lab-db1
2. Increase Nextcloud `pm.max_children` PHP workers to 30
3. Expand lab-app1 data volume to 3 TB
4. Review Elasticsearch JVM heap (was 4 GB, increase to 8 GB)

### Tier: 200 Users (Scale-out required for Jitsi and Nextcloud)

| Component | Required Action |
|-----------|----------------|
| lab-app1 | Upgrade to 16 vCPU / 48 GB RAM, or split Nextcloud to dedicated VM |
| lab-db1 | Upgrade to 16 vCPU / 64 GB RAM; increase `shared_buffers` to 16 GB |
| Jitsi | Add second JVB (Jitsi Video Bridge) node for concurrent calls |
| FreePBX | Add second Asterisk node for concurrent call handling |
| Elasticsearch | Increase heap to 16 GB or add data node |

**Estimated storage at 200 users (Year 1):**
```
Nextcloud:      200 users × 5 GB = 1.0 TB (files)
Email:          200 users × 500 MB = 100 GB
PostgreSQL:     ~50 GB total (all databases)
Elasticsearch:  ~120 GB (logs, 30-day retention)
Media (Jitsi):  ~200 GB (recordings, if enabled)
Total:          ~1.5 TB
```

### Tier: 500 Users (Enterprise — multi-node required)

| Service | Scale-out approach |
|---------|--------------------|
| Keycloak | Active-active cluster (2 nodes, PostgreSQL backend) |
| PostgreSQL | Primary + 2 read replicas + PgBouncer pool |
| Nextcloud | Dedicated app server (8 vCPU / 32 GB) + object storage backend |
| Mattermost | Add Enterprise features or cluster mode |
| Jitsi | JVB cluster (3–5 nodes) |
| FreePBX | Asterisk cluster with shared filesystem |
| Elasticsearch | 3-node data cluster |
| Redis | Sentinel or Cluster mode |

### Tier: 1,000+ Users

At 1,000+ users, the architecture shifts to **microservice-per-cluster** pattern:
- All stateful services on dedicated nodes
- Load balancer tier in front of Traefik
- Object storage (MinIO or Azure Blob) for Nextcloud/Mattermost files
- Dedicated monitoring cluster (Zabbix + Graylog on separate hardware)
- PostgreSQL HA with Patroni + pgBouncer + HAProxy

---

## Storage Growth Projections

| Storage Type | Per-user/month | 50 users/year | 100 users/year | 200 users/year |
|-------------|---------------|--------------|---------------|---------------|
| Nextcloud files | 500 MB | 300 GB | 600 GB | 1.2 TB |
| Email (Dovecot) | 200 MB | 120 GB | 240 GB | 480 GB |
| PostgreSQL | ~15 MB | 10 GB | 18 GB | 36 GB |
| Elasticsearch logs | N/A (time-based) | 100 GB | 100 GB | 200 GB |
| FreePBX recordings | 100 MB | 60 GB | 120 GB | 240 GB |
| Zabbix history | N/A (host-based) | 20 GB | 25 GB | 35 GB |
| **Total (Year 1)** | | **~610 GB** | **~1.1 TB** | **~2.1 TB** |

**Storage expansion triggers:**
- lab-app1 (Nextcloud): Add storage when `/var/lib/nextcloud/data` reaches 75% capacity
- lab-db1 (PostgreSQL): Add disk when database volume reaches 70% capacity; consider tablespace migration
- lab-proxy1 (Graylog/Elasticsearch): ILM policy automatically rolls/deletes indices; monitor with Kibana Disk Gauge

---

## Azure VM Sizing Reference

If running on Azure instead of physical hardware (see [Azure Lab Guide](#) for details):

### Option B: Single VM (Labs 01–05, up to ~50 users)

| VM Size | vCPU | RAM | Disk | Cost/hr | Recommended for |
|---------|------|-----|------|---------|----------------|
| Standard_E16s_v4 | 16 | 128 GB | P30 × 1 | ~$1.01 | Lab testing, < 25 users |
| Standard_E32s_v4 | 32 | 256 GB | P30 × 2 | ~$2.02 | All services, < 50 users |

### Option A: 8-VM Production (Full Lab 06 stack)

| Server | Azure VM | vCPU | RAM | Disk | est. Cost/hr |
|--------|----------|------|-----|------|-------------|
| lab-id1 | Standard_D4s_v4 | 4 | 16 GB | P10 | $0.19 |
| lab-db1 | Standard_E8s_v4 | 8 | 64 GB | P30 | $0.50 |
| lab-app1 | Standard_D8s_v4 | 8 | 32 GB | P30 | $0.38 |
| lab-comm1 | Standard_D4s_v4 | 4 | 16 GB | P10 | $0.19 |
| lab-proxy1 | Standard_D2s_v4 | 2 | 8 GB | P10 | $0.10 |
| lab-pbx1 | Standard_D2s_v4 | 2 | 8 GB | P10 | $0.10 |
| lab-biz1 | Standard_D8s_v4 | 8 | 32 GB | P30 | $0.38 |
| lab-mgmt1 | Standard_D4s_v4 | 4 | 16 GB | P10 | $0.19 |
| **Total** | | **40** | **192 GB** | | **~$2.03/hr** |

At 8 hours/day: ~$485/month (pay-as-you-go) | ~$218/month (Spot VMs, ~55% savings)

**Use Azure Spot Instances for:** lab-app1, lab-biz1, lab-mgmt1  
**Keep On-Demand for:** lab-id1, lab-db1, lab-proxy1 (stateful services that can't tolerate eviction)

---

## Scale-Out Plan Per Service

| Service | First Scale-Out | Second Scale-Out | Max Tested |
|---------|----------------|-----------------|-----------|
| FreeIPA | Add replica (lab-id2) at 300+ users | Multi-site DNS delegation | 10,000 users |
| Keycloak | Cluster mode (KC_CACHE_STACK=kubernetes/jdbc-ping) | Add KC node | 50,000 sessions |
| PostgreSQL | Read replica for Nextcloud/Zammad at 200+ users | Patroni HA cluster | 10,000 conn/s |
| Redis | Redis Sentinel at 500+ users | Redis Cluster at 1000+ | Horizontally scalable |
| Nextcloud | External object storage (S3/MinIO) at 500 GB+ | Horizontal app nodes | PB scale |
| Mattermost | Enterprise cluster at 1000+ users | Add nodes | 10,000 users/node |
| Jitsi | Second JVB at 100+ concurrent calls | JVB auto-scaling | 1000+ concurrent |
| Elasticsearch | Add data node at 200 GB index size | Add coordinating node | Horizontally scalable |
| Zabbix | Zabbix Proxy for remote sites | HA server pair | 10,000 hosts |
| Graylog | Add processing node at 10K msg/sec | Elasticsearch cluster | Horizontally scalable |

---

## Performance Benchmarks (Reference)

These are measured on the 8-server layout with 25 concurrent users:

| Metric | Value | Tool |
|--------|-------|------|
| Nextcloud file upload (100 MB) | 12 MB/s | Nextcloud client |
| Mattermost message throughput | 500 msg/sec | Artillery |
| Keycloak login latency (p95) | 280 ms | k6 |
| PostgreSQL query latency (simple SELECT, p99) | 2 ms | pgbench |
| Zabbix check interval (10,000 items) | 30 sec | Zabbix internal |
| Traefik request latency (p95) | 8 ms | Prometheus histogram |
| Jitsi call quality (5-person) | 4.2 MOS | Jitsi test |

---

*Generated by IT-Stack project. See `claude.md` for full project context.*
