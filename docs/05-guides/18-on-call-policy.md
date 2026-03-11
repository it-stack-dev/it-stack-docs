# IT-Stack On-Call Escalation Policy

**Document:** 18  
**Location:** `docs/05-guides/18-on-call-policy.md`  
**Last Updated:** March 2026

---

## Overview

This document defines the on-call rotation, alert escalation path, and incident response procedures for IT-Stack production environments. It is intended for organizations that have deployed IT-Stack and need a structured approach to handling after-hours incidents.

For alert configuration details see:
- [Admin Runbook](17-admin-runbook.md) — daily ops / Zabbix / Graylog
- [Ansible repo](../../../it-stack-ansible/) — `roles/zabbix/tasks/mattermost-alerts.yml`

---

## On-Call Rotation

### Minimum Staffing

| Role | Responsibility | Min. Required |
|------|---------------|---------------|
| Primary On-Call | First responder — triages all P1/P2 alerts | 1 person |
| Secondary On-Call | Backup if primary unreachable (15 min) | 1 person |
| Escalation Manager | Declares major incidents, coordinates teams | 1 person |

### Rotation Schedule

- **Rotation length:** 1 week (Monday 08:00 → Monday 07:59)
- **Handover:** Monday standup — outgoing on-call reviews open incidents
- **Tool options:** PagerDuty · Opsgenie · Mattermost `#on-call` channel · phone/SMS

### Handover Checklist

Before ending your on-call week:
- [ ] All P1/P2 incidents resolved or formally handed over
- [ ] Outstanding Zabbix problems acknowledged or silenced with explanation
- [ ] Graylog WARN/ERROR backlog reviewed; false positives suppressed
- [ ] Backup verification (`make backup-verify`) run and clean
- [ ] Handover notes posted to `#ops-handover` Mattermost channel

---

## Alert Severity Levels

| Severity | Name | Examples | Response Target |
|----------|------|---------|----------------|
| **P1** | Critical | Identity server down · PostgreSQL unreachable · All email bouncing | 15 min |
| **P2** | High | Single service down · DB replication lag > 60s · Certificate expiry < 7 days | 1 hour |
| **P3** | Medium | High CPU > 90% for 15min · Disk > 80% · Redis evictions | Next business day |
| **P4** | Low | Log volume spike · Backup older than 48h · Slow query | 3 business days |

---

## Escalation Path

```
Alert fires in Zabbix
  │
  ▼
Mattermost #ops-alerts (immediate, automated)
  │
  ├─ P3/P4 ──► Primary On-Call acknowledges within 4h (business hours)
  │
  ├─ P2 ──────► Primary On-Call responds within 1h (any time)
  │               │
  │               └─ No response in 30 min ──► Page Secondary On-Call
  │
  └─ P1 ──────► Page Primary On-Call immediately
                  │
                  ├─ No response in 15 min ──► Page Secondary On-Call
                  │
                  └─ No response in another 15 min ──► Page Escalation Manager
```

### Notification Channels

| Channel | Used For | Tool |
|---------|---------|------|
| Mattermost `#ops-alerts` | All automated Zabbix/Graylog alerts | Zabbix webhook |
| Mattermost `#incidents` | Active incident coordination | Manual |
| Mattermost `#on-call` | Rotation schedule, ack confirmations | Manual |
| Phone / SMS | P1 escalation when Mattermost is down | PagerDuty or manually |
| Email | P3/P4 non-urgent notifications | Zabbix SMTP action |

---

## Incident Response Procedures

### P1 — Critical Service Down

**Goal: Restore service within RTO target (see below)**

1. **Acknowledge** the Zabbix alert immediately (prevents repeat paging).
2. **Identify** affected service and server:
   ```bash
   ansible all -i inventory/hosts.ini -m ping
   ssh ansible@<affected-host> systemctl status <service>
   ```
3. **Attempt quick restart** (acceptable for non-data-loss scenarios):
   ```bash
   ssh ansible@<host> sudo systemctl restart <service>
   ```
4. **If restart fails** — check logs:
   ```bash
   ssh ansible@<host> journalctl -u <service> -n 50 --no-pager
   # Or check Graylog stream for that host
   ```
5. **Escalate** if not resolved in 30 minutes. Post in `#incidents`.
6. **Post-incident:** File an incident report within 24 hours (see template below).

### P1 — Database Unreachable

1. Verify PostgreSQL is running on `lab-db1`:
   ```bash
   ssh ansible@lab-db1 systemctl status postgresql
   ssh ansible@lab-db1 psql -U postgres -c '\l'
   ```
2. Check disk space (common cause):
   ```bash
   ssh ansible@lab-db1 df -h /var/lib/postgresql
   ```
3. Check for locks / stuck connections:
   ```bash
   ssh ansible@lab-db1 psql -U postgres -c "SELECT pid, state, query_start, query FROM pg_stat_activity WHERE state != 'idle';"
   ```
4. If disk full — purge old backups or WAL segments:
   ```bash
   ssh ansible@lab-db1 find /var/backups/it-stack/postgres -name '*.dump' -mtime +3 -delete
   ```
5. Backup restoration (break-glass):
   ```bash
   ansible-playbook -i inventory/hosts.ini playbooks/test-restore.yml --tags postgres
   ```

### P1 — Identity (FreeIPA / Keycloak) Down

All services authenticate through Keycloak → FreeIPA. Impact is **all users locked out**.

1. Check FreeIPA health:
   ```bash
   ssh ansible@lab-id1 ipactl status
   ssh ansible@lab-id1 curl -sf https://lab-id1/ipa/ui/ | head -5
   ```
2. Restart FreeIPA services:
   ```bash
   ssh ansible@lab-id1 sudo ipactl restart
   ```
3. Check Keycloak:
   ```bash
   ssh ansible@lab-id1 systemctl status keycloak
   ssh ansible@lab-id1 curl -sf http://localhost:8080/health/ready
   ```
4. Emergency user access (break-glass local accounts):
   - Each server has a local `ansible` sudo user (key-only)
   - Temporary direct login to avoid SSO dependency during recovery

---

## RTO / RPO Targets

| Component | RPO | RTO |
|-----------|-----|-----|
| PostgreSQL (single DB) | 24 hours | 15 min (< 1 GB) / 60 min (< 10 GB) |
| PostgreSQL (full cluster) | 24 hours | 2–4 hours |
| Nextcloud files | 24 hours | 30 min (rsync) |
| Service configs | 24 hours | 5 min (tar extract) |
| FreeIPA (identity) | N/A (rebuilt via Ansible) | 45 min |
| Keycloak | N/A (state in PostgreSQL) | 15 min |
| Traefik | N/A (stateless) | 5 min |

> RTO = time from start of restore to service available.  
> Run `make test-restore` quarterly to verify these targets remain achievable.

---

## Incident Report Template

Post to `#incidents` (or a ticket in GLPI) after every P1/P2:

```
## Incident Report — [SERVICE] [DATE]

**Severity:** P1 / P2
**Duration:** HH:MM – HH:MM UTC (X minutes)
**Impact:** [Which users / services were affected]
**Root Cause:** [What broke and why]
**Detection:** Zabbix alert / user report / monitoring gap
**Timeline:**
  - HH:MM – Alert fired
  - HH:MM – Acknowledged by [name]
  - HH:MM – Root cause identified
  - HH:MM – Fix applied
  - HH:MM – Service restored
**Fix Applied:** [Exact commands or Ansible run]
**Prevention:** [What will stop this happening again]
**Follow-up Issues:** [GLPI ticket numbers]
```

---

## Scheduled Maintenance Windows

| Frequency | Time | Duration | Purpose |
|-----------|------|----------|---------|
| Weekly | Sunday 02:00–04:00 UTC | 2 hours | Security patches (`make harden`) |
| Monthly | First Sunday 01:00–05:00 | 4 hours | OS upgrades, cert rotation |
| Quarterly | TBD | Half day | DR test, `make test-restore`, load test |

Announce maintenance in Mattermost `#maintenance` at least **24 hours** in advance.

---

## Silence / Maintenance Mode

To suppress Zabbix alerts during maintenance:

```bash
# Via Zabbix API (from ansible-playbook or manual)
curl -s -X POST https://zabbix.yourdomain.com/api_jsonrpc.php \
  -H 'Content-Type: application/json' \
  -d '{
    "jsonrpc":"2.0","method":"maintenance.create",
    "params":{
      "name":"Maintenance window '"$(date +%F)"'",
      "active_since":'"$(date +%s)"',
      "active_till":'"$(($(date +%s) + 7200))"',
      "hosts":[{"hostid":"ALL"}],
      "timeperiods":[{"period":7200}]
    },
    "auth":"<ZABBIX_TOKEN>","id":1
  }'
```

Or use the Zabbix web UI → Configuration → Maintenance.

---

## Contact Directory Template

> Replace with your organisation's actual contacts.

| Role | Name | Mattermost | Phone |
|------|------|-----------|-------|
| Primary On-Call | *See rotation* | `@primary-oncall` | — |
| Secondary On-Call | *See rotation* | `@secondary-oncall` | — |
| Escalation Manager | *TBD* | `@it-manager` | — |
| PostgreSQL DBA | *TBD* | `@dba` | — |
| Network Admin | *TBD* | `@netops` | — |

---

*This document should be reviewed and contact information updated at least quarterly.*  
*Run `make test-restore` quarterly to verify RTO/RPO targets remain achievable.*
