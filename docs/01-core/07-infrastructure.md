---
doc: "01-core-07"
title: "Infrastructure — Traefik + Zabbix + Graylog"
category: infrastructure
phase: 1 (Traefik) / 4 (Zabbix, Graylog)
servers: [lab-proxy1]
date: 2026-02-27
---

# Infrastructure

> **Category:** Infrastructure — Layer 7  
> **Phase:** 1 (Traefik) · 4 (Zabbix, Graylog)  
> **Servers:** `lab-proxy1` (10.0.50.15, 8 GB RAM)  
> **Modules:** Traefik (18) · Zabbix (19) · Graylog (20)

---

## Module 18: Traefik

**Repo:** [it-stack-traefik](https://github.com/it-stack-dev/it-stack-traefik)  
**Ports:** 80 (HTTP→HTTPS redirect), 443 (HTTPS), 8080 (dashboard)  
**Phase:** 1 (Foundation — required before all other services)

### Subdomain Routing

| Subdomain | Backend Service | Port |
|-----------|----------------|------|
| `cloud.example.com` | Nextcloud | 80 |
| `chat.example.com` | Mattermost | 8065 |
| `meet.example.com` | Jitsi | 443 |
| `mail.example.com` | iRedMail | 443 |
| `desk.example.com` | Zammad | 3000 |
| `crm.example.com` | SuiteCRM | 443 |
| `erp.example.com` | Odoo | 8069 |
| `docs.example.com` | OpenKM | 8080 |
| `pm.example.com` | Taiga | 443 |
| `assets.example.com` | Snipe-IT | 443 |
| `itsm.example.com` | GLPI | 443 |
| `monitor.example.com` | Zabbix | 3000 |
| `logs.example.com` | Graylog | 9000 |
| `id.example.com` | Keycloak | 8443 |

### TLS Strategy

```yaml
# traefik.yml
certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@example.com
      storage: /data/acme.json
      tlsChallenge: {}
  # Internal CA for lab environments (no public DNS)
  internal:
    acme:
      caServer: https://lab-id1/ipa/acme/directory
```

---

## Module 19: Zabbix

**Repo:** [it-stack-zabbix](https://github.com/it-stack-dev/it-stack-zabbix)  
**Port:** 10051 (agent), 3000 (Grafana dashboard) · **Subdomain:** `monitor.example.com`  
**Phase:** 4  
**Replaces:** Datadog, Nagios, PRTG

### Monitored Hosts

All 8 servers monitored via Zabbix Agent 2:

| Host | Key Metrics |
|------|------------|
| lab-id1 | FreeIPA LDAP response, Kerberos TGT, DNS |
| lab-db1 | PostgreSQL connections, Redis memory, ES cluster health |
| lab-app1 | Nextcloud cron, Mattermost websockets, Jitsi JVB |
| lab-comm1 | Postfix queue, Dovecot connections, Zammad jobs |
| lab-proxy1 | Traefik active connections, cert expiry, Graylog lag |
| lab-pbx1 | Asterisk channels, SIP trunk status, RTP packet loss |
| lab-biz1 | Odoo workers, SuiteCRM cron, OpenKM JVM heap |
| lab-mgmt1 | Taiga Celery workers, GLPI cron, Snipe-IT queue |

### Alert Routing

```
Zabbix problem → Webhook → Mattermost #ops-alerts
              → Email  → ops-team@example.com
              → (Critical) SMS via Zabbix SMS media
```

---

## Module 20: Graylog

**Repo:** [it-stack-graylog](https://github.com/it-stack-dev/it-stack-graylog)  
**Ports:** 9000 (web UI), 1514 (Syslog), 12201 (GELF) · **Subdomain:** `logs.example.com`  
**Phase:** 4  
**Replaces:** Splunk, Datadog Logs, Elastic Stack (ELK)

### Log Sources

| Source | Protocol | Input |
|--------|----------|-------|
| All 8 servers | Syslog UDP | Port 1514 |
| Docker containers | GELF | Port 12201 |
| Nginx/Traefik | Syslog | Port 1514 |
| Mattermost | GELF | Port 12201 |
| Zammad | Filebeat | Port 12201 |
| Odoo | GELF | Port 12201 |

### Streams & Alerts

| Stream | Criteria | Alert To |
|--------|----------|---------|
| Security Events | `auth_failure`, `sudo`, SSH login | Mattermost #security |
| Application Errors | `level:error`, `level:critical` | Mattermost #ops-alerts |
| Slow Queries | PostgreSQL `duration > 1000ms` | Zabbix trigger |

### Graylog → Zabbix Integration

Graylog alert callbacks call the Zabbix external check API, allowing log-based events
to trigger Zabbix problem states and go through the standard alert routing.
