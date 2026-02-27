# Support

IT-Stack is a community-driven open-source project. Support is provided on a best-effort basis by maintainers and community members.

---

## Before Asking for Help

1. **Check the documentation** — most common questions are answered in the lab manuals
2. **Search existing issues** in the relevant repository
3. **Read the troubleshooting guide** in the module's `docs/TROUBLESHOOTING.md`
4. **Check the debug checklist** below

---

## Quick Debug Checklist

Work through this list before opening an issue:

```bash
# 1. Service status
systemctl status {service}

# 2. Recent logs
journalctl -u {service} -n 100 --no-pager

# 3. Docker logs (if containerized)
docker compose logs -f {service-name}

# 4. Connectivity to PostgreSQL
psql -h lab-db1 -U {service_user} -d {service_db} -c '\conninfo'

# 5. Keycloak SSO (if OIDC/SAML issue)
# Check realm → Clients → {service} → Settings and Credentials tabs
# Check Events → Login events for error details

# 6. FreeIPA / LDAP
ldapsearch -H ldap://lab-id1 -x -D "uid=admin,cn=users,cn=accounts,dc=lab,dc=local" -W -b "cn=users,cn=accounts,dc=lab,dc=local" "(uid={username})"

# 7. DNS resolution
dig @lab-id1 {hostname}.lab.local

# 8. Firewall
sudo ufw status numbered

# 9. Certificate validity
openssl s_client -connect {host}:443 -servername {host} </dev/null 2>/dev/null | openssl x509 -noout -dates

# 10. Traefik routing
# Dashboard: https://lab-proxy1:8080 → HTTP → Routers
```

---

## Documentation

| Resource | URL / Path |
|----------|-----------|
| Master Index | [docs/MASTER-INDEX.md](docs/MASTER-INDEX.md) |
| Architecture (8-server) | [docs/enterprise-stack-complete-v2.md](docs/enterprise-stack-complete-v2.md) |
| Lab Part 1: Network & OS | [docs/enterprise-it-lab-manual.md](docs/enterprise-it-lab-manual.md) |
| Lab Part 2: Identity/DB/SSO | [docs/enterprise-it-lab-manual-part2.md](docs/enterprise-it-lab-manual-part2.md) |
| Lab Part 3: Collaboration | [docs/enterprise-it-lab-manual-part3.md](docs/enterprise-it-lab-manual-part3.md) |
| Lab Part 4: Communications | [docs/enterprise-it-lab-manual-part4.md](docs/enterprise-it-lab-manual-part4.md) |
| Lab Part 5: Back Office | [docs/enterprise-lab-manual-part5.md](docs/enterprise-lab-manual-part5.md) |
| Integration Guide | [docs/integration-guide-complete.md](docs/integration-guide-complete.md) |
| Task Tracker | [docs/IT-STACK-TODO.md](docs/IT-STACK-TODO.md) |

---

## GitHub Issues

For bugs, feature requests, or lab issues:

- **Use the correct repository** — each module has its own repo (`it-stack-{module}`)
- **Use the correct labels** — `lab`, `module-XX`, `phase-X`, `priority-*`
- **Include context** — OS version, Docker version, which lab, which step failed

| Repo | Use For |
|------|---------|
| [it-stack-docs](https://github.com/it-stack-dev/it-stack-docs) | Documentation bugs, missing content |
| [it-stack-freeipa](https://github.com/it-stack-dev/it-stack-freeipa) | FreeIPA-specific issues |
| [it-stack-keycloak](https://github.com/it-stack-dev/it-stack-keycloak) | Keycloak, SSO, OIDC, SAML issues |
| [it-stack-postgresql](https://github.com/it-stack-dev/it-stack-postgresql) | PostgreSQL, database connection issues |
| [it-stack-traefik](https://github.com/it-stack-dev/it-stack-traefik) | Reverse proxy, routing, TLS issues |
| [it-stack-nextcloud](https://github.com/it-stack-dev/it-stack-nextcloud) | File storage, CalDAV, LDAP sync |
| [it-stack-mattermost](https://github.com/it-stack-dev/it-stack-mattermost) | Chat, webhooks, notifications |
| [it-stack-installer](https://github.com/it-stack-dev/it-stack-installer) | Setup scripts, bootstrap automation |
| [it-stack-ansible](https://github.com/it-stack-dev/it-stack-ansible) | Ansible playbooks, roles, vars |
| [it-stack-testing](https://github.com/it-stack-dev/it-stack-testing) | Integration tests, lab scripts |

---

## GitHub Discussions

For questions that aren't bugs — "how do I…", "would it work if…", "can someone help with…":

- Use **GitHub Discussions** in the relevant repository
- Or use the parent [it-stack-docs Discussions](https://github.com/it-stack-dev/it-stack-docs/discussions) for general questions

---

## Community Channels

> These will be set up once the Mattermost deployment (Phase 2) is complete.

| Channel | Purpose |
|---------|---------|
| `#general` | General IT-Stack discussion |
| `#labs` | Lab progress, questions, and results |
| `#ops-alerts` | Infrastructure alerts (Zabbix integration) |
| `#deployments` | Deployment announcements |
| `#security` | Security discussions |

---

## Common Issues by Module

### FreeIPA
- **Kerberos clock skew error** — NTP must be synchronized across all nodes (`timedatectl status`)
- **LDAP bind fails** — check `nsslapd-minssf` setting requires TLS; use `ldaps://` or StartTLS
- **Replica not syncing** — check `/var/log/dirsrv/slapd-*/errors` on both master and replica

### Keycloak
- **"Invalid redirect_uri"** — the registered URI in the client config must exactly match what the service sends
- **LDAP federation not syncing** — check connection test in Keycloak → User Federation → Test connection / Test authentication
- **Token expiry causing logout loops** — adjust `accessTokenLifespan` and `ssoSessionMaxLifespan` in realm settings

### PostgreSQL
- **"pg_hba.conf" rejection** — add an entry for the source IP/network using `scram-sha-256`
- **"too many connections"** — add a PgBouncer connection pooler between application and PostgreSQL
- **Slow queries** — `EXPLAIN ANALYZE {query}` and check for missing indexes via `pg_stat_user_tables`

### Traefik
- **Certificate not renewing** — check `/var/log/traefik/traefik.log` for ACME errors; verify port 80 is reachable from Let's Encrypt
- **502 Bad Gateway** — backend service is down or health check failed; check Traefik dashboard
- **Service not appearing in dashboard** — Docker label syntax error or service not on the correct Docker network

### Nextcloud
- **"Trusted domain" error** — add the domain to `config.php` `trusted_domains` array or use `occ config:system:set`
- **Cron not running** — check `docker exec -u www-data nextcloud php cron.php` and configure crontab
- **LDAP users not seeing files** — check user home directory provisioning; set `ldapExpertUUIDUserAttr` to `uid`

### Mattermost
- **Email notifications not sending** — check SMTP settings in System Console → Notifications → Email
- **SSO redirect loop** — verify the Keycloak client redirect URI includes the Mattermost base URL with trailing slash

---

## No SLA / Commercial Support

IT-Stack is community-supported open-source software. There is no SLA, no guaranteed response time, and no commercial support contract.

If your organization requires guaranteed support, consider:
- Hiring a systems administrator experienced with these open-source tools
- Engaging a Red Hat / Canonical partner for FreeIPA and Ubuntu support
- Using commercially supported versions (e.g., Red Hat Identity Management, Bitnami stacks)

---

## Security Issues

**Do not report security vulnerabilities in public issues.**

See [SECURITY.md](SECURITY.md) for the responsible disclosure process.
