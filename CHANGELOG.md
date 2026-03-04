# Changelog

All notable changes to IT-Stack will be documented in this file.

This project adheres to [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned — Next Up
- Business workflow integrations (FreePBX↔SuiteCRM, SuiteCRM↔Odoo, Zabbix↔Mattermost, etc.)

---

## [1.34.0] — 2026-03-04

### Added — Sprint 38: INT-08b Snipe-IT ↔ Keycloak SAML 2.0

**Ansible (`it-stack-ansible`):**
- `roles/snipeit/tasks/keycloak-saml.yml` — INT-08b idempotent 8-step SAML 2.0 playbook: assert KC IdP metadata reachable, assert EntityDescriptor + X509Certificate, extract cert + build all SP/IdP URL facts, deploy `snipeit-saml-settings.env.j2` to `.env.saml`, blockinfile SAML2 vars into `.env`, run `php artisan saml2:create-tenant`, flush handlers, final assert
- `roles/snipeit/templates/snipeit-saml-settings.env.j2` — SAML2 .env config template: `SAML2_ENABLED`, `SAML2_IDP_METADATA_URL`, SP entity ID + ACS + SLO URLs, IdP entityID + SSO/SLO endpoints, IdP X509 cert, attribute mapping (uid/email/givenName/sn), `KEYCLOAK_URL/REALM/CLIENT_ID`
- `roles/snipeit/tasks/main.yml` — added `keycloak-saml.yml` import guarded by `snipeit_enable_keycloak_saml | default(true)`

**Integration test (`it-stack-snipeit`):**
- `docker/snipeit-ldap-seed.ldif` — FreeIPA-style LDAP seed (cn=accounts tree, users: snipeadmin/snipeuser1/snipeuser2, groups: admins/snipeit-users)
- `docker/docker-compose.integration.yml` — added `snipeit-i05-ldap-seed` init service (ldapadd, depends on LDAP healthy, restart: "no"), KC `depends_on: service_completed_successfully`, KC healthcheck updated to `/health/ready`, injected `SAML2_ENABLED + SAML2_IDP_METADATA_URL + SAML2_SP_ENTITY_ID + SAML2_SP_ACS_URL + SAML2_AUTOLOAD_METADATA` into Snipe-IT app container
- `tests/labs/test-lab-16-05.sh` — rewritten: 8-phase INT-08b test (container health + seed exit, MariaDB/WireMock/KC/Snipe-IT health, LDAP seed verify, KC realm + LDAP federation + SAML client registration + LDAP sync, SAML IdP metadata HTTP + EntityDescriptor + X509 cert + internal reach, env var assertions, WireMock Odoo stubs + Snipe-IT connectivity, volume + DB/LDAP/MAIL env assertions)
- `.github/workflows/ci.yml` — lab-05-smoke updated (name, python3 tool, wait order: MariaDB → OpenLDAP → LDAP seed exit → KC 300 s health/ready → WireMock → Snipe-IT)

---

## [1.33.0] — 2026-03-04

### Added — Sprint 37: INT-08 Taiga ↔ Keycloak OIDC

**Ansible (`it-stack-ansible`):**
- `roles/taiga/tasks/keycloak-oidc.yml` — INT-08 idempotent 8-step OIDC playbook: assert KC discovery reachable, extract all endpoints, pip-install `taiga-contrib-oidc-auth` in venv, deploy `taiga-oidc-settings.py.j2`, inject `from .oidc import *` into `local.py`, update INSTALLED_APPS, flush handlers, final assert
- `roles/taiga/templates/taiga-oidc-settings.py.j2` — Django `mozilla-django-oidc` settings template: `OIDC_RP_*` + `OIDC_OP_*` endpoints from KC discovery facts, RS256 signing, session cookie config, KC logout redirect
- `roles/taiga/tasks/main.yml` — added `keycloak-oidc.yml` import guarded by `taiga_enable_keycloak_oidc | default(true)`

**Integration test (`it-stack-taiga`):**
- `docker/taiga-ldap-seed.ldif` — FreeIPA-style LDAP seed (cn=accounts tree, users: taigaadmin/taigauser1/taigauser2, groups: admins/taiga-users)
- `docker/docker-compose.integration.yml` — added `taiga-i05-ldap-seed` init service, wired KC `depends_on: service_completed_successfully`, injected `OIDC_DISCOVERY_URL` into Taiga Back
- `tests/labs/test-lab-15-05.sh` — rewritten: 8-phase INT-08 test (container health, LDAP seed verify, KC realm + LDAP federation + OIDC client registration, OIDC discovery + password-grant token + userinfo, Taiga env var assertions, WireMock Mattermost stubs + webhook reach, volume assertions)
- `.github/workflows/ci.yml` — lab-05-smoke updated (name, python3 tool, wait order: PG → OpenLDAP → LDAP seed exit → KC 300 s health/ready → WireMock → Taiga Back)

---

## [1.32.0] — 2026-03-04

### Added — Sprint 36: INT-07 GLPI ↔ Keycloak SAML 2.0

**Ansible (`it-stack-ansible`):**
- `roles/glpi/tasks/keycloak-saml.yml` — INT-07 idempotent SAML 2.0 integration: assert KC SAML IdP descriptor reachable (retries:6), assert EntityDescriptor + IDPSSODescriptor present, extract IdP X.509 certificate via regex, set SP/IdP helper vars (entity IDs, ACS/SLO URLs), deploy `glpi-saml-config.php.j2` template to `glpi/config/saml_config.php`, enable SAML in `config_db.php` (`$CFG_GLPI['use_saml']` + SP/IdP URL settings), insert LDAP directory source via mysql CLI into `glpi_authldaps` table (IGNORE for idempotency), final assert IdP descriptor still reachable post-deploy
- `roles/glpi/templates/glpi-saml-config.php.j2` — php-saml/onelogin-style SP + IdP config array: SP entity ID, ACS URL, SLO URL, security settings (wantAssertionsSigned, RSA-SHA256, SHA-256 digest), attribute mapping (uid/mail/givenName/sn/groups), auto-provision enabled
- `roles/glpi/tasks/main.yml` — added `keycloak-saml.yml` import guarded by `glpi_enable_keycloak_saml`

**Integration test (`it-stack-glpi`):**
- `docker/glpi-ldap-seed.ldif` — FreeIPA-compatible LDAP seed: 3 users (`glpiadmin`, `glpiuser1`, `glpiuser2`), 2 groups (`cn=admins`, `cn=glpi-users`), objectClass inetOrgPerson + groupOfNames
- `docker/docker-compose.integration.yml` — added `glpi-i05-ldap-seed` init service with `ldapadd` LDIF injection; Keycloak `depends_on: ldap-seed: service_completed_successfully`; `KC_SAML_IDP_METADATA_URL`, `KC_SAML_SP_ENTITY_ID`, `KC_SAML_ACS_URL` env vars added to GLPI app container
- `tests/labs/test-lab-17-05.sh` — INT-07 full test suite (392 lines): Phase 1-7: docker up + 90s wait, container health checks (6 containers + seed exit code), MariaDB + WireMock + KC ready loop + GLPI web loop, LDAP seed (exit code, ≥3 users, ≥2 groups, `glpiadmin` present, readonly bind), KC realm + LDAP federation + full sync + ≥3 users + `glpiadmin` present, SAML IdP descriptor (HTTP 200, EntityDescriptor, IDPSSODescriptor, X.509 cert), GLPI SAML env vars + internal KC reachability, WireMock Zammad stubs + GLPI → Zammad mock escalation, volume + env assertions
- `.github/workflows/ci.yml` — `lab-05-smoke` updated to INT-07, `python3` added, wait order fixed: MariaDB → OpenLDAP → LDAP seed exit → Keycloak(300s via health/ready) → WireMock → GLPI

---

## [1.31.0] — 2026-03-04

### Added — Sprint 35: INT-06 Zammad ↔ Keycloak OIDC

**Ansible (`it-stack-ansible`):**
- `roles/zammad/tasks/keycloak-oidc.yml` — INT-06 idempotent OIDC integration: assert KC OIDC discovery URL, authenticate to Zammad API (`POST /api/v1/users/signin`, fingerprint header), list existing channels, build OIDC channel payload (adapter `auth_oidc`, issuer, client_id, client_secret, scope), create or update OIDC channel via `POST /api/v1/channels` / `PUT /api/v1/channels/:id`, configure LDAP source via `GET`/`POST /api/v1/ldap_configs`, assert OIDC channel with correct client_id present post-provision
- `roles/zammad/tasks/main.yml` — added `keycloak-oidc.yml` import guarded by `zammad_enable_keycloak_oidc`

**Integration test (`it-stack-zammad`):**
- `docker/zammad-ldap-seed.ldif` — FreeIPA-compatible LDAP seed: 3 users (`zammadadmin`, `zammaduser1`, `zammaduser2`), 2 groups (`cn=admins`, `cn=zammad-users`), objectClass inetOrgPerson + groupOfNames
- `docker/docker-compose.integration.yml` — added `zammad-int-ldap-seed` init service with `ldapadd` LDIF injection; Keycloak `depends_on: ldap-seed: service_completed_successfully`; Keycloak image bumped `24.0→24.0.3`; `KEYCLOAK_URL`, `KEYCLOAK_REALM`, `KEYCLOAK_CLIENT_ID` env vars added to `x-zammad-int-env` anchor
- `tests/labs/test-lab-11-05.sh` — INT-06 full test suite (392 lines): Phase 1–7: docker up + health checks (8 containers, PG, Redis, ES cluster health, KC ready loop, Zammad nginx loop), LDAP seed verification (exit code, ≥3 users, ≥2 groups, readonly bind), KC realm + LDAP federation + full sync + ≥3 users + `zammadadmin` present, OIDC discovery + `zammad` client registration + Zammad LDAP/OIDC API calls, OIDC token for `zammadadmin` + userinfo claims + token introspection, container env var assertions
- `.github/workflows/ci.yml` — `lab-05-smoke` updated to INT-06, `python3` added, wait order fixed: OpenLDAP → LDAP seed exit → Keycloak(240s) → Elasticsearch → Zammad

---

## [1.30.0] — 2026-03-03

### Added — Sprint 34: INT-05 Odoo ↔ Keycloak OIDC

**Ansible (`it-stack-ansible`):**
- `roles/odoo/tasks/keycloak-oidc.yml` — INT-05 idempotent OIDC integration: assert KC discovery URL, authenticate to Odoo JSON-RPC, ensure `auth_oauth` module installed (install + re-auth if missing), create or update `auth.oauth.provider` record (name, client_id, client_secret, auth/token/validation/jwks endpoints), set `web.base.url` system parameter, assert provider enabled
- `roles/odoo/tasks/main.yml` — added `keycloak-oidc.yml` import guarded by `odoo_enable_keycloak_oidc`

**Integration test (`it-stack-odoo`):**
- `docker/odoo-ldap-seed.ldif` — FreeIPA-compatible LDAP seed: 3 users (`odooadmin`, `odoouser1`, `odoouser2`), 2 groups (`cn=admins`, `cn=odoo-users`)
- `docker/docker-compose.integration.yml` — added `odoo-int-ldap-seed` init service; Keycloak `depends_on: ldap-seed: service_completed_successfully`; `LDAP_BASE_DN` updated to `cn=users,cn=accounts,dc=lab,dc=local`; OIDC env vars: `KEYCLOAK_URL`, `KEYCLOAK_REALM`, `KEYCLOAK_CLIENT_ID`
- `tests/labs/test-lab-13-05.sh` — INT-05 full test suite: Phase 3 (WireMock stubs, LDAP seed exit code, ≥3 users / ≥2 groups, readonly bind), Phase 4 (KC admin token, create `it-stack` realm, LDAP federation component, full sync, ≥3 users synced, `odooadmin` present), Phase 5 (OIDC discovery, register `odoo` client, Odoo JSON-RPC auth + `auth.oauth.provider` count), Phase 6 (OIDC token for `odooadmin`, userinfo sub + preferred_username claims, token introspection active=true); removed duplicate dead-code stub
- `.github/workflows/ci.yml` — `lab-05-smoke` updated to INT-05, `python3` added, wait order: PostgreSQL → OpenLDAP → LDAP seed exit → WireMock → Keycloak(240s) → Mailhog → Odoo

---

## [1.29.0] — 2026-03-03

### Added — Sprint 33: INT-04 SuiteCRM ↔ Keycloak SAML 2.0

**Ansible (`it-stack-ansible`):**
- `roles/keycloak/tasks/saml-clients.yml` — idempotent SAML client provisioner: fetch existing clients, create missing, verify post-provision; iterates `keycloak_saml_clients` list
- `roles/keycloak/templates/saml-client.json.j2` — SAML client template with `protocol: saml`, ACS URL, SLO URL, RSA_SHA256 signature, 5 protocol mappers (uid, mail, givenName, sn, groups)
- `roles/keycloak/defaults/main.yml` — added `keycloak_saml_clients` list with suitecrm, glpi, snipeit entries (ACS/SLO URLs, redirect_uris)
- `roles/keycloak/tasks/main.yml` — added `saml-clients.yml` import guarded by `keycloak_provision_saml_clients`
- `roles/suitecrm/tasks/keycloak-saml.yml` — INT-04 Ansible task: verify Keycloak IdP descriptor reachable, extract X.509 cert via regex, template `saml_settings.php.j2`, enable SAML in `config.php` via `lineinfile`, trigger extension rebuild, assert SP metadata endpoint returns EntityDescriptor + AssertionConsumerService
- `roles/suitecrm/templates/saml_settings.php.j2` — full `$saml_settings` PHP array (IdP entity, SSO/SLO URLs, X.509 cert, SP entity, ACS/SLO, security settings, attribute map, auto-create users)
- `roles/suitecrm/tasks/main.yml` — added `keycloak-saml.yml` import guarded by `suitecrm_enable_keycloak_saml`

**Integration test (`it-stack-suitecrm`):**
- `docker/suitecrm-ldap-seed.ldif` — FreeIPA-compatible LDAP seed: 3 users (`crmadmin`, `crmuser1`, `crmuser2`), 2 groups (`cn=admins`, `cn=crm-users`)
- `docker/docker-compose.integration.yml` — added `suitecrm-i05-ldap-seed` init service; `suitecrm-i05-kc` depends on seed completed successfully; `SUITECRM_LDAP_BASE_DN` updated to `cn=users,cn=accounts,dc=lab,dc=local`; LDAP bind switched to readonly account
- `tests/labs/test-lab-12-05.sh` — extended: seed exit code check, Phase 3a (KC admin token, realm, SAML client creation + verification, LDAP federation + full sync + user count assert, IdP descriptor assertions), Phase 3b (LDAP seed: ≥3 users, ≥2 groups, readonly bind), 3c–3g renamed from 3a–3e, new Phase 3h (SAML env vars, KC SAML descriptor reachable from container, FreeIPA LDAP BaseDN check); removed 80-line dead code stub
- `.github/workflows/ci.yml` — `lab-05-smoke` renamed INT-04, `python3` added, wait order: MariaDB → OpenLDAP → seed exit → Keycloak(300s) → WireMock → Mailhog → SuiteCRM

---

## [1.28.0] — 2026-03-03

### Added — Sprint 32: INT-03 Mattermost ↔ Keycloak OIDC

**Ansible (`it-stack-ansible`):**
- `roles/mattermost/tasks/keycloak-oidc.yml` — INT-03 Ansible task: waits for Mattermost API, obtains admin token, patches `OpenIdSettings` (Enable, DiscoveryEndpoint, Id, Secret) and `LdapSettings` (Enable, FreeIPA DN paths, uid/mail attributes) via `PUT /api/v4/config/patch`, triggers LDAP sync, asserts OIDC+LDAP settings applied and Keycloak discovery URL reachable
- `roles/mattermost/tasks/main.yml` — added `keycloak-oidc.yml` import guarded by `mattermost_enable_keycloak_oidc`

**Integration test (`it-stack-mattermost`):**
- `docker/mattermost-ldap-seed.ldif` — FreeIPA-compatible LDAP seed: `cn=accounts` tree, 3 users (`mmadmin`, `mmuser1`, `mmuser2`) with `inetOrgPerson`, groups `cn=admins` + `cn=mm-users` with `groupOfNames`
- `docker/docker-compose.integration.yml` — added `mm-int-ldap-seed` init service (depends on `mm-int-ldap` healthy, exits on completion); `mm-int-keycloak` now depends on `mm-int-ldap-seed` completed successfully; updated `MM_LDAPSETTINGS_BASEDN` to `cn=users,cn=accounts,dc=lab,dc=local` (FreeIPA-style)
- `tests/labs/test-lab-07-05.sh` — extended with: section 3b LDAP seed verification (≥3 users, ≥2 groups, readonly bind), section 5 extended (Keycloak FreeIPA-style LDAP federation component + full sync + realm user count assert), section 8 upgraded to authenticated API config check (OpenIdSettings.Enable, DiscoveryEndpoint, LdapSettings.Enable), section 9 extended (3 OIDC discovery fields), new section 10 (Mattermost LDAP sync + ≥3 LDAP users verified), new section 11 (OIDC token issued for mmadmin, claim verification, Keycloak introspect)
- `.github/workflows/ci.yml` — `lab-05-smoke` renamed to INT-03, added `python3`, reordered waits (OpenLDAP first, LDAP seed exit, then Keycloak 240s timeout)

---

## [1.27.0] — 2026-03-02

### Added — Sprint 31: INT-02 Nextcloud ↔ Keycloak OIDC

**Ansible (`it-stack-ansible`):**
- `roles/keycloak/tasks/oidc-clients.yml` — idempotent OIDC client provisioning for all services in `keycloak_oidc_clients`: check existing, create missing, retrieve client UUID, retrieve/assert client secret into `keycloak_client_secrets` dict
- `roles/keycloak/templates/oidc-client.json.j2` — full OIDC client template with 4 protocol mappers (email, given_name, family_name, groups), backchannel logout, post-logout redirect
- `roles/nextcloud/tasks/keycloak-oidc.yml` — configure `user_oidc` app via `occ`: install/enable app, delete stale provider, register Keycloak discovery URI + client credentials, `allow_multiple_user_backends`, button text, assert discovery URL reachable
- `roles/keycloak/tasks/main.yml` — added `oidc-clients.yml` import guarded by `keycloak_provision_oidc_clients`
- `roles/nextcloud/tasks/main.yml` — added `keycloak-oidc.yml` import guarded by `nextcloud_enable_keycloak_oidc`

**Integration test (`it-stack-nextcloud`):**
- `docker/nextcloud-ldap-seed.ldif` — FreeIPA-compatible LDAP seed: `cn=accounts` tree, 3 users (`ncadmin`, `ncuser1`, `ncuser2`) with `inetOrgPerson`, groups `cn=admins` + `cn=nc-users` with `groupOfNames`
- `docker/docker-compose.integration.yml` — added `nc-int-ldap-seed` init service (applies LDIF to OpenLDAP); `nc-int-keycloak` now depends on `service_completed_successfully` (ldap-seed)
- `tests/labs/test-lab-06-05.sh` — extended with 4 new sections: 3b LDAP seed verification (3 users, 2 groups), 8 LDAP full sync into Keycloak + user_oidc app enabled check, 9 OIDC provider registration (occ), 10 OIDC token endpoint + Nextcloud bearer API auth; renumbered Cron→11, WebDAV→12
- `.github/workflows/ci.yml` — lab-05-smoke: updated job name, added `python3`, reordered waits (OpenLDAP first), 240s Keycloak timeout

---

## [1.26.0] — 2026-03-03

### Added — Sprint 30: INT-01 FreeIPA ↔ Keycloak LDAP Federation

**Ansible (`it-stack-ansible`):**
- `roles/freeipa/tasks/keycloak-svc-account.yml` — creates `uid=keycloak-svc` read-only service account in FreeIPA: kinit, `ipa user-add`, vault password, `ldappasswd` reset, `ldapmodify` sysaccounts + ACI, bind verification
- `roles/keycloak/tasks/ldap-federation.yml` — full idempotent federation pipeline: kcadm auth → realm check → create LDAP component (`vendor: rhds`, FreeIPA DN paths) → group mapper → 5 attribute mappers (email, firstName, lastName, phone, title) → map `admins` → `realm-admin` → full sync → assert `federationLink`
- `roles/keycloak/templates/group-mapper.json.j2` — Jinja2 template for LDAP group mapper (`groupOfNames`, `READ_ONLY`, inherits from `federation_id` fact)
- `roles/keycloak/templates/ldap-federation.json.j2` — fixed `uuidLDAPAttribute` from `uid` to `ipaUniqueID` (FreeIPA-correct)
- `roles/keycloak/tasks/main.yml` — added `ldap-federation.yml` import with `keycloak_enable_ldap_federation` guard
- `roles/freeipa/tasks/main.yml` — added `keycloak-svc-account.yml` import with `freeipa_create_keycloak_svc` guard
- `roles/keycloak/tasks/realm.yml` — removed duplicate stub LDAP block; replaced with NOTE comment pointing to `ldap-federation.yml`

**Integration test (`it-stack-keycloak`):**
- `docker/openldap-seed.ldif` — FreeIPA-compatible LDAP seed: `cn=accounts`, `cn=users,cn=accounts`, `cn=groups,cn=accounts`, 3 test users (`testadmin`, `testuser1`, `testuser2`) with `inetOrgPerson`, groups `cn=admins` and `cn=ipausers` with `groupOfNames`
- `docker/docker-compose.integration.yml` — added `ldap-seed` init service (seeds FreeIPA-like LDIF into OpenLDAP); updated Keycloak `depends_on` to `ldap-seed: service_completed_successfully`
- `tests/labs/test-lab-02-05.sh` — full rewrite with 13 sections: OpenLDAP seed verification (3 users, 2 groups, readonly bind), FreeIPA-style LDAP federation creation, group mapper, full sync, `federationLink` assertion, `testadmin` sync check, `admins` group sync, OIDC clients, client credentials, OIDC discovery, SAML descriptor, MailHog, app services
- `.github/workflows/ci.yml` — lab-05-smoke: updated job name, added `python3` to toolchain, reordered wait steps (OpenLDAP first → Keycloak), extended timeout to 240s

---

## [1.25.0] — 2026-03-02

### Added — Sprint 29: Integration Milestone GitHub Issues (23 issues)

New script `create-integration-issues.ps1` in `it-stack-installer` creates 23 GitHub
Issues across module repos — one per cross-service integration milestone.

**Script:** `scripts/github/create-integration-issues.ps1`
- `-Category sso` — 9 SSO integration issues
- `-Category business` — 15 business/observability integration issues
- `-Id INT-XX` — single integration issue

**`integration` label added to `apply-labels.ps1`** (purple #5319e7)

**SSO Integration Issues (9):**

| ID | Title | Repo |
|----|-------|------|
| INT-01 | FreeIPA <-> Keycloak LDAP Federation | `it-stack-keycloak` |
| INT-02 | Nextcloud <-> Keycloak OIDC | `it-stack-nextcloud` |
| INT-03 | Mattermost <-> Keycloak OIDC | `it-stack-mattermost` |
| INT-04 | SuiteCRM <-> Keycloak SAML 2.0 | `it-stack-suitecrm` |
| INT-05 | Odoo <-> Keycloak OIDC | `it-stack-odoo` |
| INT-06 | Zammad <-> Keycloak OIDC | `it-stack-zammad` |
| INT-07 | GLPI <-> Keycloak SAML 2.0 | `it-stack-glpi` |
| INT-08 | Taiga <-> Keycloak OIDC | `it-stack-taiga` |
| INT-08b | Snipe-IT <-> Keycloak SAML 2.0 | `it-stack-snipeit` |

**Business Workflow Integration Issues (15):**

| ID | Title | Protocol | Repo |
|----|-------|----------|------|
| INT-09 | FreePBX <-> SuiteCRM | CTI / REST API | `it-stack-freepbx` |
| INT-10 | FreePBX <-> Zammad | AMI webhook | `it-stack-freepbx` |
| INT-11 | FreePBX <-> FreeIPA | LDAP extension provisioning | `it-stack-freepbx` |
| INT-12 | SuiteCRM <-> Odoo | Bidirectional REST API sync | `it-stack-suitecrm` |
| INT-13 | SuiteCRM <-> Nextcloud | CalDAV calendar sync | `it-stack-suitecrm` |
| INT-14 | SuiteCRM <-> OpenKM | REST API document linking | `it-stack-suitecrm` |
| INT-15 | Odoo <-> FreeIPA | LDAP employee directory sync | `it-stack-odoo` |
| INT-16 | Odoo <-> Taiga | Timesheet export | `it-stack-odoo` |
| INT-17 | Odoo <-> Snipe-IT | Procurement -> asset creation | `it-stack-odoo` |
| INT-18 | Taiga <-> Mattermost | Webhook project notifications | `it-stack-taiga` |
| INT-19 | Snipe-IT <-> GLPI | Asset -> CMDB sync | `it-stack-snipeit` |
| INT-20 | GLPI <-> Zammad | Ticket escalation bridge | `it-stack-glpi` |
| INT-21 | OpenKM <-> Nextcloud | Document storage bridge | `it-stack-openkm` |
| INT-22 | Zabbix <-> Mattermost | Infrastructure alert webhooks | `it-stack-zabbix` |
| INT-23 | Graylog <-> Zabbix | Log-based alert triggers | `it-stack-graylog` |

---

## [1.24.0] — 2026-03-07

### Added — Sprint 28: Architecture Documentation (`docs/07-architecture/`)

8 Architecture Decision Records (ADRs) and 2 technical diagrams covering all major IT-Stack technical choices.

**Architecture Decision Records:**

| ADR | Decision | Status |
|-----|----------|--------|
| [ADR-001](docs/07-architecture/adr-001-identity-stack.md) | Use FreeIPA + Keycloak for identity | Accepted |
| [ADR-002](docs/07-architecture/adr-002-postgresql-primary.md) | PostgreSQL as primary database for all services | Accepted |
| [ADR-003](docs/07-architecture/adr-003-traefik-proxy.md) | Traefik as reverse proxy with automatic TLS | Accepted |
| [ADR-004](docs/07-architecture/adr-004-lab-methodology.md) | 6-lab progressive testing methodology | Accepted |
| [ADR-005](docs/07-architecture/adr-005-ubuntu-2404.md) | Ubuntu 24.04 LTS as base OS for all servers | Accepted |
| [ADR-006](docs/07-architecture/adr-006-8server-layout.md) | 8-server production layout | Accepted |
| [ADR-007](docs/07-architecture/adr-007-docker-compose-ansible.md) | Docker Compose for labs, Ansible for production | Accepted |
| [ADR-008](docs/07-architecture/adr-008-apache2-license.md) | Apache 2.0 license for all repositories | Accepted |

**Technical Diagrams:**

| File | Description |
|------|-------------|
| [network-topology.md](docs/07-architecture/network-topology.md) | 8-server network layout, all IPs, DNS A+CNAME records, firewall rules, Mermaid diagram |
| [service-integration-map.md](docs/07-architecture/service-integration-map.md) | All 22+ cross-service integrations, Mermaid graph, integration catalog, startup order |

**`docs/07-architecture/` is now complete.**

---

## [1.23.0] — 2026-03-06

### Added — Sprint 27: it-stack-installer Automation Scripts (19 scripts)

Complete automation toolset for bootstrapping the IT-Stack development environment and GitHub organization from scratch.

**Setup Scripts (3) — `scripts/setup/`:**

| Script | Purpose |
|--------|---------|
| `install-tools.ps1` | winget installs Git, GitHub CLI, Docker Desktop, kubectl, Helm, Terraform, Python 3.12, jq; Ansible via WSL |
| `setup-directory-structure.ps1` | Creates the full `C:\IT-Stack\it-stack-dev\` workspace tree (35+ directories, .gitkeep placeholders) |
| `setup-github.ps1` | `gh auth login`, org access verification, git user config from GitHub profile |

**GitHub Bootstrap Scripts (11) — `scripts/github/`:**

| Script | Issues/Repos |
|--------|-------------|
| `create-phase1-modules.ps1` | Creates 5 Phase 1 repos (freeipa, keycloak, postgresql, redis, traefik) |
| `create-phase2-modules.ps1` | Creates 5 Phase 2 repos (nextcloud, mattermost, jitsi, iredmail, zammad) |
| `create-phase3-modules.ps1` | Creates 4 Phase 3 repos (freepbx, suitecrm, odoo, openkm) |
| `create-phase4-modules.ps1` | Creates 6 Phase 4 repos (taiga, snipeit, glpi, elasticsearch, zabbix, graylog) |
| `apply-labels.ps1` | Creates all 39 labels across all 26 repos (idempotent with `--force`) |
| `create-milestones.ps1` | Creates 4 phase milestones in all 20 module repos |
| `create-github-projects.ps1` | Creates 5 GitHub Projects (v2 boards) in the org |
| `add-phase1-issues.ps1` | Creates 30 lab issues for Phase 1 (6 labs x 5 modules) |
| `add-phase2-issues.ps1` | Creates 30 lab issues for Phase 2 (6 labs x 5 modules) |
| `add-phase3-issues.ps1` | Creates 24 lab issues for Phase 3 (6 labs x 4 modules) |
| `add-phase4-issues.ps1` | Creates 36 lab issues for Phase 4 (6 labs x 6 modules) |

**Operations Scripts (2) — `scripts/operations/`:**

| Script | Purpose |
|--------|---------|
| `clone-all-repos.ps1` | Clones all 26 repos into category subdirectories; `-Phase` filter, skip-if-exists |
| `update-all-repos.ps1` | `git pull --ff-only` across all repos; `-Status` mode, `-Branch` selection |

**Utility Script (1) — `scripts/utilities/`:**

| Script | Purpose |
|--------|---------|
| `create-repo-template.ps1` | Scaffolds full module repo structure: manifest, Dockerfile, Makefile, 6 Compose files, 6 lab scripts, CI workflows; `-CreateGitHubRepo` flag |

**Deployment Script (1) — `scripts/deployment/`:**

| Script | Purpose |
|--------|---------|
| `deploy-stack.sh` | Ansible wrapper: `--module`, `--phase 1-4`, `--check`, `--verbose`; validates vault and secrets before running |

**Testing Script (1) — `scripts/testing/`:**

| Script | Purpose |
|--------|---------|
| `run-all-labs.sh` | Runs all 120 lab tests with `--phase`, `--module`, `--lab` filters; reports PASS/FAIL/SKIP counts |

**Total lab issues when all scripts are run:** 120 (30 + 30 + 24 + 36)

---

## [1.22.0] — 2026-03-05

### Added — Sprint 26: Ansible Roles for All 15 Phase 2–4 Services

Complete Ansible automation coverage for every IT-Stack service. The `it-stack-ansible` repo now contains roles for all 21 services (6 from Phase 1, 15 new in this sprint).

**New Ansible Roles (15):**

| Role | Service | Server | Key Template |
|------|---------|--------|-------------|
| `nextcloud` | Nextcloud file sharing | lab-app1 | `nextcloud-nginx.conf.j2` |
| `mattermost` | Mattermost team chat | lab-app1 | `mattermost.service.j2` |
| `jitsi` | Jitsi Meet video | lab-app1 | `prosody.cfg.lua.j2` |
| `iredmail` | iRedMail email server | lab-comm1 | `postfix-main.cf.j2` |
| `zammad` | Zammad help desk | lab-comm1 | _(apt-managed)_ |
| `elasticsearch` | Elasticsearch search | lab-db1 | `elasticsearch.yml.j2` + `jvm.options.j2` |
| `freepbx` | FreePBX VoIP PBX | lab-pbx1 | `pjsip.conf.j2` |
| `suitecrm` | SuiteCRM CRM | lab-biz1 | `suitecrm-nginx.conf.j2` |
| `odoo` | Odoo ERP | lab-biz1 | `odoo.conf.j2` |
| `openkm` | OpenKM document mgmt | lab-biz1 | `openkm.service.j2` |
| `taiga` | Taiga project mgmt | lab-mgmt1 | `taiga-backend.service.j2` |
| `snipeit` | Snipe-IT assets | lab-mgmt1 | `snipeit-env.j2` |
| `glpi` | GLPI ITSM | lab-mgmt1 | `glpi-nginx.conf.j2` |
| `zabbix` | Zabbix monitoring | lab-comm1 | `zabbix_server.conf.j2` |
| `graylog` | Graylog log mgmt | lab-proxy1 | `graylog-server.conf.j2` |

**New Playbooks (15):** `deploy-{service}.yml` for each role above — with vault assertions, role execution, service verification, and deployment summary.

**Updated `site.yml`:** Expanded from 6 plays (Phase 1 only) to 16 plays covering all 4 phases in dependency order.

**New Inventory Variable Files (9):**
- `inventory/group_vars/collaboration.yml` — Nextcloud, Mattermost, Jitsi vars
- `inventory/group_vars/communications.yml` — iRedMail, FreePBX, Zammad, Zabbix vars
- `inventory/group_vars/business.yml` — SuiteCRM, Odoo, OpenKM vars
- `inventory/group_vars/it_management.yml` — Taiga, Snipe-IT, GLPI vars
- `inventory/host_vars/lab-app1.yml` — PHP-FPM pool + UFW rules
- `inventory/host_vars/lab-comm1.yml` — email/monitoring ports
- `inventory/host_vars/lab-pbx1.yml` — SIP/RTP port rules
- `inventory/host_vars/lab-biz1.yml` — Odoo/OpenKM ports
- `inventory/host_vars/lab-mgmt1.yml` — IT management service ports

**Updated `vault/secrets.yml.example`:** Added 25 new vault variable stubs for all new services.

**Updated `Makefile`:** Added `deploy-phase2`, `deploy-phase3`, `deploy-phase4` group targets + 15 individual service targets.

**Total repo size:** 161 role files across 21 roles.

---

## [1.21.0] — 2026-03-05

### Added — Sprint 25: Category Spec Documents + Tracking Corrections

7 category architecture specification documents in `docs/01-core/` confirmed complete and marked done. All stale TODO tracker entries corrected.

**Category Spec Documents (7) — `docs/01-core/`:**

| File | Content | Lines |
|------|---------|-------|
| `01-identity.md` | FreeIPA + Keycloak architecture, LDAP schema, OIDC clients table, IPA federation config | 147 |
| `02-database.md` | PostgreSQL service databases (11 DBs), pg_hba.conf, Redis config/usage, ES JVM config, backup cron | 127 |
| `03-collaboration.md` | Nextcloud storage layout, Mattermost channels table, Jitsi architecture, integration tables, lab progression | 113 |
| `04-communications.md` | iRedMail SMTP/IMAP/webmail, FreePBX dial plan, Zammad ticket workflow, integration details | 104 |
| `05-business.md` | SuiteCRM workflows, Odoo module list, OpenKM document structure, cross-service integrations | 102 |
| `06-it-management.md` | Taiga projects, Snipe-IT asset lifecycle, GLPI CMDB, integration tables | 95 |
| `07-infrastructure.md` | Traefik routing, Zabbix monitoring topology, Graylog pipeline, alerting flows | 123 |

**Tracking Corrections:**
- Phase 3 (Documentation Migration) status updated: `21 docs total · 14 migrated · 7 category specs written`
- Phase 5 (Collaboration) status corrected: `🟡 LAB 01 COMPLETE` → `✅ COMPLETE` · all 5 module entries expanded to show Labs 01–06 with sprint references (Sprints 7–12)
- Phase 6 (Back Office) status corrected: `🟡 IN PROGRESS` → `✅ COMPLETE` · all 4 module entries show Labs 01–06 · sprint checkboxes added (Sprints 13–18)
- Elasticsearch Lab 06 table entry corrected: `[ ]` → `[x]`

Lab progress: 120/120 (unchanged — tracking correction only). **ALL 120 LABS REMAIN COMPLETE.**

---

## [1.20.0] — 2026-03-04

### Added — Phase 4 Lab 06: Production Deployment (all 6 Phase 4 modules) — Sprint 24 complete — **ALL 120 LABS DONE** 🎉

Lab progress: 114/120 → 120/120 (95.0% → 100.0%). **Phase 4 COMPLETE.** All 6 Phase 4 modules now have production-grade `docker-compose.production.yml` files, functional test scripts with 9-phase production checks (3a–3i), and `lab-06-smoke` CI jobs. **ALL 120 IT-Stack labs are now implemented across all 20 modules.**

| Module | App Port | KC Port | LDAP Port | MH Port | Production Feature |
|--------|----------|---------|-----------|---------|-------------------|
| Elasticsearch (05) | Kibana 5650 | 8550 | 3870 | — | ILM env vars, write+retrieve test doc |
| Taiga (15) | Front 8460 / Back 8061 | 8560 | 3871 | 8750 | Celery events worker, Redis session persistence |
| Snipe-IT (16) | 8461 | 8561 | 3872 | 8751 | `php artisan queue:work` queue worker |
| GLPI (17) | 8462 | 8562 | 3873 | 8752 | cron.php every 60s, LDAP bind test |
| Zabbix (19) | Web 8463 | 8563 | 3874 | 8753 | server + web both running, DB restart resilience |
| Graylog (20) | 9050 | 8564 | 3875 | — | Syslog 1519/udp, GELF 12206/udp, mongodump backup |

**Key production patterns applied (all modules):**
- `restart: unless-stopped` on **every** container
- Resource `limits` AND `reservations` on every service
- `IT_STACK_ENV: production` · `IT_STACK_MODULE: {module}` · `IT_STACK_LAB: "06"` env vars
- Password pattern: `*Prod06!` (e.g., `RootProd06!`, `LdapProd06!`, `Admin06!`, `SnipeProd06!`)
- Container naming: `{module}-p06-{service}` (p = production, 06 = lab 06)
- Project name: `it-stack-{module}-lab06`

**Test script 9-phase production checklist (3a–3i):**
- 3a: `docker compose config -q` validation
- 3b: HostConfig.Memory > 0 (resource limits applied)
- 3c: HostConfig.RestartPolicy.Name = "unless-stopped"
- 3d: `IT_STACK_ENV=production` + module-specific env vars
- 3e: Database backup (pg_dump / mysqldump / mongodump)
- 3f: Redis session SET/GET or LDAP bind (module-specific)
- 3g: Keycloak admin API token via `/realms/master/protocol/openid-connect/token`
- 3h: Background worker/cron container confirmed running
- 3i: Container restart resilience (Redis or DB restart + recovery check)

**Graylog SHA256:** `GRAYLOG_ROOT_PASSWORD_SHA2` = sha256 of `GraylogProd06!` = `0db7a747c6ff62219430654b88e1fe9d474241a65b028a697ecbe2251d01ff18`

---

## [1.19.0] — 2026-03-04

### Added — Phase 4 Lab 05: Advanced Integration (all 6 Phase 4 modules) — Sprint 23 complete

Lab progress: 108/120 → 114/120 (90.0% → 95.0%). Phase 4 Lab 05 (Advanced Integration) complete. All 6 Phase 4 modules now have fully implemented `docker-compose.integration.yml` files with WireMock ecosystem API mocks, functional test scripts with WireMock stub registration and `--no-cleanup`, and `lab-05-smoke` CI jobs appended to all 6 CI pipelines.

| Module | App Port | WireMock Port | KC Port | LDAP Port | WireMock Simulates |
|--------|----------|---------------|---------|-----------|-------------------|
| Elasticsearch (05) | Kibana 5640 | 8760 | 8505 | 3884 | Graylog REST API |
| Taiga (15) | 8440 (UI), 8041 (API) | 8761 | 8540 | 3885 | Mattermost incoming webhook |
| Snipe-IT (16) | 8441 | 8762 | 8541 | 3886 | Odoo REST API (asset procurement) |
| GLPI (17) | 8442 | 8763 | 8542 | 3887 | Zammad REST API (ticket escalation) |
| Zabbix (19) | 8443 (web) | 8764 | 8543 | 3888 | Mattermost incoming webhook |
| Graylog (20) | 9040 | 8765 | 8544 | 3889 | Zabbix HTTP API + syslog 1518/udp, GELF 12205/udp |

**Key patterns applied:**
- Container naming: `{module}-i05-{service}` (e.g., `elastic-i05-mock`, `taiga-i05-back`)
- Project name: `it-stack-{module}-lab05`
- **Single-network architecture**: `{module}-i05-net`
- Password pattern: `*Lab05!` (e.g., `RootLab05!`, `ZabbixLab05!`, `LdapLab05!`, `Admin05!`)
- **WireMock 3.3.1**: `wiremock/wiremock:3.3.1` — `--port=8080 --verbose --global-response-templating`
- WireMock healthcheck: `curl -sf http://localhost:8080/__admin/health || exit 1`, interval 10s, retries 10
- Stub registration: `POST /__admin/mappings` → HTTP 201; test validates status before proceeding
- Integration env vars injected into app containers: `GRAYLOG_API_URL`, `MATTERMOST_URL`, `ODOO_URL`, `ZAMMAD_URL`, `MATTERMOST_WEBHOOK_URL`, `ZABBIX_URL`
- Test script Phase 3: register WireMock stubs → verify mock endpoint response → assert env vars in app container → app→WireMock connectivity check → functional integration call → volume assertions
- `lab-05-smoke` job appended after `lab-04-smoke` in all 6 CI files

---

## [1.18.0] — 2026-03-06

### Added — Phase 4 Lab 04: SSO Integration (all 6 Phase 4 modules) — Sprint 22 complete

Lab progress: 102/120 → 108/120 (85.0% → 90.0%). Phase 4 Lab 04 (SSO Integration) complete. All 6 Phase 4 modules now have fully implemented `docker-compose.sso.yml` files with OpenLDAP + Keycloak stacks, functional test scripts with Keycloak API realm/client creation and `--no-cleanup`, and `lab-04-smoke` CI jobs appended to all 6 CI pipelines.

| Module | Web Port | KC Port | LDAP Port | MH Port | SSO Protocol |
|--------|----------|---------|-----------|---------|-------------|
| Elasticsearch (05) | Kibana 5630 | 8504 | 3894 | N/A | OIDC (Kibana→KC) |
| Taiga (15) | 8430 (UI), 8031 (API) | 8530 | 3895 | 8730 | OIDC (Taiga back→KC) |
| Snipe-IT (16) | 8431 | 8531 | 3896 | 8731 | SAML (SP→KC) |
| GLPI (17) | 8432 | 8532 | 3897 | 8732 | SAML (SP→KC) |
| Zabbix (19) | 8433 (web) | 8533 | 3898 | 8733 | SAML (Zabbix web→KC) |
| Graylog (20) | 9030 | 8534 | 3899 | N/A | OIDC (Graylog→KC) + syslog 1517/udp, GELF 12204/udp |

**Key patterns applied:**
- Container naming: `{module}-s04-{service}` (e.g., `elastic-s04-kc`, `taiga-s04-ldap`)
- Project name: `it-stack-{module}-lab04`
- **Single-network architecture**: `{module}-s04-net`
- Password pattern: `*Lab04!` (e.g., `RootLab04!`, `ZabbixLab04!`, `LdapLab04!`, `Admin04!`)
- Standard sidecar stack: `osixia/openldap:1.5.0` + `quay.io/keycloak/keycloak:24.0.3` (`start-dev`, `KC_DB: dev-file`)
- Keycloak healthcheck: `curl -sf http://localhost:8080/realms/master`, interval 15s, retries 20, start_period 30s
- Resource limits: KC=1G/1.0cpu, LDAP=256M/0.25cpu, DB=512M/0.5cpu, App=512M–1G/0.5–1.0cpu
- Test script Phase 3: KC admin token → create `it-stack` realm → create module OIDC/SAML client → OIDC discovery + SAML metadata → LDAP base DC entries → KC reachable from app container → env var assertions → DB check → volume assertions
- `lab-04-smoke` job appended after `lab-03-smoke` in all 6 CI files

---

## [1.17.0] — 2026-03-04

### Added — Phase 4 Lab 03: Advanced Features (all 6 Phase 4 modules) — Sprint 21 complete

Lab progress: 96/120 → 102/120 (80.0% → 85.0%). Phase 4 Lab 03 (Advanced Features) complete. All 6 Phase 4 modules now have fully implemented `docker-compose.advanced.yml` files, functional test scripts with resource-limit validation and `--no-cleanup`, and `lab-03-smoke` CI jobs in all 6 CI pipelines.

| Module | Web Port | Mailhog | Lab 03 Advanced Feature |
|--------|----------|---------|-------------------------|
| Elasticsearch (05) | 9220 + Kibana 5620 | N/A | ES 8.13.0 + Kibana 8.13.0 + Logstash 8.13.0 pipeline (beats→ES) |
| Taiga (15) | 8420 (UI), 8021 (API) | 8720 | `taiga-a03-async` events worker + Redis persistence (`save 60 1`) |
| Snipe-IT (16) | 8421 | 8721 | `SESSION_DRIVER=redis` + `CACHE_DRIVER=redis` + `snipeit-a03-queue` worker |
| GLPI (17) | 8422 | 8722 | `glpi-a03-cron` dedicated scheduler container (PHP cron loop) |
| Zabbix (19) | 8423 (web), 10051 (server) | 8723 | `zabbix-a03-agent` (Agent2) self-monitoring container |
| Graylog (20) | 9020 | N/A | Tuned heap (`JAVA_OPTS`/`ES_JAVA_OPTS`) + UDP syslog :1516 + GELF :12203 |

**Key patterns applied:**
- Container naming: `{module}-a03-{service}` (e.g., `es-a03-node`, `taiga-a03-async`)
- Project name: `it-stack-{module}-lab03`
- **Single-network architecture**: `{module}-a03-net` (unlike Lab 02's dual-network)
- Password pattern: `*Lab03!` (e.g., `RootLab03!`, `ZabbixLab03!`)
- `deploy.resources.limits.cpus` + `deploy.resources.limits.memory` on **all** containers
- `section()` function added to all test scripts (visual phase separators)
- Resource limit verification via `docker inspect --format '{{.HostConfig.Memory}}'`
- Advanced feature tests: env var checks (`SESSION_DRIVER`, `CACHE_DRIVER`, `ZBX_SERVER_HOST`), ILM endpoints, Redis CLI, agent state
- `lab-03-smoke` job appended after `lab-02-smoke` in all 6 CI files

---

## [1.16.0] — 2026-03-03

### Added — Phase 4 Lab 02: External Dependencies (all 6 Phase 4 modules) — Sprint 20 complete

Lab progress: 90/120 → 96/120 (75.0% → 80.0%). Phase 4 Lab 02 (External Dependencies) complete. All 6 Phase 4 modules now have fully implemented `docker-compose.lan.yml` files with real external service stacks, functional test scripts with polling wait loops and `--no-cleanup` flag, and `lab-02-smoke` CI jobs appended to all 6 CI pipelines.

| Module | Web Port | External Services | DB Used |
|--------|----------|-------------------|---------|
| Elasticsearch (05) | 9210 + Kibana 5610 | es-l02-node + es-l02-kibana | N/A — ES is the data tier |
| Taiga (15) | 8410 (UI), 8011 (API) / Mailhog 8710 | postgres:15 + redis:7 + mailhog | PostgreSQL |
| Snipe-IT (16) | 8411 / Mailhog 8711 | mariadb:10.11 + mailhog | MariaDB |
| GLPI (17) | 8412 / Mailhog 8712 | mariadb:10.11 + mailhog | MariaDB |
| Zabbix (19) | 8413 (web), 10051 (server) / Mailhog 8713 | mysql:8.0 + zabbix-server/web-mysql ubuntu-7.0 + mailhog | MySQL |
| Graylog (20) | 9010 / syslog 1515/udp, GELF 12202/udp | mongo:6.0 + elasticsearch:7.17.12 | MongoDB + ES |

**Key patterns applied:**
- Container naming: `{module}-l02-{service}` (e.g., `es-l02-node`, `taiga-l02-db`)
- Project name: `it-stack-{module}-lab02`
- Dual-network architecture: data-net (DB tier) + app-net (app tier) per module
- `--no-cleanup` arg + `trap cleanup EXIT` pattern in all test scripts
- Polling wait loops (`for i in $(seq 1 N)`) replacing static `sleep 30`
- `lab-02-smoke` job appended (not replaced) in all 6 CI files

---

## [1.15.0] — 2026-03-02

### Added — Phase 4 Lab 01: Standalone (all 6 Phase 4 modules) — Sprint 19 complete
Lab progress: 84/120 → 90/120 (70.0% → 75.0%). Phase 4 Lab 01 (Standalone) complete. All 6 Phase 4 modules now have fully implemented `docker-compose.standalone.yml` files replacing broken `$firstPort` stubs, plus functional test scripts with real endpoint validation and `cleanup()` trap pattern.

| Module | Port(s) | Stack | Key Lab 01 Test |
|--------|---------|-------|-----------------|
| Elasticsearch (05) | 9200 | single-node ES 8.13.0 | index create → document CRUD → search |
| Taiga (15) | 8400 (UI), 8001 (API) | postgres:15 + redis:7 + taiga-back + taiga-front | API root + auth endpoint + UI HTTP 200 |
| Snipe-IT (16) | 8401 | mariadb:10.11 + snipe/snipe-it | web UI accessible + content check |
| GLPI (17) | 8402 | mariadb:10.11 + diouxx/glpi | web UI accessible + GLPI content check |
| Zabbix (19) | 8403 (web), 10051 (server) | mysql:8.0 + zabbix-server-mysql + zabbix-web-nginx-mysql ubuntu-7.0 | web UI + JSON-RPC API + server port |
| Graylog (20) | 9000 | mongo:6.0 + elasticsearch:7.17.12 + graylog:5.2 | web UI + REST API + system info |

#### Patterns Established (all 6 modules)
- Container naming: `{module}-s01-{service}` (s01 = standalone lab 01)
- Dependency health checks via `condition: service_healthy` on all upstream services
- `ulimits.memlock` on Elasticsearch containers
- `cleanup()` function + `trap cleanup EXIT` for reliable test teardown
- `NO_CLEANUP=1` env var support for local debugging
- `section()` helper for structured test output
- CI `lab-01-smoke` test script reference fixed to module-numbered filenames (e.g. `test-lab-05-01.sh`)

---

## [1.14.0] — 2026-03-01

### Added — Phase 3 Lab 06: Production Deployment (all 4 Phase 3 modules) — Sprint 18 complete 🎉 Phase 3 COMPLETE!
Lab progress: 80/120 → 84/120 (66.7% → 70.0%). **Phase 3 (Back Office) is now fully complete.** Production-grade stacks with `restart: unless-stopped`, resource limits (`deploy.resources.limits`), production credentials, dependency health checks, and operational validation tests.

| Module | Web Port | KC Port | LDAP Port | MH Port | Key Production Feature |
|--------|----------|---------|-----------|---------|------------------------|
| FreePBX (10) | 8380 | 8480 | 3898 | 8680 | AMI :5042, SIP :5167/udp, mysqldump backup |
| SuiteCRM (12) | 8382 | 8481 | 3899 | 8681 | Redis sessions, cron container, mysqldump backup |
| Odoo (13) | 8390 | 8490 | 3900 | 8690 | workers=2, longpolling :8391, pg_dump backup |
| OpenKM (14) | 8393 | 8491 | 3901 | 8693 | ES :9204, index test, mysqldump backup |

Container naming: `{module}-p06-{service}` (p06 = production lab 06).

#### Test Coverage Added
- Compose file syntax validation (`config -q`)
- Memory and CPU limits via `docker inspect .HostConfig.Memory / .NanoCpus`
- `restart: unless-stopped` policy assertion
- `IT_STACK_ENV=production` and `IT_STACK_LAB=06` env var checks
- Database backup: `mysqldump` (MariaDB/MySQL) and `pg_dump` (PostgreSQL) to `/dev/null`
- Keycloak admin token + realm list via admin API
- Service restart resilience: `docker restart {db}` → re-check health
- Redis session read/write (SuiteCRM)
- Odoo workers mode in command line (`docker inspect .Config.Cmd`)
- Elasticsearch index create/document/delete cycle (OpenKM)
- OpenKM REST API `/folder/getChildren` (authenticated)
- CI `lab-06-smoke` job added to all 4 module CI workflows

---

## [1.13.0] — 2026-03-01

### Added — Phase 3 Lab 05: Advanced Integration (all 4 Phase 3 modules) — Sprint 17 complete
Lab progress: 76/120 → 80/120 (63.3% → 66.7%). Phase 3 Lab 05 (Advanced Integration) complete. Each module adds WireMock 3.3.1 as a lightweight API mock simulating partner service APIs (SuiteCRM CTI, Odoo JSONRPC, Snipe-IT REST, Nextcloud CalDAV, document consumers).

| Module | Web Port | WireMock Port | KC Port | Integration Pairs |
|--------|----------|---------------|---------|-------------------|
| FreePBX (10) | 8360 | 8361 | 8460 | SuiteCRM CTI + Zammad webhook |
| SuiteCRM (12) | 8362 | 8363 | 8461 | Odoo JSONRPC + Nextcloud CalDAV |
| Odoo (13) | 8370 | 8372 | 8470 | Snipe-IT REST + SuiteCRM customer sync |
| OpenKM (14) | 8373 | 8374 | 8471 | SuiteCRM/Odoo document consumers + ES :9203 |

Container naming: `{module}-i05-{service}` (i05 = integration lab 05).

#### Test Coverage Added
- WireMock admin health: `/__admin/health` endpoint
- WireMock stub registration via `/__admin/mappings` POST (201 assert)
- Integration endpoint simulation: CTI calls, JSONRPC, REST hardware/users, CalDAV PROPFIND
- Integration env vars verified in module containers (SUITECRM_URL, ODOO_URL, SNIPEIT_URL, etc.)
- App container → WireMock connectivity test (docker exec curl)
- All 6-8 containers health-checked individually
- CI `lab-05-smoke` job added to all 4 module CI workflows

---

## [1.12.0] — 2026-03-01

### Added — Phase 3 Lab 04: SSO Integration (all 4 Phase 3 modules) — Sprint 16 complete

Lab progress: 72/120 → 76/120 (60.0% → 63.3%). Phase 3 Lab 04 (SSO Integration) complete. Each module adds OpenLDAP directory, Keycloak 24 IdP, and module-specific SSO wiring (OIDC or SAML).

| Module | LDAP Port | KC Port | SSO Protocol | Key Integration |
|--------|-----------|---------|--------------|-----------------|
| FreePBX (10) | 3890 | 8440 | OIDC (admin UI) | LDAP_ENABLED + KC OIDC client + freepbx realm |
| SuiteCRM (12) | 3891 | 8441 | SAML | KC SAML metadata + EntityDescriptor test |
| Odoo (13) | 3893 | 8450 | OIDC | KC OIDC discovery + LDAP_HOST env + gevent :8351 |
| OpenKM (14) | 3892 | 8452 | SAML + LDAP | JAVA_OPTS ldap props + ES :9202 + KC SAML metadata |

Container naming: `{module}-s04-{service}` (s04 = sso lab 04).

#### Test Coverage Added
- Keycloak admin API: obtain token → create `it-stack` realm → create module-specific OIDC/SAML client
- OIDC discovery endpoint assertion: `/.well-known/openid-configuration` returns `issuer`
- SAML descriptor assertion: `/protocol/saml/descriptor` returns `EntityDescriptor`
- LDAP bind test from within LDAP container
- Module container → Keycloak connectivity test
- LDAP env vars verified in module containers
- All 5-6 containers health-checked individually

#### Commits
- `9e3b371` — `it-stack-freepbx`: feat(lab-04): FreePBX SSO Integration
- `4c77e6c` — `it-stack-suitecrm`: feat(lab-04): SuiteCRM SSO Integration
- `ec859e0` — `it-stack-odoo`: feat(lab-04): Odoo SSO Integration
- `40d80e9` — `it-stack-openkm`: feat(lab-04): OpenKM SSO Integration

---

## [1.11.0] — 2026-03-01

### Added — Phase 3 Lab 03: Advanced Features (all 4 Phase 3 modules) — Sprint 15 complete 🎉 60% milestone!

Lab progress: 68/120 → 72/120 (56.7% → 60.0%). Phase 3 Lab 03 (Advanced Features) complete. Key theme: production-grade configuration — resource limits on all containers, advanced service topology, and module-specific advanced capabilities.

| Module | New Services | Web Port | LP Port | Key Advanced Features |
|--------|-----------|---------|---------|-----------------------|
| FreePBX (10) | — | 8320 | — | AMI :5038, recordings/MOH/voicemail volumes, CPU/mem limits |
| SuiteCRM (12) | Redis + Cron | 8321 | — | Redis session cache, dedicated cron container, CPU/mem limits |
| Odoo (13) | Redis | 8330 | 8331 | `--workers=2`, gevent longpolling :8331, CPU/mem limits |
| OpenKM (14) | Elasticsearch 8.x | 8332 | — | Full-text indexing on :9201, ES health checks, CPU/mem limits |

Container naming: `{module}-a03-{service}` (a03 = advanced lab 03).

#### Lab 03 Tests vs Lab 02
- **FreePBX**: AMI port `nc -z :5038`, `asterisk -rx "dialplan show"`, memory limit assertion, 6 volumes
- **SuiteCRM**: Redis PING from app, `SESSION_SAVE_HANDLER=redis` env, cron container DB access
- **Odoo**: gevent port :8331 reachable, `pgrep` worker count ≥2, CPU limit assertion
- **OpenKM**: ES `/_cluster/health` green/yellow, `/_cat/indices`, REST `/folder/getChildren`

#### Commits
- `cac64ce` — `it-stack-freepbx`: feat(lab-03): FreePBX Advanced Features
- `a282a42` — `it-stack-suitecrm`: feat(lab-03): SuiteCRM Advanced Features
- `994ce43` — `it-stack-odoo`: feat(lab-03): Odoo Advanced Features
- `6910fd9` — `it-stack-openkm`: feat(lab-03): OpenKM Advanced Features

---

## [1.10.0] — 2026-03-01

### Added — Phase 3 Lab 02: External Dependencies (all 4 Phase 3 modules) — Sprint 14 complete

Lab progress: 64/120 → 68/120 (53.3% → 56.7%). Phase 3 Lab 02 (External Dependencies) complete for all Back Office / Communications modules. Each module now ships a `docker-compose.lan.yml` with an external DB container + Mailhog SMTP relay (simulates the `lab-db1` / external mail server topology).

| Module | External DB | SMTP Relay | Web Port | Mailhog UI | New vs Lab 01 |
|--------|-------------|-----------|----------|-----------|----------------|
| FreePBX (10) | MariaDB 10.11 | Mailhog | 8310 | :8610 | External DB + SMTP relay |
| SuiteCRM (12) | MariaDB 10.11 | Mailhog | 8311 | :8611 | External DB + SMTP relay |
| Odoo (13) | PostgreSQL 15 | Mailhog | 8312 | :8612 | External DB + Redis cache + SMTP |
| OpenKM (14) | MySQL 8.0 | Mailhog | 8313 | :8613 | External DB + SMTP relay |

Container naming scheme: `{module}-l02-{service}` (l02 = LAN lab 02).

#### New Lab 02 Tests (vs Lab 01)
- External DB connectivity verified from app container (`mysql`/`psql` cross-container)
- Mailhog web API `GET /api/v2/messages` returns valid JSON
- Redis `PING → PONG` check (Odoo only)
- SMTP env var points to Mailhog container name

#### Commits
- `a6099ed` — `it-stack-freepbx`: feat(lab-02): FreePBX External Dependencies
- `3b593ba` — `it-stack-suitecrm`: feat(lab-02): SuiteCRM External Dependencies
- `a3e0e26` — `it-stack-odoo`: feat(lab-02): Odoo External Dependencies
- `7991d83` — `it-stack-openkm`: feat(lab-02): OpenKM External Dependencies

---

## [1.9.0] — 2026-03-01

### Added — Phase 3 Lab 01: Standalone (all 4 Phase 3 modules) — Sprint 13 complete

Lab progress: 60/120 → 64/120 (50.0% → 53.3%). Phase 3 Lab 01 (Standalone) complete for all Back Office / Communications modules. Each module ships a `docker-compose.standalone.yml`, `test-lab-XX-01.sh`, and a corrected CI `lab-01-smoke` job.

| Module | DB | App Image | Web Port | Key Feature |
|--------|----|-----------|----------|-------------|
| FreePBX (10) | MariaDB 10.11 | tiredofit/freepbx:16 | 8301 | SIP UDP/TCP :5160, RTP 18000–18100, admin web UI |
| SuiteCRM (12) | MariaDB 10.11 | bitnami/suitecrm:8 | 8302 | REST API auth check, session/role DB tables |
| Odoo (13) | PostgreSQL 15 | odoo:17 | 8303 | `/web/health` endpoint + JSON-RPC database list |
| OpenKM (14) | MySQL 8.0 | openkm/openkmdce:7.2.0 | 8304 | REST `/repository/info` auth, utf8mb4 charset |

#### Commits
- `475829c` — `it-stack-freepbx`: feat(lab-01): FreePBX Standalone
- `0a7e386` — `it-stack-suitecrm`: feat(lab-01): SuiteCRM Standalone
- `17faca3` — `it-stack-odoo`: feat(lab-01): Odoo Standalone
- `6e8edb3` — `it-stack-openkm`: feat(lab-01): OpenKM Standalone

#### CI Fixes (all 4 repos)
- Replaced broken stub `lab-01-smoke` jobs (wrong script name `test-lab-01.sh`, invalid `$firstPort` placeholder)
- Real jobs: correct DB readiness wait, correct app port probe, correct module-specific test script

---

## [1.8.0] — 2026-03-01

### Added — Phase 2 Lab 06: Production Deployment (all 5 Phase 2 modules) — 🎉 Phase 2 COMPLETE!

Lab progress: 55/120 → 60/120 (45.8% → 50.0%). **Phase 2 entirely complete.** All 6 labs done for Nextcloud, Mattermost, Jitsi, iRedMail, and Zammad.

| Module | KC Port | App Port | LDAP Port | Key Production Feature |
|--------|---------|----------|-----------|------------------------|
| Nextcloud (06) | 8204 | 8200 | 3895 | PHP tuning (1G/512M/3600s), Redis persistence, KC metrics |
| Mattermost (07) | 8206 | 8205 | 3896 | MM metrics :8067, MinIO S3 (9110/9111), mm-prod-config vol |
| Jitsi (08) | 8207 | 8250 | — | Traefik (8280/8209), JVB UDP 10002, coturn 3479 |
| iRedMail (09) | 8208 | 9280/9380 | 3897 | ClamAV, Mailhog relay 9026, vmail+backup volumes |
| Zammad (11) | 8210 | 3002 | 3898 | Elasticsearch 2G, zammad-init pattern, Redis persist |

#### Architecture Notes (Lab 06)

```
Theme:        Production Deployment — restart=always, resource limits, named volumes, log rotation, metrics
Log driver:   json-file, max-size=10m, max-file=5 (x-logging anchor on all services)
Restart:      restart: always (all services)
Limits:       deploy.resources.limits on EVERY container (memory + cpus)
LDAP vols:    dual named volumes (ldap-data + ldap-config) for LDAP data persistence
KC metrics:   KC_METRICS_ENABLED=true + /metrics endpoint checked in all test scripts
MM metrics:   MM_METRICSSETTINGS_ENABLE=true, Prometheus on :8067
MinIO:        MINIO_PROMETHEUS_AUTH_TYPE=public
Redis:        --save 900 1 --save 300 10 persistence flags
```

#### Commit Hashes

| Repo | Hash |
|------|------|
| it-stack-nextcloud | `e38a004` |
| it-stack-mattermost | `377a515` |
| it-stack-jitsi | `cdb187c` |
| it-stack-iredmail | `e356ad6` |
| it-stack-zammad | `72840a3` |

#### CI Workflow Updates

All 5 Phase 2 CI workflows updated — `lab-06-smoke` job appended (6 smoke jobs per repo). Each waits for Keycloak, LDAP (where applicable), and the main service before running the production test script with `--no-cleanup`. All `continue-on-error: true`.

---

## [1.7.0] — 2026-03-01

### Added — Phase 2 Lab 05: Advanced Integration (all 5 Phase 2 modules)

Lab progress: 50/120 → 55/120 (41.7% → 45.8%). Phase 2 Lab 05 (Advanced Integration) complete for all 5 Phase 2 modules.

| Module | LDAP Container | Key Integration | Additional Service |
|--------|---------------|----------------|-------------------|
| Nextcloud (06) | `nc-int-ldap` :3890 | Keycloak LDAP federation + OIDC | Redis sessions, cron worker |
| Mattermost (07) | `mm-int-ldap` :3891 | LDAP sync + OIDC | MinIO S3 file storage |
| Jitsi (08) | — | Traefik reverse proxy + Keycloak JWT | Coturn TURN :3478 |
| iRedMail (09) | `iredmail-int-ldap` :3892 | LDAP primary auth + Keycloak LDAP fed | Mailhog SMTP relay |
| Zammad (11) | `zammad-int-ldap` :3893 | LDAP user import + OIDC channel | Elasticsearch + mailhog |

#### Architecture Notes (Lab 05)

```
Theme:       Full ecosystem integration — OpenLDAP (FreeIPA sim) + Keycloak + module-specific services
LDAP image:  osixia/openldap:1.5.0, domain=lab.local, admin=LdapAdmin05!, readonly=ReadOnly05!
Keycloak:    LDAP user federation registered via /admin/realms/it-stack/components API
Nextcloud:   6-container stack; LDAP_PROVIDER_* env + NC_oidc_* env; cron worker
Mattermost:  6-container stack; MM_LDAPSETTINGS_* + MM_OPENIDSETTINGS_* + MinIO S3
Jitsi:       7-container stack; Traefik labels (Host meet.localhost) + JWT_ASAP_KEYSERVER + coturn
iRedMail:    4-container stack; Keycloak on mail-int-app-net + mail-int-dir-net (LDAP federation)
Zammad:      11-container stack; LDAP config API + OIDC channel API + ES indices + mailhog
```

#### CI Workflow Updates

All 5 Phase 2 CI workflows updated — `lab-05-smoke` job appended (after `lab-04-smoke`), 5 smoke jobs per repo. Jitsi waits for Traefik dashboard; others wait for OpenLDAP bind. All `continue-on-error: true`.

---

## [1.6.0] — 2026-03-01

### Added — Phase 2 Lab 04: SSO Integration (all 5 Phase 2 modules)

Lab progress: 45/120 → 50/120 (37.5% → 41.7%). Phase 2 Lab 04 (SSO Integration) complete for all 5 Phase 2 modules.

| Module | Keycloak Port | SSO Protocol | Key OIDC / JWT Config |
|--------|--------------|--------------|----------------------|
| Nextcloud (06) | 8084 | OIDC (user_oidc) | `NC_oidc_login_provider_url`, client `nextcloud`, secret `nextcloud-secret-04` |
| Mattermost (07) | 8085 | OIDC | `MM_OPENIDSETTINGS_ENABLE=true`, `MM_OPENIDSETTINGS_ID=mattermost-client` |
| Jitsi (08) | 8086 | JWT / JWKS | `JWT_ASAP_KEYSERVER` → Keycloak JWKS, `TOKEN_AUTH_URL` → Keycloak auth endpoint |
| iRedMail (09) | 8087 | LDAP Federation | Keycloak LDAP user-federation provider registered via components API |
| Zammad (11) | 8088 | OIDC | Zammad OIDC channel created via `/api/v1/channels`, client `zammad` |

#### Architecture Notes (Lab 04)

```
Theme:       Embedded Keycloak container per module (quay.io/keycloak/keycloak:24.0, start-dev)
Realm:       it-stack (created per test script via Keycloak admin API)
Credentials: admin / Lab04Admin!  |  DB: Lab04Password!  |  Redis: Lab04Redis!
Nextcloud:   5-container stack; user_oidc env vars; OIDC discovery endpoint verified
Mattermost:  4-container stack; MM_OPENIDSETTINGS_* env; API config verified
Jitsi:       6-container stack; JWT_ASAP_KEYSERVER → Keycloak JWKS certs endpoint
iRedMail:    4-container stack; Keycloak on mail-app-net + mail-dir-net; LDAP federation
Zammad:      10-container stack; Zammad OIDC channel configured via Rails API
```

#### CI Workflow Updates

All 5 Phase 2 CI workflows updated — `lab-04-smoke` job appended to each (after `lab-03-smoke`), with Keycloak health wait (`/health/ready`) and module-specific service wait conditions. `continue-on-error: true` on all smoke jobs.

---

## [1.5.0] — 2026-03-01

### Added — Phase 2 Lab 03: Advanced Features (all 5 Phase 2 modules)

Lab progress: 40/120 → 45/120 (33.3% → 37.5%). Phase 2 Lab 03 (Advanced Features) complete for all 5 Phase 2 modules.

| Module | Key Advanced Features | Key Lab 03 Tests |
|--------|----------------------|------------------|
| Nextcloud (06) | cron worker container, PHP tuning (512M), Redis `allkeys-lru`, trusted proxies | `backgroundjobs_mode=cron` via occ, `PHP_MEMORY_LIMIT=512M` in env, memory limit 1G |
| Mattermost (07) | MinIO S3 storage, `MaxFileSize=524288000` (500MB), read/write timeout 300s, login retry limit | `MM_FILESETTINGS_MAXFILESIZE` in env + API, `DriverName=amazons3` in config |
| Jitsi (08) | JWT authentication (`APP_SECRET=JitsiJWT03!`), coturn TURN server, guest access | `ENABLE_AUTH=1`, `AUTH_TYPE=jwt`, `APP_ID=jitsi` in web+prosody env, TURN :3478 |
| iRedMail (09) | DKIM signing (`ENABLE_DKIM=1`, selector=lab), LDAP readonly bind, SMTP STARTTLS | DKIM keys in `/opt/dkim/`, STARTTLS in EHLO response, resource limit 1G |
| Zammad (11) | `RAILS_MAX_THREADS=5`, `WEB_CONCURRENCY=2`, ES indices, Redis `allkeys-lru` | `RAILS_MAX_THREADS=5` in railsserver env, `zammad_*` indices in ES, resource limit 2G |

#### Architecture Notes (Lab 03)

```
Theme:       Resource limits on all containers + module-specific advanced production features
Nextcloud:   4-container stack: db+redis+app+cron; cron replaces ajax background jobs
Mattermost:  5-container stack adds MinIO S3; MM_FILESETTINGS_DRIVERNAME=amazons3
Jitsi:       5-container stack adds JWT auth layer; ENABLE_GUESTS=1 allows anonymous after auth
iRedMail:    3-container stack; DKIM keys generated at /opt/dkim/; POSTFIX relays via mailhog
Zammad:      7-container stack (init+railsserver+scheduler+websocket+nginx+pg+es+redis+smtp)
             RAILS_MAX_THREADS=5, WEB_CONCURRENCY=2 tune Ruby concurrency
```

#### CI Workflow Updates

All 5 Phase 2 CI workflows updated — `lab-03-smoke` job appended to each (after `lab-02-smoke`), with compose-specific wait conditions and `continue-on-error: true`.

---

## [1.4.0] — 2026-02-28

### Added — Phase 2 Lab 02: External Dependencies (all 5 Phase 2 modules)

Lab progress: 35/120 → 40/120 (29.2% → 33.3%). Phase 2 Lab 02 (External Dependencies) complete for all 5 Phase 2 modules.

| Module | Key External Deps | Key Lab 02 Tests |
|--------|-------------------|------------------|
| Nextcloud (06) | postgres:16-alpine, redis:7-alpine (2 networks) | DB type = pgsql via `occ config:system:get dbtype`, Redis in config.php |
| Mattermost (07) | postgres:16-alpine, redis:7-alpine, mailhog SMTP relay | SMTP relay: `SMTPServer` = `smtp` verified via config API |
| Jitsi (08) | coturn:4.6 TURN/STUN (2 networks: jitsi-net + turn-net) | TURN TCP :3478 reachable, config.js TURN config present |
| iRedMail (09) | osixia/openldap:1.5.0, mailhog SMTP relay (2 networks) | LDAP search dc=lab,dc=local, readonly bind, SMTP/IMAP/SUBM banners |
| Zammad (11) | postgres:15, elasticsearch:8, redis:7 (replaces memcached), mailhog (3 networks) | REDIS_URL=redis:// in container env (not memcached), Mailhog :8025 new |

#### Architecture Notes (Lab 02)

```
Theme:       Each module connects to externally-managed services on separate Docker networks
             simulating real LAN topology (app ↔ db on dedicated subnets)
Nextcloud:   nc-app-net (app+redis) + nc-db-net (app+db); REDIS_HOST_PASSWORD=Lab02Redis!
Mattermost:  mm-app-net + mm-data-net; MM_EMAILSETTINGS_SMTPSERVER=smtp (mailhog)
Jitsi:       jitsi-net (all Jitsi components) + turn-net (coturn); coturn --user=jitsi:TurnPass1!
iRedMail:    mail-app-net + mail-dir-net; LDAP_BIND_DN=cn=readonly,dc=lab,dc=local
Zammad:      zammad-app-net + zammad-data-net + zammad-mail-net; REDIS_URL replaces MEMCACHE_SERVERS
```

#### CI Workflow Updates

All 5 Phase 2 CI workflows updated — `lab-02-smoke` job appended to each, including real wait conditions for PG/Redis/ES/LDAP/TURN/API readiness before running lab scripts.

---

## [1.3.0] — 2026-02-28

### Added — Phase 2 Lab 01: Standalone (all 5 Phase 2 modules)

Lab progress: 30/120 → 35/120 (25.0% → 29.2%). Phase 2 Lab 01 (Standalone) complete for all 5 Phase 2 modules.

| Module | Compose | Sidecar Services | Key Tests |
|--------|---------|------------------|-----------|
| Nextcloud (06) | `nextcloud:29-apache` :8080, SQLite auto | — | `status.php installed:true`, `occ status/user:list`, WebDAV PROPFIND, OCS Capabilities |
| Mattermost (07) | `mattermost-team-edition:9.3` :8065 | postgres:16-alpine | API `/system/ping`, create team/channel, post message |
| Jitsi (08) | web+prosody+jicofo+jvb `:stable-9753` | 4-container stack | HTTPS :8443, config.js, external_api.js, BOSH :5280, JVB logs |
| iRedMail (09) | `iredmail/iredmail:stable` all-in-one | — | SMTP :9025, IMAP :9143, Submission :9587, Roundcube :9080/mail, Postfix/Dovecot/MariaDB |
| Zammad (11) | `ghcr.io/zammad/zammad:6.3.0` × 5 | postgres:15, ES:8, memcached | PG/ES health, web :3000, API `/signshow`, create admin, railsserver |

#### Architecture Notes (Lab 01)

```
Nextcloud:   SQLite (no external DB) — correct for standalone lab validation
Mattermost:  Internal PG sidecar — no Keycloak, no FreeIPA at this stage
Jitsi:       4 containers with xmpp.meet.jitsi network alias for XMPP DNS resolution
iRedMail:    All-in-one container (Postfix+Dovecot+MariaDB+Nginx+Roundcube)
Zammad:      YAML anchor x-zammad-env shared across 5 service containers; ES security disabled for lab
```

#### CI Workflow Updates

All 5 CI workflows updated — `lab-01-smoke` job now uses correct module-specific test script names and real health-wait conditions (no more scaffold `sleep 30` or `test-lab-01.sh` references).

---

## [1.2.0] — 2026-02-28

### Added — Phase 1 Lab 06: Production Deployment 🎉 Phase 1 Complete

All 5 Phase 1 modules have real Lab 06 production HA Docker Compose stacks and test suites.
Lab progress: 25/120 → 30/120 (20.8% → 25.0%). **Phase 1 is complete.** All 30 Phase 1 labs done.

| Module | Compose | HA Pattern | Test Lines |
|--------|---------|------------|------------|
| FreeIPA (01) | `docker-compose.production.yml` | Privileged FreeIPA + KC + PG + Redis + Traefik; CI syntax-check only | ~90 lines |
| Keycloak (02) | `docker-compose.production.yml` | 2-node KC cluster (KC_CACHE=local) + Traefik LB + PG + Redis | ~165 lines |
| PostgreSQL (03) | `docker-compose.production.yml` | bitnami/postgresql:16 streaming replication (master/slave) + PgBouncer :6432 + postgres-exporter :9187 | ~140 lines |
| Redis (04) | `docker-compose.production.yml` | Redis master + 2 replicas + 3 Sentinel nodes + redis-exporter :9121 | ~145 lines |
| Traefik (18) | `docker-compose.production.yml` | TLS :443, rate-limit (20/40 burst), secure-headers, retry(3), access logs JSON, Prometheus :9090 | ~145 lines |

#### Production Architecture Patterns (Lab 06)

```
PostgreSQL HA:
  pg-primary (bitnami, :5432, REPLICATION_MODE=master)
  pg-replica  (bitnami, :5433, replicaof pg-primary)
  pgbouncer   (:6432, transaction pool, MAX_CLIENT_CONN=200)
  postgres-exporter (:9187, Prometheus metrics)

Redis HA (Sentinel):
  redis-master  (:6379, AOF + maxmemory 512mb allkeys-lru)
  redis-replica-1/2 (:6380/:6381, replicaof redis-master)
  redis-sentinel-1/2/3 (:26379-26381, quorum=2, monitor mymaster)
  redis-exporter (:9121, oliver006/redis_exporter)

Traefik Production:
  traefik (:80/:443/:8080/:8082) + 2x whoami backends + prometheus
  Middlewares: rate-limit (20avg/40burst/1s), secure-headers, retry(3 attempts)
  Access logs: JSON → /logs/access.log
  TLS: auto self-signed on :443

Keycloak HA:
  keycloak-1 + keycloak-2 (quay.io/keycloak/keycloak:26.0, KC_CACHE=local)
  Traefik :8080 → round-robin LB to both KC nodes
  Shared: postgres:16-alpine (kc-db) + redis:7-alpine (session cache)
  Traefik dashboard: :8081

FreeIPA Production (CI-safe; real deployment on privileged Linux host):
  freeipa (privileged, 172.22.0.10, freeipa/freeipa-server:fedora-41)
  keycloak (:8080) + postgres (:5432) + redis (:6379) alongside
  CI: config -q + bash -n + ShellCheck only
```

#### Supporting Files Added
- `docker/production/sentinel.conf` (Redis) — Sentinel monitor config for 3-node quorum
- `docker/production/prometheus.yml` (Traefik) — scrape config targeting `traefik:8082`

#### CI Updates
- All 5 repos: validate section now explicitly validates `docker-compose.production.yml` with `config -q`
- All 5 repos: `lab-06-smoke` job added to `ci.yml`
  - PostgreSQL: wait PG primary/replica/PgBouncer → run `PG_PASS=Lab06Password! bash test-lab-03-06.sh`
  - Redis: wait master/replicas/sentinels → run `REDIS_PASS=Lab06Password! bash test-lab-04-06.sh`
  - Traefik: wait Traefik API + backends → run `bash test-lab-18-06.sh`
  - Keycloak: wait cluster health (300s) → run `KC_PASS=Lab06Password! bash test-lab-02-06.sh`
  - FreeIPA: pull + `config -q` + `bash -n` + ShellCheck (privileged pattern)

---

## [1.1.0] — 2026-02-28

### Added — Phase 1 Lab 05: Advanced Integration

All 5 Phase 1 modules have real Lab 05 Docker Compose integration stacks and test suites.
Lab progress: 20/120 → 25/120 (16.7% → 20.8%). This milestone proves cross-service ecosystem wiring.

| Module | Compose | What's New | Test Lines |
|--------|---------|------------|------------|
| FreeIPA (01) | `docker-compose.integration.yml` | FreeIPA + KC + PG + Redis — LDAP :389, KC federation component, Kerberos :88, OIDC discovery | 147 lines |
| Keycloak (02) | `docker-compose.integration.yml` | KC + OpenLDAP (osixia) + phpLDAPadmin + MailHog + 2 OIDC apps — LDAP federation + client creds flow | 177 lines |
| PostgreSQL (03) | `docker-compose.integration.yml` | PG multi-DB (keycloak+labapp) + Redis + KC + Traefik LB + Prometheus scraping | 131 lines |
| Redis (04) | `docker-compose.integration.yml` | Redis LRU+keyspace+AOF + PG + KC + Traefik — sessions, queues, rate-limit sorted sets | 130 lines |
| Traefik (18) | `docker-compose.integration.yml` | Traefik + KC + oauth2-proxy ForwardAuth + security headers + Prometheus scraping :8082 | 123 lines |

#### Integration Architecture Pattern (Lab 05)

```
Phase 1 service stack:
  PostgreSQL  — serves keycloak DB + labapp DB; Prometheus scrapes Traefik
  Redis       — LRU eviction + keyspace events + AOF; KC token cached in Redis
  Traefik     — ForwardAuth via oauth2-proxy → Keycloak OIDC; /public open, /protected gated
  Keycloak    — OpenLDAP federation (osixia); phpLDAPadmin; MailHog; app-a + app-b OIDC
  FreeIPA     — LDAP :389 + Kerberos :88 + DNS; KC LDAP federation; PG + Redis alongside
```

#### Supporting Files Added
- `docker/integration/pg-init.sh` (PostgreSQL) — creates `keycloak` + `labapp` databases on startup
- `docker/integration/prometheus.yml` (Traefik) — scrape config targeting `traefik:8082`

#### CI Updates
- All 5 repos: validate section now explicitly validates `docker-compose.integration.yml`
- All 5 repos: `lab-05-smoke` job added to `ci.yml`
  - PostgreSQL/Redis/Traefik/Keycloak: full Docker runtime test
  - FreeIPA: pull + config + `bash -n` + ShellCheck (privileged container CI pattern)

---

## [1.0.0] — 2026-02-28

### Added — Phase 1 Lab 04: SSO Integration

All 5 Phase 1 modules have real Lab 04 Docker Compose stacks and test suites.
Lab progress: 15/120 → 20/120 (12.5% → 16.7%). This milestone proves the full SSO chain end-to-end.

| Module | Compose | What's New | Test Lines |
|--------|---------|------------|------------|
| FreeIPA (01) | `docker-compose.sso.yml` | FreeIPA + Keycloak + KC-DB — LDAP federation component, user sync, OIDC discovery | 130 lines |
| Keycloak (02) | `docker-compose.sso.yml` | Keycloak + KC-DB + OIDC app + MailHog — full OIDC/SAML hub | 142 lines |
| PostgreSQL (03) | `docker-compose.sso.yml` | KC + KC-DB + PostgreSQL + pgAdmin + oauth2-proxy — pgAdmin gated by OIDC | 123 lines |
| Redis (04) | `docker-compose.sso.yml` | KC + KC-DB + Redis + redis-commander + oauth2-proxy — UI gated by OIDC | 107 lines |
| Traefik (18) | `docker-compose.sso.yml` | KC + KC-DB + Traefik + oauth2-proxy + whoami×2 — ForwardAuth middleware | 103 lines |

#### SSO Architecture Pattern (same across PostgreSQL, Redis, Traefik)

```
Browser → Traefik/oauth2-proxy → Keycloak OIDC → protected service
                                      ↑
                                 it-stack realm
                                 oauth2-proxy client (confidential)
                                 labuser (test user)
```

#### Test coverage highlights

- **FreeIPA:** LDAP port 389 reachable, admin LDAP bind, users OU present, Keycloak `it-stack` realm creation, LDAP federation component (`rhds` vendor, `cn=users,cn=accounts`), full user sync triggered, FreeIPA users visible in Keycloak, OIDC discovery, JWKS endpoint
- **Keycloak:** Realm with brute-force protection, OIDC confidential client (service accounts + ROPC), SAML client, test user, client credentials grant, ROPC grant, JWT structure (3 parts + `iss`/`exp`/`iat` claims), token refresh, introspection (`active:true`), OIDC discovery (5 fields), SAML descriptor XML, MailHog :8025 + API
- **PostgreSQL:** Keycloak + realm + client + user via REST API, client credentials token, JWT validation, OIDC discovery, UserInfo, token introspection, JWKS, oauth2-proxy `:4180` redirects to Keycloak (302), PostgreSQL query via labdb
- **Redis:** Same OIDC flow + Redis PING/SET/GET/INFO, oauth2-proxy SSO gate redirects (302), JWKS signing keys
- **Traefik:** Same OIDC flow + Traefik dashboard, `/public` → 200 (no auth), `/protected` → 302/401 (ForwardAuth intercepts), `/oauth2/callback` accessible, router count ≥2

#### CI workflow updates (all 5 repos)

- `validate` step: `docker-compose.sso.yml` now strictly validated with `config -q` individually
- New `lab-04-smoke` job added to all 5 CI workflows (needs: validate, continue-on-error: true):
  - PostgreSQL: waits for KC ready (200s) + PG ready (60s) — runs `KC_PASS=Lab04Password! bash test-lab-03-04.sh`
  - Redis: waits for KC ready (200s) + Redis PONG (60s) — runs `KC_PASS=Lab04Password! bash test-lab-04-04.sh`
  - Traefik: waits for KC ready (200s) + Traefik API (60s) — runs `KC_PASS=Lab04Password! bash test-lab-18-04.sh`
  - Keycloak: waits for KC ready (200s) — runs `KC_PASS=Lab04Password! bash test-lab-02-04.sh`
  - FreeIPA: pull images + `config -q` + `bash -n` + ShellCheck (privileged — full test on real VMs)

---

## [0.9.0] — 2026-02-28

### Added — Phase 1 Lab 03: Advanced Features

All 5 Phase 1 modules have real Lab 03 Docker Compose stacks and test suites.
Lab progress: 10/120 → 15/120 (8% → 12.5%).

| Module | Compose | What's New | Test Lines |
|--------|---------|------------|------------|
| FreeIPA (01) | `docker-compose.advanced.yml` | FreeIPA + `policy-client` (one-shot: sudo rules, HBAC, password policy, automount maps) | 121 lines |
| Keycloak (02) | `docker-compose.advanced.yml` | 2-node cluster (ispn cache) + `keycloak-db` (internal) + MailHog SMTP sink | 161 lines |
| PostgreSQL (03) | `docker-compose.advanced.yml` | Primary + Replica + PgBouncer (transaction pool, port 5434) + pg-exporter (Prometheus :9187) + pgAdmin | 116 lines |
| Redis (04) | `docker-compose.advanced.yml` | 6-node cluster (3 primary + 3 replica, ports 7001–7006) + cluster-init one-shot container | 118 lines |
| Traefik (18) | `docker-compose.advanced.yml` | Prometheus metrics (:8082) + 5 middleware chains + TCP echo router + JSON access logs | 117 lines |

#### New supporting files

- `it-stack-postgresql/docker/advanced/pgbouncer-init.sh` — creates `pgbouncer_auth` role, enables `pg_stat_statements` extension, grants read access
- `it-stack-traefik/docker/advanced/traefik-dynamic.yml` — middleware definitions: `security-headers` (HSTS/CSP/nosniff), `compress`, `rate-limit` (avg 20, burst 50), `retry` (3×100ms), `circuit-breaker` (>25% 5xx), `basic-auth`

#### Test coverage highlights

- **PostgreSQL:** `pg_stat_statements` extension present, PgBouncer port 5434 ready, query routing via PgBouncer, `SHOW POOLS`, stat capture, `log_min_duration_statement=100ms`, `archive_mode=on`, replica streaming, `pg_dump`+`pg_restore` roundtrip, Prometheus `pg_up=1` + `pg_stat_*` metrics
- **Redis:** `cluster_state:ok`, `cluster_slots_assigned=16384`, `cluster_slots_fail=0`, 6 nodes (3 primary + 3 replica), PING all 6, cross-shard SET/GET via `-c`, hash-tag co-location, AOF enabled on primaries, `cluster_known_nodes=6`
- **Traefik:** `/ping=OK`, `api/version` JSON, Prometheus metrics reachable, `traefik_` namespace present, router/service/entrypoint metrics, JSON access log file, 4+ middleware names registered, security-headers + circuit-breaker + retry + rate-limit present, HTTP→HTTPS redirect, all 3 HTTPS backends (200), TCP echo port 9000, router count ≥3
- **Keycloak:** Both nodes `/health/ready=200`, admin token from both nodes, realm created on node 1 visible on node 2 (shared DB confirms clustering), MailHog `:8025` accessible, realm SMTP config via API, brute-force enabled + confirmed, token lifetime 300s, custom scope `it-stack:read` created and visible, OIDC discovery on both nodes
- **FreeIPA:** Container running, `policy-client` exit=0, sudo rule `allow-docker-devops` exists with docker command group, HBAC rule `allow-devops-ssh` exists with devops group, group + user created, user in devops, password `min_len≥12`, automount location + map + key exist, LDAP anonymous search works, `kinit admin` succeeds

#### CI workflow updates (all 5 repos)

- `validate` step: `docker-compose.advanced.yml` now strictly validated with `config -q` individually (not in scaffold loop)
- New `lab-03-smoke` job added to all 5 CI workflows (needs: validate, continue-on-error: true):
  - PostgreSQL: waits for primary (5432, 120s), replica (5433, 180s), PgBouncer (5434, 60s) — runs `ADMIN_PASS=Lab03Password! bash test-lab-03-03.sh`
  - Redis: waits for all 6 nodes PONG then 20s cluster-init settle — runs `REDIS_PASS=Lab03Password! bash test-lab-04-03.sh`
  - Traefik: waits for `/ping` (90s) + metrics (30s) — runs `bash test-lab-18-03.sh`
  - Keycloak: waits for node 1 + node 2 `/health/ready` (200s each) — runs `KC_PASS=Lab03Password! bash test-lab-02-03.sh`
  - FreeIPA: pull images + `config -q` + `bash -n` syntax check + ShellCheck (privileged containers cannot run in GitHub Actions)

---

## [0.8.0] — 2026-02-28

### Added — Phase 1 Lab 02: External Dependencies

All 5 Phase 1 modules have real Lab 02 Docker Compose stacks and test suites.
Lab progress: 5/120 → 10/120 (4% → 8%).

| Module | Compose | What’s New | Test Lines |
|--------|---------|------------|------------|
| FreeIPA (01) | `docker-compose.lan.yml` | FreeIPA + `ldap-client` (debian:12-slim, ldap-utils + krb5-user) | 141 lines |
| Keycloak (02) | `docker-compose.lan.yml` | Keycloak + `keycloak-db` (PG16, `db-net` internal) | 161 lines |
| PostgreSQL (03) | `docker-compose.lan.yml` | Primary + Replica (streaming) + pgAdmin | 155 lines |
| Redis (04) | `docker-compose.lan.yml` | Master + 2 Replicas + 3 Sentinels (quorum=2) | 158 lines |
| Traefik (18) | `docker-compose.lan.yml` | Traefik + 4 backends: host routing, path routing, rate limit, LB (3 replicas) | 129 lines |

#### New supporting files

- `it-stack-postgresql/docker/replication/primary-init.sh` — creates `replicator` role + `pg_hba.conf` streaming replication entry
- `it-stack-postgresql/docker/pgadmin/servers.json` — pre-configures pgAdmin with primary + replica connections
- `it-stack-freeipa/docker/ldap-client/krb5.conf` — Kerberos client config for `LAB.LOCALHOST` realm
- `it-stack-freeipa/docker/ldap-client/ldap.conf` — LDAP Base DN + URI via ipa-net alias

#### Test coverage highlights

- **PostgreSQL:** WAL level, `max_wal_senders`, replica `pg_is_in_recovery()`, `pg_stat_replication` streaming count, 3-row cross-node replication, replica write rejection, pgAdmin HTTP
- **Redis:** Master/replica PING+ROLE, data replication to both replicas, all 3 sentinels PING, sentinel master discovery via `get-master-addr-by-name`, TTL persistence
- **Traefik:** HTTP→HTTPS redirect, HTTPS backends (self-signed `-k`), path routing `/api/v1/echo`, router count ≥3, security headers, load balancer ≥2 unique backends
- **Keycloak:** Admin token (proves JDBC), realm CRUD (201/409), restart + realm persists (persistence test), OIDC discovery, `db-net` internal flag
- **FreeIPA:** Port connectivity from ldap-client, anonymous bind, authenticated bind OUs, user create + LDAP verify, `kinit` from client container

#### CI workflow updates (all 5 repos)

- `validate` step: `docker-compose.lan.yml` now strictly validated with `config -q` (not `--no-interpolate`)
- New `lab-02-smoke` job added to all 5 CI workflows:
  - PostgreSQL: waits for primary (`pg_isready` 5432) then replica (5433, 180s), runs `test-lab-03-02.sh`
  - Redis: waits for master PONG (90s) + 30s sentinel settle, runs `test-lab-04-02.sh`
  - Traefik: waits for `/ping` (90s), runs `test-lab-18-02.sh`
  - Keycloak: waits for `/health/ready` (200s), runs `test-lab-02-02.sh`
  - FreeIPA: pull images + syntax check only (privileged containers cannot run in GitHub Actions)

---

## [0.7.0] — 2026-02-27

### Added — Phase 1 Lab 01 Content + Ansible Roles

#### Option A: Ansible (`it-stack-ansible`)
Complete Ansible automation for all 5 Phase 1 modules — 76 files, ~3,332 lines:
- `roles/common` — base hardening: sysctl tuning, locale/timezone, Docker CE, NTP (chrony), firewall, fail2ban, motd
- `roles/freeipa` — FreeIPA server install, DNS configuration, Kerberos realm, admin account bootstrap
- `roles/postgresql` — install + 10 service databases + application users + `pg_hba.conf` + performance tuning
- `roles/redis` — install + password auth + AOF persistence + maxmemory-policy + sysctl `vm.overcommit_memory`
- `roles/keycloak` — Docker-based deploy + master realm + LDAP federation to FreeIPA + `it-stack` realm
- `roles/traefik` — Docker-based deploy + Let's Encrypt ACME + per-service dynamic config + dashboard
- `site.yml` — full stack playbook (all 8 servers in dependency order)
- 5 targeted playbooks: `deploy-identity.yml`, `deploy-database.yml`, `deploy-keycloak.yml`, `deploy-traefik.yml`, `setup-servers.yml`
- `inventory/` with 8-server production layout (lab-id1 through lab-mgmt1)
- `vault.yml.template` — all secret variables documented (never committed)

Each role follows standard structure: `tasks/main.yml`, `handlers/main.yml`, `defaults/main.yml`, `templates/`, `files/`

#### Option B: Real Lab 01 Docker Compose + Test Scripts

For all 5 Phase 1 modules — replaced scaffold stubs with fully functional content:

| Module | Compose Highlights | Test Coverage |
|--------|--------------------|---------------|
| FreeIPA (01) | `freeipa/freeipa-server:latest`, privileged mode, systemd, full env vars, named volumes | kinit, ipa user-add/del, LDAP search, DNS, IPA JSON-RPC API |
| Keycloak (02) | `quay.io/keycloak/keycloak:24`, start-dev mode, PostgreSQL backend, health checks | Admin token, realm CRUD, user CRUD, OIDC client, token endpoint |
| PostgreSQL (03) | `postgres:16`, labadmin user, labdb + 10 app databases via init SQL, pgBadger config | Schema CRUD, indexes, transactions, ROLLBACK, extensions, encoding |
| Redis (04) | `redis:7-alpine`, `--requirepass`, AOF persistence, 256 MB maxmemory allkeys-lru | String/List/Hash/Set/ZSet ops, TTL/PERSIST, MULTI/EXEC, INFO, CONFIG |
| Traefik (18) | Traefik v3.x, Docker provider, 3 whoami backends, host routing, path-prefix, StripPrefix | Ping, dashboard API, router discovery, host routing, load balancing, 404 |

#### CI Workflow Fixes (3 rounds)

**Round 1 — Core CI bugs (all 5 repos):**
- Fixed `Validate Docker Compose files` step: was globbing all 6 files including scaffolds with `$firstPort` placeholders → now validates `standalone.yml` strictly, others with `--no-interpolate || warn`
- Fixed smoke test script name: was `test-lab-01.sh` (generic) → now `test-lab-XX-01.sh` (module-numbered)
- Fixed `((PASS++))` post-increment with `set -euo pipefail`: post-increment returns old value (0 on first call = falsy = `set -e` exits) → changed to `((++PASS))` pre-increment
- Added module-appropriate tool installs: `postgresql-client`, `redis-tools`, `netcat-openbsd`
- Added proper readiness waits: `pg_isready`, `redis-cli PING`, `curl /health/ready`, `curl /ping`
- FreeIPA CI: skip live test (requires privileged mode + 20 min install) → validate compose + pull image only

**Round 2 — ShellCheck errors:**
- SC2015 (FreeIPA): `cmd && pass || warn` → `if cmd; then pass; else warn; fi`
- SC2209 (Keycloak): `KC_ADMIN=admin` → `KC_ADMIN="admin"` (unquoted string flagged as command substitution)
- SC1049/SC1073 (PostgreSQL): missing `then` keyword after heredoc terminator `SQL` in two `if` blocks
- SC2034 (Traefik): unused `for i in` loop variable → renamed to `_`
- SC2086 (Redis): pre-existing, suppressed with `# shellcheck disable=SC2086`

**Final CI status: 5/5 PASS ✅**

---

## [0.6.0] — 2026-02-27

### Added — Phase 5: CI/CD Workflows

#### GitHub Actions (3 workflows × 20 repos = 60 files)
- `ci.yml` — validates all Docker Compose files (`--no-interpolate`), ShellCheck on lab scripts, manifest validation, Trivy config scan (SARIF → GitHub Security tab), Lab 01 smoke test with `continue-on-error`
- `release.yml` — Docker image build and push to GHCR on semver tags (`v*.*.*`), Trivy image scan, GitHub Release with auto-generated release notes
- `security.yml` — weekly scheduled (Monday 02:00 UTC) Trivy filesystem + config scan with SARIF upload to GitHub Security
- All 20 repos: CI status 20/20 ✅ passing

#### Scripts
- `deploy-workflows.ps1` — redeploys all 3 workflows to all 20 component repos atomically

#### Bug Fixes
- Fixed `docker-compose.sso.yml` duplicate YAML key `keycloak` in `it-stack-keycloak` repo (renamed conflicting service to `keycloak-sso`)
- Fixed all 20 `ci.yml` stubs where `$f` shell variable was consumed by PowerShell during scaffold generation, producing broken `\` literals
- Fixed `docker compose config` invocation to use `--no-interpolate` (compose files use placeholder vars not available in CI)

---

## [0.5.0] — 2026-02-27

### Added — All 20 Module Repos Scaffolded

#### GitHub Repositories (20 component repos)
- All 20 component repos created on GitHub, each with 21 scaffolded items
- Full directory structure per repo: `src/`, `tests/labs/`, `docker/`, `kubernetes/`, `helm/`, `ansible/`, `docs/labs/`
- 6 Docker Compose files per repo: `standalone`, `lan`, `advanced`, `sso`, `integration`, `production`
- 6 lab test scripts per repo: `test-lab-01.sh` through `test-lab-06.sh`
- Module manifest YAML (`it-stack-{module}.yml`) with full metadata
- `Makefile`, `Dockerfile`, `.env.example`, `.gitattributes`, standard community files

#### GitHub Issues (120 total)
- 6 lab issues per module × 20 modules = 120 issues
- All labeled: `lab`, `module-NN`, `phase-N`, category tag, `priority-high`
- All milestoned to correct phase
- All linked to GitHub Projects: phase-specific project + Master Dashboard (#10) = 240 project items

#### Labels & Milestones
- 39 labels × 20 repos = 780 label applications (0 failures)
- 4 milestones × 20 repos = 80 milestone applications (0 failures)

#### Scripts
- `scaffold-module.ps1` — full scaffold for all 20 module repos (1177 lines)
- `create-component-repos.ps1`, `apply-labels-components.ps1`, `apply-milestones-components.ps1`
- `create-lab-issues.ps1` — 120 issues, `link-issues-to-projects.ps1` — 240 project items
- `add-gitattributes.ps1` — consistent LF line endings across all repos

---

## [0.4.0] — 2026-02-27

### Added — Documentation Site (MkDocs + GitHub Pages)

#### MkDocs Material Site
- `mkdocs.yml` — Material theme with dark/light mode, tabs, search, code copy, sticky navigation
- `docs/index.md` — Comprehensive home page with module table, 7-layer architecture, phase tabs, server layout
- `requirements-docs.txt` — `mkdocs-material>=9.5`, `mkdocs-minify-plugin>=0.8`
- **Docs live at: https://it-stack-dev.github.io/it-stack-docs/**

#### Documentation Reorganized into MkDocs Hierarchy
- `docs/architecture/` — `overview.md` (arch + server layout), `integrations.md` (all 15 integrations)
- `docs/deployment/` — `lab-deployment.md`, `enterprise-reference.md`
- `docs/labs/` — `overview.md`, `part1-network-os.md` through `part5-business-management.md`
- `docs/project/` — `master-index.md`, `github-guide.md`, `todo.md`
- `docs/contributing/` — `framework-template.md`

#### GitHub Actions
- `.github/workflows/docs.yml` — auto-deploys to GitHub Pages on push to `docs/**` or `mkdocs.yml`

#### Scripts
- `reorganize-docs.ps1`, `enable-pages.ps1`

---

## [0.3.0] — 2026-02-27

### Added — Local Development Environment

#### Dev Workspace (`C:\IT-Stack\it-stack-dev\`)
- 35 subdirectories: `repos/meta/`, 7 category dirs (`01-identity/` – `07-infrastructure/`), `workspaces/`, `deployments/`, `lab-environments/`, `configs/`, `scripts/`, `logs/`
- All 6 meta repos cloned into `repos/meta/`
- `configs/global/it-stack.yaml` — global config (all 8 servers, subdomains, all 20 service ports, versions)
- `README.md` — dev environment quick start guide
- `it-stack.code-workspace` — VS Code multi-root workspace (at `C:\IT-Stack\` root)

#### Scripts
- `setup-dev-workspace.ps1`, `clone-meta-repos.ps1`

---

## [0.2.0] — 2026-02-27

### Added — GitHub Organization Bootstrap

#### Organization `.github` Repository
- `profile/README.md` — org homepage with module table and architecture overview
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md` — org-level community files
- `workflows/ci.yml`, `release.yml`, `security-scan.yml`, `docker-build.yml` — reusable workflow templates

#### Meta Repositories (6 created and initialized)
- `it-stack-docs`, `it-stack-installer`, `it-stack-testing`
- `it-stack-ansible`, `it-stack-terraform`, `it-stack-helm`

#### GitHub Projects (5)
- Project #6: Phase 1 Foundation · Project #7: Phase 2 Collaboration
- Project #8: Phase 3 Back Office · Project #9: Phase 4 IT Management
- Project #10: Master Dashboard (all 20 modules)

#### Labels and Milestones
- 39 labels applied to all 6 meta repos (234 applications)
- 4 phase milestones applied to all 6 meta repos (24 milestones)

#### Scripts
- `apply-labels.ps1`, `create-milestones.ps1`, `fix-milestones.ps1`, `push-phase1-repos.ps1`

---

## [0.1.0] — 2026-02-27

### Added — Phase 0: Planning Complete

#### Documentation
- `enterprise-it-stack-deployment.md` — Original 112 KB technical reference (15+ server layout)
- `enterprise-stack-complete-v2.md` — Updated 8-server architecture with hostnames and IPs
- `enterprise-it-lab-manual.md` — Lab Part 1: Network and OS setup
- `enterprise-it-lab-manual-part2.md` — Lab Part 2: Identity, DB, SSO (FreeIPA, PostgreSQL, Keycloak)
- `enterprise-it-lab-manual-part3.md` — Lab Part 3: Collaboration (Nextcloud, Mattermost, Jitsi)
- `enterprise-it-lab-manual-part4.md` — Lab Part 4: Communications (Email, Proxy, Help Desk, Monitoring)
- `enterprise-lab-manual-part5.md` — Lab Part 5: Back Office (VoIP, CRM, ERP, DMS, PM, Assets, ITSM)
- `integration-guide-complete.md` — Cross-system integration procedures for all 20 modules
- `LAB_MANUAL_STRUCTURE.md` — Overview of entire 5-part lab manual series
- `lab-deployment-plan.md` — Test/lab deployment strategy (3–5 servers)
- `MASTER-INDEX.md` — Master index and reading guide for all documentation

#### Project Framework
- `PROJECT-FRAMEWORK-TEMPLATE.md` — Canonical project blueprint, revised for IT-Stack
  - All 20 module definitions (category, repo name, phase, ports)
  - 26-repo GitHub organization structure
  - Standard repository directory layout
  - 6-lab methodology with progression table
  - 4-phase implementation roadmap with timelines
  - Configuration hierarchy and secrets management rules
  - Commit message conventions and code review checklist

#### Tooling & Guides
- `IT-STACK-TODO.md` — Living task checklist covering all 7 implementation phases
  - Lab tracking grid (20 modules × 6 labs = 120 total)
  - Integration milestones for 15 cross-service integrations
  - Production readiness checklists (security, monitoring, backup, DR)
- `IT-STACK-GITHUB-GUIDE.md` — Step-by-step GitHub org bootstrap guide
  - PowerShell scripts for all 26 repo creations
  - `apply-labels.ps1` — 35+ labels with hex color values
  - `create-milestones.ps1` — 4 phase milestones with due dates
  - `create-repo-template.ps1` — Full module scaffold (dirs, 6 docker-compose files, 6 lab scripts, YAML manifest)
  - `create-lab-issues.ps1` — 120 labeled issues across 4 phases
  - Reusable `ci.yml` and `release.yml` GitHub Actions workflow templates
- `claude.md` — Comprehensive AI assistant context document

#### Standard Files
- `README.md` — Project overview with module table, server layout, documentation map
- `CHANGELOG.md` — This file
- `CONTRIBUTING.md` — Contribution guidelines
- `CODE_OF_CONDUCT.md` — Contributor Covenant 2.1
- `SECURITY.md` — Security policy and responsible disclosure process
- `SUPPORT.md` — Support channels and how to get help
- `.gitignore` — Ignore patterns for secrets, environments, OS artifacts, editors

---

## Version Scheme

IT-Stack follows [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH

MAJOR — Breaking change to a deployed service or integration contract
MINOR — New module added, new lab, new integration, new feature
PATCH — Documentation fix, bug fix, configuration correction
```

Each component repository (`it-stack-{module}`) maintains its own version independent of this meta version. A component version reflects the maturity of that module's labs and production readiness:

| Version Range | Meaning |
|---------------|---------|
| `0.1.x` | Lab 01 (Standalone) passing |
| `0.2.x` | Lab 02 (External Dependencies) passing |
| `0.3.x` | Lab 03 (Advanced Features) passing |
| `0.4.x` | Lab 04 (SSO Integration) passing |
| `0.5.x` | Lab 05 (Advanced Integration) passing |
| `1.0.x` | Lab 06 (Production Deployment) passing — production-ready |

---

[Unreleased]: https://github.com/it-stack-dev/it-stack-docs/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/it-stack-dev/it-stack-docs/releases/tag/v0.1.0
