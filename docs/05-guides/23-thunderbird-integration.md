---
doc: 23
title: "Thunderbird Email Client — IT-Stack Integration Guide"
category: guides
date: 2026-03-11
modules: [01-freeipa, 02-keycloak, 06-nextcloud, 09-iredmail]
---

# Thunderbird Email Client Integration
### Connect Mozilla Thunderbird to Every IT-Stack Communication & Collaboration Service

> **Role of Thunderbird in IT-Stack:** Thunderbird is the **primary and only email client** for IT-Stack deployments. It integrates natively with **docker-mailserver** (IMAP/SMTP), Nextcloud (calendar + contacts via CalDAV/CardDAV), FreeIPA (LDAP global address book), and Keycloak (OAuth2 modern authentication). This makes Thunderbird the unified desktop interface for all communication, scheduling, and contact management in the stack. **The mail server is already running** — no extra deployment needed.

---

## Integration Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                 THUNDERBIRD INTEGRATION MAP                          │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                    THUNDERBIRD CLIENT                         │   │
│  │                                                              │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │   │
│  │  │  Email   │  │ Calendar │  │ Contacts │  │  Chat    │   │   │
│  │  │ (IMAP/   │  │(CalDAV)  │  │(CardDAV/ │  │(XMPP -  │   │   │
│  │  │  SMTP)   │  │          │  │  LDAP)   │  │optional) │   │   │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │   │
│  └───────┼─────────────┼─────────────┼──────────────┼─────────┘   │
│          │             │             │              │               │
│          ▼             ▼             ▼              ▼               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │ iRedMail │  │Nextcloud │  │Nextcloud │  │ FreeIPA  │          │
│  │ Module 09│  │ Calendar │  │ Contacts │  │  LDAP    │          │
│  │ port 993 │  │ Module 06│  │ Module 06│  │ Module 01│          │
│  │ port 587 │  │ CalDAV   │  │ CardDAV  │  │ port 389 │          │
│  └────┬─────┘  └──────────┘  └──────────┘  └──────────┘          │
│       │                                                             │
│       ▼  Auth via                                                   │
│  ┌──────────┐                                                       │
│  │ Keycloak │  OAuth2 / Modern Authentication for SMTP/IMAP        │
│  │ Module 02│  (production) — replaces password-based auth         │
│  └──────────┘                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

### Integration Summary

| Integration | Protocol | Module | Port | Complexity |
|-------------|----------|--------|------|------------|
| Send & receive email | IMAP / SMTP | docker-mailserver | **143, 587** | ⭐ Basic ✅ Running |
| Calendar sync | CalDAV (TbSync) | Nextcloud (06) | 443/8280 | ⭐ Basic |
| Contacts sync | CardDAV (TbSync) | Nextcloud (06) | 443/8280 | ⭐ Basic |
| Global address book | LDAP | FreeIPA (01) | 389/636 | ⭐ Basic |
| Modern auth (OAuth2) | OAuth2 via Keycloak | Keycloak (02) | 8443 | ⭐⭐ Moderate |
| Email certificate (S/MIME) | X.509 via FreeIPA CA | FreeIPA (01) | 443 | ⭐⭐⭐ Advanced |
| Mattermost notifications | RSS feed | Mattermost (07) | 8065 | ⭐ Basic |

---

## Prerequisites

Before configuring Thunderbird, the following services must be running:

**Required (Core email):**
- ✅ iRedMail deployed and DNS configured (Module 09) — or MailHog for lab-only testing
- ✅ User account exists in FreeIPA (Module 01)

**Required (Full integration):**
- ✅ Nextcloud running and user account created (Module 06)
- ✅ FreeIPA LDAP accessible on port 389 (Module 01)

**Optional (Production hardening):**
- ✅ Keycloak configured with `iredmail` realm client (Module 02)
- ✅ FreeIPA CA certificate downloaded

**Software:**
- Thunderbird **128 ESR** or later (LTS recommended for enterprise)
- Add-on: **TbSync** (calendar + contacts sync) — install from Thunderbird Add-ons
- Add-on: **Provider for CalDAV & CardDAV** (TbSync provider) — install from Thunderbird Add-ons

---

## Lab Environment vs Production

| Setting | Lab (Azure VM Demo) | Production (8-server) |
|---------|--------------------|-----------------------|
| Email server | **docker-mailserver** (`mail-demo`) — ✅ already running | iRedMail on `lab-comm1` |
| Email protocol | **IMAP port 143 / SMTP port 587 (no SSL)** | IMAP port 993 / SMTP port 587 (STARTTLS) |
| Mail domain | `itstack.local` | `yourcompany.com` |
| Service notifications | MailHog port 8025 (catch-all, no IMAP) | Routed through iRedMail |
| Webmail | Nextcloud Mail at port 8280 → ✉ icon | Nextcloud `https://cloud.yourcompany.com` |
| Calendar/Contacts | Nextcloud port 8280 | Nextcloud `https://cloud.yourcompany.com` |
| LDAP | FreeIPA port 389 | FreeIPA `ldap://lab-id1` |
| OAuth2 | Not required in lab | Keycloak `https://sso.yourcompany.com` |

---

## Part 1: Email (IMAP + SMTP) via docker-mailserver

> **Status: ✅ Already running.** The `mail-demo` container is deployed and ready. Skip to section 1.2 to configure Thunderbird.

### 1.1 Server Settings

**Lab — docker-mailserver (`mail-demo`) — ALREADY RUNNING:**

| Setting | Value |
|---------|-------|
| IMAP server | `4.154.17.25` |
| IMAP port | **`143`** (plaintext — lab mode) |
| IMAP security | **None** (no SSL) |
| SMTP server | `4.154.17.25` |
| SMTP port | **`587`** |
| SMTP security | **None** (no SSL) |
| SMTP authentication | Normal password |
| Username | Full email address e.g. `jdoe@itstack.local` |
| Password | See accounts table below |

**Pre-created accounts:**

| Email | Password | Messages |
|-------|----------|----------|
| `admin@itstack.local` | `Lab01Password!` | 5 pre-loaded |
| `jdoe@itstack.local` | `LabUser01!` | 2 pre-loaded |
| `jsmith@itstack.local` | `LabUser01!` | 0 |

> ⚠️ **Lab note:** Security is set to **None** (plaintext). This is intentional for the lab. Production uses SSL/TLS on IMAP port 993 and STARTTLS on SMTP port 587 (iRedMail on `lab-comm1`).

**Production (iRedMail on `lab-comm1`):**

| Setting | Value |
|---------|-------|
| IMAP server | `mail.yourcompany.com` |
| IMAP port | `993` (IMAPS/SSL) |
| SMTP server | `mail.yourcompany.com` |
| SMTP port | `587` (STARTTLS) |
| Username | `jdoe@yourcompany.com` |

### 1.2 Configure Thunderbird

1. Open Thunderbird → **Edit → Account Settings → Account Actions → Add Mail Account**
2. Enter:
   - **Your name:** John Doe
   - **Email address:** `jdoe@itstack.local`
   - **Password:** *(your iRedMail password)*
3. Click **Configure manually** (do not use auto-detect in lab)
4. Fill in:
   ```
   Incoming  IMAP  4.154.17.25  143  None  Normal password
   Outgoing  SMTP  4.154.17.25  587  None  Normal password
   Username: jdoe@itstack.local  (full email address)
   ```
5. Click **Re-test** → should show green checkmarks
6. Click **Done**

> If Thunderbird warns about unencrypted connection — click **"I understand the risks"** or **"Confirm"** to proceed. This is expected in the lab.

### 1.3 Add More Email Accounts (Lab)

All three accounts are pre-created. To add new accounts:

```bash
# SSH to VM
ssh itstack@4.154.17.25

# Create new account in docker-mailserver
docker exec mail-demo setup email add newuser@itstack.local 'Password123!'

# Verify
docker exec mail-demo setup email list
```

### 1.4 Test Email Delivery

Send a test email **between accounts** using swaks inside the container:

```bash
ssh itstack@4.154.17.25

# Send from admin → jdoe via SMTP (port 587)
docker exec mail-demo swaks \
  --to jdoe@itstack.local \
  --from admin@itstack.local \
  --server localhost \
  --port 587 \
  --auth LOGIN \
  --auth-user admin@itstack.local \
  --auth-password 'Lab01Password!' \
  --header 'Subject: Test from admin' \
  --body 'Docker-mailserver is working!'
```

**Verify in Thunderbird:** IMAP port 143 → jdoe inbox → new message appears  
**Verify in Nextcloud Mail:** http://4.154.17.25:8280 → ✉ icon → jdoe inbox

> **MailHog** (port 8025) captures **service notification emails** from Nextcloud/Mattermost/etc. — not the same inbox as docker-mailserver. They are separate email surfaces.

---

## Part 2: Calendar Sync (CalDAV) via Nextcloud

Thunderbird's built-in Calendar plus the **TbSync** add-on syncs with Nextcloud Calendar over CalDAV.

### 2.1 Install Required Add-ons

In Thunderbird: **Tools → Add-ons and Themes** → search and install:

1. **TbSync** — synchronization framework
2. **Provider for CalDAV & CardDAV** — enables CalDAV/CardDAV in TbSync

Restart Thunderbird after both are installed.

### 2.2 Configure CalDAV Sync

1. In Thunderbird: **Tools → TbSync → Account Actions → Add New Account → CalDAV & CardDAV**
2. Select **Manual configuration**
3. Enter:
   ```
   Account name:    IT-Stack Nextcloud
   CalDAV server:   http://4.154.17.25:8280/remote.php/dav/
   CardDAV server:  http://4.154.17.25:8280/remote.php/dav/
   Username:        admin
   Password:        Lab02Password!
   ```
4. Click **Next** → TbSync discovers all calendars and address books
5. Tick which calendars to sync → **Save & Close**

### 2.3 Nextcloud CalDAV URLs

| Resource | URL Pattern |
|----------|-------------|
| Personal calendar | `http://HOST:8280/remote.php/dav/calendars/USERNAME/personal/` |
| IT-Stack calendar | `http://HOST:8280/remote.php/dav/calendars/USERNAME/it-stack/` |
| All calendars (discovery) | `http://HOST:8280/remote.php/dav/` |

### 2.4 Test Calendar Sync

1. In Nextcloud: **http://4.154.17.25:8280** → Calendar → Create event: `IT-Stack Meeting` (tomorrow, 10am)
2. In Thunderbird: Calendar tab → wait up to 30 seconds (or right-click calendar → Properties → Sync now)
3. Event should appear in Thunderbird Calendar

---

## Part 3: Contact Sync (CardDAV) via Nextcloud

### 3.1 Configure CardDAV (same TbSync account as CalDAV)

When you set up TbSync in Part 2, it discovers CardDAV address books automatically from the same server. In the TbSync account:

1. Click the **Address Books** tab
2. Enable **Personal** address book → set sync direction: **Two-way**
3. Optionally enable **Shared contacts** if your org shares a contact book in Nextcloud

### 3.2 Nextcloud CardDAV URLs

| Resource | URL |
|----------|-----|
| Personal contacts | `http://HOST:8280/remote.php/dav/addressbooks/users/USERNAME/contacts/` |
| Shared contacts | `http://HOST:8280/remote.php/dav/addressbooks/system/system-contacts/` |

### 3.3 Test Contact Sync

1. In Nextcloud: **Contacts** → New contact: `Jane Smith`, email: `jsmith@itstack.local`, phone: `+1-555-0100`
2. In Thunderbird: **Address Book** → right-click the synced address book → **Synchronize**
3. `Jane Smith` should appear — autocomplete works in new emails

---

## Part 4: Global Address Book (LDAP) via FreeIPA

LDAP lets Thunderbird look up **all users in the organization** for email autocomplete. It reads directly from FreeIPA's LDAP directory — no sync required, always live.

### 4.1 Configure LDAP Directory

In Thunderbird: **Tools → Account Settings → Composition & Addressing → (check) Use a different LDAP server → Edit Directories → Add**

Enter:

| Field | Lab Value | Production Value |
|-------|-----------|-----------------|
| Name | IT-Stack Directory | IT-Stack Directory |
| Hostname | `4.154.17.25` | `lab-id1.yourcompany.com` |
| Port | `389` | `636` (LDAPS) |
| Base DN | `cn=users,cn=accounts,dc=lab,dc=localhost` | `cn=users,cn=accounts,dc=DOMAIN,dc=COM` |
| Bind DN | `uid=admin,cn=users,cn=accounts,dc=lab,dc=localhost` | `uid=svc-thunderbird,cn=users,...` |
| Bind password | `Lab01Password!` | *(service account password)* |
| Search scope | **Subtree** | Subtree |
| Login filter | `(uid=%u)` | `(uid=%u)` |

> **Production note:** Create a dedicated FreeIPA service account `svc-thunderbird` with read-only access to the user subtree. Never use `admin` credentials in Thunderbird config.

### 4.2 Test LDAP Autocomplete

1. Compose a new email → start typing `jdo` in the **To:** field
2. Thunderbird queries the LDAP directory and suggests `jdoe@itstack.local (John Doe)`
3. Press **Enter** to select

### 4.3 Verify LDAP is Reachable

```bash
# From Windows terminal (with ldap tools) or WSL:
ldapsearch -x -H ldap://4.154.17.25:389 \
  -D "uid=admin,cn=users,cn=accounts,dc=lab,dc=localhost" \
  -w Lab01Password! \
  -b "cn=users,cn=accounts,dc=lab,dc=localhost" \
  "(objectClass=person)" uid mail displayName | head -40

# Expected output: returns all FreeIPA users with uid, mail, displayName
```

---

## Part 5: OAuth2 Modern Authentication via Keycloak (Production)

In production, replace password-based IMAP/SMTP auth with OAuth2 tokens via Keycloak. This eliminates password storage in Thunderbird and enables SSO — users log in once.

### 5.1 Create Keycloak Client for iRedMail

In Keycloak admin (http://4.154.17.25:8180 → `it-stack` realm):

1. **Clients → Create client**
   - Client type: `OpenID Connect`
   - Client ID: `thunderbird-iredmail`
   - Name: `Thunderbird / iRedMail OAuth`
   - Click **Next**
2. **Capability config:**
   - Client authentication: **OFF** (public client — Thunderbird cannot keep secrets)
   - Standard flow: **ON**
   - Direct access grants: **ON**
   - Click **Next**
3. **Login settings:**
   - Valid redirect URIs: `http://localhost/*` (Thunderbird uses local redirect)
   - Web origins: `http://localhost`
   - Save

4. **Scopes → Add client scope:** add `email`, `profile`, `openid`

### 5.2 Configure iRedMail for OAuth2

Edit iRedMail's Dovecot config to accept OAuth2 tokens from Keycloak:

```bash
# On iRedMail server
sudo nano /etc/dovecot/dovecot.conf
```

Add:

```ini
# OAuth2 authentication via Keycloak
auth_mechanisms = plain login oauthbearer xoauth2

passdb {
  driver = oauth2
  mechanisms = xoauth2 oauthbearer
  args = /etc/dovecot/dovecot-oauth2.conf.ext
}
```

Create `/etc/dovecot/dovecot-oauth2.conf.ext`:

```ini
introspection_mode = local
introspection_url = https://sso.yourcompany.com/realms/it-stack/protocol/openid-connect/userinfo

# Token validation
username_attribute = email
active_attribute = email
active_value =

# Keycloak public key for token verification
local_validation_key_dict = file:/etc/dovecot/oidc-keys/%d
```

### 5.3 Configure Thunderbird OAuth2

In Thunderbird account settings → **Server Settings** → **Authentication method**:

| Field | Value |
|-------|-------|
| Authentication | `OAuth2` |
| Issuer | `https://sso.yourcompany.com/` |
| Client ID | `thunderbird-iredmail` |

When Thunderbird connects: it opens a browser window → Keycloak login → token issued → IMAP/SMTP auth succeeds with token (no password stored in Thunderbird).

---

## Part 6: S/MIME Email Signing via FreeIPA CA (Advanced)

Use FreeIPA's built-in Certificate Authority to issue personal email certificates. Thunderbird uses these to digitally sign and/or encrypt emails.

### 6.1 Issue S/MIME Certificate from FreeIPA

```bash
# On FreeIPA server or client with ipa-client installed
kinit admin

# Request certificate for user jdoe
ipa cert-request \
  --principal jdoe@LAB.LOCALHOST \
  --certificate-out jdoe.pem \
  jdoe.csr  # (generated in next step)

# Generate key + CSR for user
openssl req -new -newkey rsa:4096 -keyout jdoe.key -out jdoe.csr \
  -subj "/CN=John Doe/emailAddress=jdoe@itstack.local"

# After cert-request, convert to PKCS#12 for Thunderbird import
openssl pkcs12 -export \
  -in jdoe.pem \
  -inkey jdoe.key \
  -out jdoe-smime.p12 \
  -name "John Doe S/MIME" \
  -passout pass:YourPassphrase
```

### 6.2 Import Certificate into Thunderbird

1. **Tools → Account Settings → jdoe@itstack.local → End-To-End Encryption**
2. Under **S/MIME** → click **Manage S/MIME Certificates → Import**
3. Select `jdoe-smime.p12` → enter passphrase
4. Under **Personal certificate for digital signing:** select the imported cert
5. Check **Digitally sign messages (by default)**

### 6.3 Trust the FreeIPA CA

```bash
# Download FreeIPA CA certificate
curl -k https://4.154.17.25:8180/ipa/config/ca.crt -o ipa-ca.crt
```

In Thunderbird: **Tools → Options → Privacy & Security → Certificates → Manage Certificates → Authorities → Import `ipa-ca.crt`**

Check: **Trust this CA to identify email users**

Now all emails signed with FreeIPA-issued certs show as **trusted** in Thunderbird.

---

## Part 7: Mattermost Notifications via RSS

Thunderbird can subscribe to Mattermost's permalinks and channel RSS feeds, surfacing team activity in the mail client.

### 7.1 Subscribe to Mattermost RSS

In Mattermost: **Account Settings → Notifications → Enable Email Notifications**

Set notification email to your iRedMail address: `jdoe@itstack.local`

All Mattermost notifications arrive as emails in your Thunderbird inbox.

### 7.2 Subscribe to Zammad Ticket RSS

Zammad generates RSS feeds for ticket queues:

In Thunderbird: **File → New → Feed Account** → Subscribe

```
Feed URL: http://4.154.17.25:8380/api/v1/tickets.rss?token=YOUR_TOKEN
Name: IT-Stack Helpdesk Queue
```

New and updated tickets appear in Thunderbird as RSS items.

---

## Integration Testing Checklist

> **Automated test suite available** — run on the Azure VM before manual Thunderbird testing:
> ```bash
> ssh itstack@4.154.17.25
> bash ~/test-email.sh              # full suite (47 tests)
> bash ~/test-email.sh --section imap      # IMAP only
> bash ~/test-email.sh --section smtp      # SMTP only
> bash ~/test-email.sh --section flow      # end-to-end send+receive
> bash ~/test-email.sh --section nextcloud # Nextcloud Mail only
> bash ~/test-email.sh --section mailhog   # MailHog only
> bash ~/test-email.sh --verbose           # show debug output
> ```
> **Expected result: 47/47 PASS** (verified 2026-03-11). If any tests fail, resolve them before configuring Thunderbird.

### Email (docker-mailserver)
- [ ] Thunderbird connects to IMAP port **143** — **None** (no SSL) — no errors
- [ ] Thunderbird connects to SMTP port **587** — **None** (no SSL)
- [ ] Send email from Thunderbird (jdoe → admin) → admin receives it
- [ ] Receive email in Thunderbird (IMAP sync)
- [ ] Webmail check: http://4.154.17.25:8280 → Nextcloud Mail → same inbox visible
- [ ] Reply, forward work correctly

### Calendar (Nextcloud CalDAV)
- [ ] TbSync connects to Nextcloud without errors
- [ ] Calendars listed and subscribed in TbSync
- [ ] Create event in Nextcloud → appears in Thunderbird within 60s
- [ ] Create event in Thunderbird → appears in Nextcloud within 60s
- [ ] Two-way sync confirmed (no duplicates)

### Contacts (Nextcloud CardDAV)
- [ ] Address books discovered by TbSync
- [ ] Create contact in Nextcloud → appears in Thunderbird within 60s
- [ ] Create contact in Thunderbird → appears in Nextcloud
- [ ] Email autocomplete uses synced contacts

### LDAP (FreeIPA)
- [ ] Directory configured in Thunderbird
- [ ] Typing first 3 chars of username in **To:** returns suggestions
- [ ] All FreeIPA users appear in **Tools → Address Books → IT-Stack Directory**
- [ ] No authentication errors in Thunderbird error console

### OAuth2 / Keycloak (Production)
- [ ] Keycloak client `thunderbird-iredmail` exists in `it-stack` realm
- [ ] Thunderbird prompts browser login (not password dialog) on first connect
- [ ] Token refresh works — no re-login required within token lifetime
- [ ] Revoking Keycloak session logs Thunderbird out within token expiry

### S/MIME (FreeIPA CA)
- [ ] FreeIPA CA cert trusted in Thunderbird
- [ ] S/MIME cert imported for user `jdoe`
- [ ] Outgoing email shows 🔐 signing icon
- [ ] Signature verified by recipient's Thunderbird

---

## Quick Reference: All Endpoints

### Lab Environment (Azure VM `4.154.17.25`)

| Purpose | URL / Address | Port | Notes |
|---------|---------------|------|-------|
| **IMAP (docker-mailserver)** | `4.154.17.25` | **`143`** | ✅ Running — no SSL (lab) |
| **SMTP (docker-mailserver)** | `4.154.17.25` | **`587`** | ✅ Running — no SSL (lab) |
| **Nextcloud Mail (webmail)** | http://4.154.17.25:8280 → ✉ icon | 8280 | ✅ Running — browser webmail |
| MailHog (catch-all) | http://4.154.17.25:8025 | 8025 | Service notifications only |
| CalDAV | `http://4.154.17.25:8280/remote.php/dav/` | 8280 | Nextcloud |
| CardDAV | `http://4.154.17.25:8280/remote.php/dav/` | 8280 | Nextcloud |
| LDAP | `4.154.17.25` | `389` | FreeIPA (if running) |
| Keycloak | http://4.154.17.25:8180 | 8180 | SSO server + OAuth2 |

### Production (8-server layout)

| Purpose | Hostname | Port |
|---------|----------|------|
| IMAP | `mail.yourcompany.com` | `993` |
| SMTP | `mail.yourcompany.com` | `587` |
| CalDAV / CardDAV | `cloud.yourcompany.com` | `443` |
| LDAP | `ldap://lab-id1.yourcompany.com` | `389` |
| LDAPS | `ldaps://lab-id1.yourcompany.com` | `636` |
| OAuth2 issuer | `https://sso.yourcompany.com/realms/it-stack` | `443` |

---

## Troubleshooting

### Thunderbird cannot connect to IMAP

```
Problem: "Unable to connect to imap://4.154.17.25"
Checks:
  1. Is iRedMail container running? → docker ps | grep iredmail
  2. Is port 993 open in NSG? → az network nsg rule list --resource-group rg-it-stack-phase1 --nsg-name nsg-it-stack-lab
  3. Test IMAP: openssl s_client -connect 4.154.17.25:993
     Should return "220 iRedMail ESMTP Postfix"
  4. Check iRedMail logs: docker exec iredmail-demo tail -50 /var/log/dovecot/dovecot.log
```

### TbSync CalDAV authentication fails

```
Problem: "401 Unauthorized"
Checks:
  1. Use the exact Nextcloud username (case-sensitive): admin
  2. Verify Nextcloud app password (preferred over main password):
     Nextcloud → top-right avatar → Settings → Security → App passwords → Generate
     Use the app password in TbSync instead of main password
  3. Test CalDAV URL in browser: http://4.154.17.25:8280/remote.php/dav/
     Should prompt for basic auth — enter admin / Lab02Password!
```

### LDAP autocomplete not working

```
Problem: No suggestions appear when typing in To: field
Checks:
  1. In Thunderbird → Tools → Account Settings → Composition & Addressing
     → check "Use a different LDAP server" → verify server selected
  2. Test LDAP manually:
     ldapsearch -x -H ldap://4.154.17.25 -D "uid=admin,cn=users,cn=accounts,dc=lab,dc=localhost" \
       -w Lab01Password! -b "cn=users,cn=accounts,dc=lab,dc=localhost" "(uid=jdoe)"
  3. Check FreeIPA container is running: docker ps | grep freeipa
  4. Firewall: ensure port 389 open on VM and NSG
```

### S/MIME certificate shows "Untrusted"

```
Problem: Signed emails show warning — "No trusted certificate"
Fix:
  1. Download IPA CA: curl -k https://4.154.17.25:8180/ipa/config/ca.crt -o ipa-ca.crt
  2. Thunderbird → Options → Privacy & Security → Manage Certificates → Authorities → Import
  3. Check "Trust this CA to identify email users"
  4. Re-open email — should now show green checkmark
```

---

## Deployment Script: Thunderbird Auto-Config (autoconfig.xml)

For enterprise deployments, deploy an autoconfig file that Thunderbird reads automatically when users enter their email address. Host this via iRedMail's web server or Traefik.

**File path on iRedMail:** `/var/www/html/mail/.well-known/autoconfig/mail/config-v1.1.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<clientConfig version="1.1">
  <emailProvider id="itstack.local">
    <domain>itstack.local</domain>
    <displayName>IT-Stack Mail</displayName>
    <displayShortName>IT-Stack</displayShortName>

    <!-- IMAP incoming mail -->
    <incomingServer type="imap">
      <hostname>mail.itstack.local</hostname>
      <port>993</port>
      <socketType>SSL</socketType>
      <authentication>password-cleartext</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>

    <!-- SMTP outgoing mail -->
    <outgoingServer type="smtp">
      <hostname>mail.itstack.local</hostname>
      <port>587</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-cleartext</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>

    <!-- CalDAV calendar autodiscovery -->
    <documentation url="https://cloud.itstack.local/remote.php/dav/">
      <descr lang="en">Nextcloud CalDAV/CardDAV server</descr>
    </documentation>
  </emailProvider>
</clientConfig>
```

When a user opens Thunderbird and enters `jdoe@itstack.local`, Thunderbird fetches this file and pre-fills all settings — no manual configuration required.

---

## Holistic User Onboarding Workflow

When a new employee joins and IT creates their FreeIPA account, the complete Thunderbird setup should take < 10 minutes:

```
1. IT creates user in FreeIPA (or Odoo HR → FreeIPA sync)
   ipa user-add jdoe --first=John --last=Doe --email=jdoe@itstack.local

2. User opens Thunderbird → enters jdoe@itstack.local
   → Thunderbird fetches autoconfig.xml → pre-fills IMAP/SMTP
   → User enters password → connected to email

3. User installs TbSync + Provider add-ons
   → Tools → TbSync → Add CalDAV & CardDAV → Nextcloud URL
   → All calendars + contacts sync in 30 seconds

4. LDAP configured (IT can push this via policy/script)
   → Global directory is live — autocomplete for all 500+ users

5. (Optional) IT issues S/MIME cert from FreeIPA CA → user imports
   → All emails signed from day one

Result: Full enterprise email experience with calendar + contacts + directory
        in a single open-source client, all pointing to IT-Stack infrastructure.
```

---

## Related Documentation

- [Integration Guide](../02-implementation/12-integration-guide.md) — Cross-service integration procedures
- [GUI Walkthrough](22-gui-walkthrough.md) — Browse all services in a browser  
- [User Onboarding](16-user-onboarding.md) — New employee setup guide
- [iRedMail Lab Manual](../03-labs/) — iRedMail module & lab tests
- [Nextcloud Lab Manual](../03-labs/) — Nextcloud module & lab tests

---

*IT-Stack Thunderbird Integration Guide v1.0 — 2026-03-11*  
*Covers: iRedMail (09) · Nextcloud (06) · FreeIPA (01) · Keycloak (02)*
