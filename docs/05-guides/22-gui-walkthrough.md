# IT-Stack GUI Walkthrough Guide
### Explore Every Service on the Azure Cloud Lab VM

> **VM:** `lab-single` · **IP:** `4.154.17.25` · **Region:** West US 2, Azure  
> **SSH:** `ssh itstack@4.154.17.25`  
> **Goal:** Open your browser and explore real features on a live, running environment.

---

> ### ✅ Services Are Already Running
> All services listed in the **Active** column below are live on `lab-single` right now.
> **You do not need to run any `docker compose up` or start commands** for active services —
> simply open the URL in your browser. The "Start" sections in each module are preserved
> as reference for re-deployment on a fresh VM.
>
> Services marked **⏳ Pending** are not yet deployed on this VM.
> See [18-azure-lab-deployment.md](18-azure-lab-deployment.md) for deployment instructions.

---

## Quick Setup: Open Browser Access (5 minutes)

Services on `lab-single` are already running. All you need is to open the ports in the Azure NSG (if not already done) and open your browser.

```powershell
# Run once from your local Windows terminal (requires Azure CLI)
# These ports are already open on the current lab-single NSG — only needed on a fresh VM.
$RG  = "rg-it-stack-phase1"
$NSG = "lab-single-nsg"

# Active service ports
$ports = @(8080, 8180, 8265, 8280, 8302, 8303, 8305, 8307, 8380, 8880, 9001, 9002)
# Mail ports
$mailPorts = @(25, 143, 587)
# Jitsi video bridge (UDP)
# az network nsg rule create ... --protocol Udp --destination-port-ranges 10000

$priority = 1000
foreach ($p in ($ports + $mailPorts)) {
    az network nsg rule create `
        --resource-group $RG --nsg-name $NSG `
        --name "Allow-$p" --priority $priority `
        --protocol Tcp --destination-port-ranges $p `
        --access Allow --direction Inbound | Out-Null
    Write-Host "Opened TCP $p"
    $priority++
}
Write-Host "Done. Browse to http://4.154.17.25:<port>"
```

**Or use SSH tunneling** (no NSG changes needed; note Jitsi requires the real IP for UDP video):
```bash
# Forwards all active service ports to localhost. Keep this running in a terminal.
ssh -N \
  -L 8080:localhost:8080 \
  -L 8180:localhost:8180 \
  -L 8265:localhost:8265 \
  -L 8280:localhost:8280 \
  -L 8302:localhost:8302 \
  -L 8303:localhost:8303 \
  -L 8305:localhost:8305 \
  -L 8307:localhost:8307 \
  -L 8880:localhost:8880 \
  -L 9001:localhost:9001 \
  -L 9002:localhost:9002 \
  itstack@4.154.17.25
# Note: Jitsi video (WebRTC UDP) will not work over SSH tunnel — use the real IP 4.154.17.25:8880 directly.
```

> **If using NSG / public IP:** use `http://4.154.17.25:<port>` in all URLs.  
> **If using SSH tunnel:** use `http://localhost:<port>` (except Jitsi — use real IP).

---

## Service Directory

All URLs use the VM's public IP. If you prefer SSH tunnels, replace `4.154.17.25` with `localhost`.

### ✅ Active Services (running now on lab-single)

| Module | Service | Port | URL | Username | Password |
|--------|---------|------|-----|----------|----------|
| 18 | Traefik | 8080 | http://4.154.17.25:8080 | — | — |
| 02 | Keycloak SSO | 8180 | http://4.154.17.25:8180 | admin | *(check keycloak-demo ENV)* |
| 06 | Nextcloud | 8280 | http://4.154.17.25:8280 | admin | Lab02Password! |
| 07 | Mattermost | 8265 | http://4.154.17.25:8265 | testadmin@gmail.com | testadmin |
| 12 | SuiteCRM | 8302 | http://4.154.17.25:8302 | admin | Admin01! |
| 13 | Odoo ERP | 8303 | http://4.154.17.25:8303 | admin | admin (DB: testdb) |
| 16 | Snipe-IT | 8305 | http://4.154.17.25:8305 | admin | Lab01Password! |
| 19 | Zabbix | 8307 | http://4.154.17.25:8307 | Admin | zabbix |
| 08 | Jitsi Meet | 8880 | http://4.154.17.25:8880 | — | guest mode |
| 15 | Taiga | 9001 | http://4.154.17.25:9001 | admin | Lab01Password! |
| 20 | Graylog | 9002 | http://4.154.17.25:9002 | admin | Admin01! |
| — | docker-mailserver | 143/587 | IMAP/SMTP — see Thunderbird setup ↓ | admin@itstack.local | Lab01Password! |

> **Nextcloud webmail:** http://4.154.17.25:8280 → top-right grid icon → **Mail**  
> **Thunderbird desktop:** IMAP :143 / SMTP :587 (STARTTLS) · See [23-thunderbird-integration.md](23-thunderbird-integration.md)

### ⏳ Pending Services (not yet deployed on this VM)

| Module | Service | Planned Port | Reason | Reference |
|--------|---------|-------------|--------|-----------| 
| 11 | Zammad | 8380 | 30 GB disk full during JS asset write | Expand disk to 64 GB — see [18-azure-lab-deployment.md](18-azure-lab-deployment.md) |
| 01 | FreeIPA | 8180 | Requires dedicated VM (DNS/KDC conflict with Keycloak) | Deploy on `lab-id1` for production |
| 10 | FreePBX | 8301 | Phase 3 | Deploy on `lab-pbx1` |
| 14 | OpenKM | 8304 | Phase 3 | Deploy on `lab-biz1` |
| 17 | GLPI | 8306 | Phase 4 | Deploy on `lab-mgmt1` |
| 05 | Elasticsearch | 9200 | No standalone instance — bundled inside Graylog stack | Access via Graylog at :9002 |

---

## How to Start Each Service

> **On the live cloud lab:** all active services above are already running. The start/stop commands below are reference procedures for deploying on a fresh VM.

```bash
ssh itstack@4.154.17.25

# Check all running containers
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# Check a specific service log
docker logs --tail 50 <container-name>
```

---

## Module 01 — FreeIPA (LDAP + Kerberos + DNS)

> **What it is:** The identity backbone — manages all users, groups, DNS, and Kerberos tickets. This is what replaces Active Directory.

> ⚠️ **Not deployed on the current cloud lab VM.** FreeIPA requires a dedicated host due to its DNS server and Kerberos KDC footprint. On this single-VM deployment, Keycloak handles SSO standalone without FreeIPA federation. Deploy FreeIPA on `lab-id1` for production.  
> The Lab 01 test scripts and Ansible playbook for FreeIPA are available in the `it-stack-freeipa` repo.

```bash
# Deploy on a SEPARATE dedicated VM (not the current lab-single VM)
# Requires 16 GB RAM and a clean hostname already registered in DNS
ssh itstack@<lab-id1-ip>
cd ~/it-stack-labs/freeipa && bash start-standalone.sh
# OR run the phase1 test to start and verify:
bash ~/lab-phase1.sh   # runs all of Phase 1 including FreeIPA
```

**Browse to:** http://localhost:8180/ipa/ui/  
**Login:** `admin` / `Lab01Password!`

### Things to try:

1. **User Management** → Identity → Users → `+ Add`
   - Create `jdoe` with First: `John`, Last: `Doe`, Email: `jdoe@lab.localhost`
   - Set password: `LabUser01!`
   - Click **Add and Edit** → verify user profile

2. **Groups** → Identity → Groups → click `ipausers` → Members tab
   - See all users in the default group
   - Add `jdoe` to the group

3. **Hosts** → Identity → Hosts
   - See all enrolled hosts (the FreeIPA server itself)
   - Note the DNS entries that were auto-created

4. **DNS Zones** → Network Services → DNS → DNS Zones
   - Click `lab.localhost.` → see A records for all enrolled hosts

5. **SUDO Rules** → Policy → Sudo → see default rules
   - Create a new rule allowing `jdoe` to run `/bin/ls` on all hosts

6. **OTP / Two-Factor Auth** → Identity → Users → admin → Actions → Add OTP Token
   - Generate a TOTP token (scan QR with Google Authenticator)

7. **Certificate Authority** → Authentication → Certificates
   - See the built-in CA that signs all service certs

```bash
# Stop
cd ~/it-stack-labs/freeipa && docker compose down -v
```

---

## Module 02 — Keycloak (SSO / OAuth2 / OIDC / SAML)

> **What it is:** The single sign-on broker. Every other service authenticates through Keycloak. This is what replaces Azure AD B2C or Okta.

> ✅ **Already running** as `keycloak-demo` + `keycloak-proxy` on port 8180. Skip directly to **Things to try** below.

**Browse to:** http://4.154.17.25:8180  
**Login:** `admin` / *(check container ENV: `docker inspect keycloak-demo | grep KEYCLOAK_ADMIN_PASSWORD`)*

**Re-deploy from scratch (fresh VM only):**
```bash
mkdir -p ~/demo/keycloak && cd ~/demo/keycloak
docker run -d --name keycloak-demo \
  -p 8180:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=Lab01Password! \
  -e KC_HTTP_ENABLED=true \
  -e KC_HOSTNAME_STRICT=false \
  quay.io/keycloak/keycloak:24.0.5 start-dev
# Wait ~60s, then browse
```

### Things to try:

1. **Master Realm → Realm Settings**
   - See the built-in `master` realm
   - Under **Tokens**, note Access Token Lifespan (300s default)

2. **Create the `it-stack` realm** (what all services use)
   - Top-left dropdown → **Create Realm** → Name: `it-stack` → Create
   - This is the production realm — all service clients go here

3. **Create a Client (simulating Nextcloud)**
   - Clients → Create client → Protocol: `OpenID Connect`
   - Client ID: `nextcloud` → Next
   - Enable **Client authentication** → Standard flow checked → Next
   - Root URL: `http://localhost:8280`
   - Valid redirect URIs: `http://localhost:8280/*`
   - Save → Credentials tab → copy the **Client Secret**

4. **Create a User**
   - Users → Create new user
   - Username: `testuser`, Email: `test@lab.localhost`
   - Credentials → Set password: `Test01!` → Temporary: OFF

5. **Try logging in as that user**
   - Open Incognito tab → Go to: `http://localhost:8180/realms/it-stack/account/`
   - Login as `testuser` / `Test01!`
   - See the user's account management portal (change password, add OTP, see sessions)

6. **Identity Providers**
   - Identity Providers → Add provider → GitHub (or LDAP)
   - This is where you'd federate FreeIPA LDAP

7. **Events**
   - Events → Login Events → see all auth events in real time

8. **Token Introspection via API**
   ```bash
   # Get a token for testuser
   curl -s -X POST http://localhost:8180/realms/it-stack/protocol/openid-connect/token \
     -d "grant_type=password&client_id=nextcloud&client_secret=YOUR_SECRET&username=testuser&password=Test01!" \
     | python3 -m json.tool
   ```

```bash
# Stop
docker stop keycloak-demo && docker rm keycloak-demo
```

---

## Module 18 — Traefik (Reverse Proxy)

> **What it is:** The front door. All HTTPS traffic goes through Traefik, which routes to services by hostname. Replaces Nginx + manual SSL config.

**Start:**
```bash
ssh itstack@4.154.17.25
mkdir -p ~/demo/traefik && cd ~/demo/traefik
cat > docker-compose.yml << 'EOF'
services:
  traefik:
    image: traefik:v3.1
    container_name: traefik-demo
    ports:
      - "8088:80"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
    labels:
      - "traefik.enable=true"

  whoami-1:
    image: traefik/whoami
    container_name: whoami-1
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.whoami-1.rule=Host(`app1.lab.localhost`)"

  whoami-2:
    image: traefik/whoami
    container_name: whoami-2
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.whoami-2.rule=Host(`app2.lab.localhost`)"
EOF
docker compose up -d
sleep 5
```

**Browse to:** http://localhost:8080 (Traefik Dashboard — no auth)

### Things to try:

1. **Dashboard Overview**
   - See the entrypoints (web on port 80)
   - HTTP Routers: `whoami-1` routing to `app1.lab.localhost`, `whoami-2` to `app2.lab.localhost`
   - Services: see both whoami backends

2. **Test routing**
   ```bash
   # From your local machine:
   curl -H "Host: app1.lab.localhost" http://localhost:8088
   curl -H "Host: app2.lab.localhost" http://localhost:8088
   # Each returns the request details from a different container
   ```

3. **Health checks**
   ```bash
   curl http://localhost:8080/api/http/routers | python3 -m json.tool
   curl http://localhost:8080/api/http/services | python3 -m json.tool
   ```

4. **Live config update** — add a new container without restarting Traefik:
   ```bash
   docker run -d --name whoami-3 \
     -l "traefik.enable=true" \
     -l "traefik.http.routers.whoami-3.rule=Host(\`app3.lab.localhost\`)" \
     traefik/whoami
   # Refresh the dashboard — whoami-3 appears automatically
   ```

```bash
docker compose down -v && docker rm whoami-3 2>/dev/null
```

---

## Module 06 — Nextcloud (File Sharing / Calendar / Office)

> **What it is:** Your own Google Drive + Google Docs + Google Calendar. All files stay on your servers.

> ✅ **Already running** as `nc-demo` on port 8280. **57 apps are enabled** including Calendar, Contacts, Talk, Forms, Tables, GroupFolders, TOTP 2FA, LDAP, SAML, Maps, PhoneTrack, Recognize, and more. Skip directly to **Things to try** below.

**Browse to:** http://4.154.17.25:8280  
**Login:** `admin` / `Lab02Password!`

**Re-deploy from scratch (fresh VM only):**
```bash
ssh itstack@4.154.17.25
mkdir -p ~/demo/nextcloud && cd ~/demo/nextcloud
cat > docker-compose.yml << 'EOF'
services:
  nextcloud-db:
    image: postgres:16
    container_name: nc-db-demo
    environment:
      POSTGRES_DB: nextcloud
      POSTGRES_USER: nextcloud
      POSTGRES_PASSWORD: Lab02Password!
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U nextcloud -d nextcloud"]
      interval: 10s
      retries: 10
    networks: [nc-demo-net]

  nextcloud:
    image: nextcloud:28-apache
    container_name: nc-demo
    ports:
      - "8280:80"
    depends_on:
      nextcloud-db:
        condition: service_healthy
    environment:
      POSTGRES_HOST: nextcloud-db
      POSTGRES_DB: nextcloud
      POSTGRES_USER: nextcloud
      POSTGRES_PASSWORD: Lab02Password!
      NEXTCLOUD_ADMIN_USER: admin
      NEXTCLOUD_ADMIN_PASSWORD: Lab02Password!
      NEXTCLOUD_TRUSTED_DOMAINS: "localhost 4.154.17.25"
    volumes:
      - nc_data:/var/www/html
    networks: [nc-demo-net]

volumes:
  nc_data:

networks:
  nc-demo-net:
EOF
docker compose up -d
echo "Nextcloud starting (~2 min)..."
```

**Browse to:** http://localhost:8280  
**Login:** `admin` / `Lab02Password!`

### Things to try:

1. **File Upload**
   - Click **Files** (folder icon) → **+ New** → Upload file
   - Upload a document from your local machine
   - Right-click it → **Share** → enter an email → see share link generated

2. **Create a Shared Folder**
   - New → New folder → name it `IT-Stack Team`
   - Share it → enable "Public link" → copy the URL → open in incognito window

3. **Calendar**
   - Top-right grid → **Calendar** app
   - Create a new event: "IT-Stack Go-Live" → set date/time → add notification
   - See CalDAV subscription URL (can be added to any calendar app)

4. **Contacts**
   - Top-right grid → **Contacts** → New contact
   - Add name, email, phone → see vCard format option

5. **Onlyoffice / Text editor**
   - Click a `.txt` or `.md` file → opens inline editor
   - Make changes → auto-saves

6. **Users & Groups**
   - Top-right profile → Administration → Users
   - Create a new user: `jdoe` / email: `jdoe@lab.localhost` / password: `LabUser01!`
   - Set storage quota: 5 GB

7. **Apps**
   - Top-right grid → **Apps** → browse available apps
   - Note: Calendar, Contacts, Talk (video), Forms, Deck (Kanban) are all free

8. **WebDAV mount (optional)**
   ```
   # Mount Nextcloud as a network drive in Windows File Explorer:
   # Map network drive → \\localhost@8280\DavWWWRoot\remote.php\dav\files\admin\
   ```

```bash
docker compose down -v
```

---

## Module 07 — Mattermost (Team Chat)

> **What it is:** Your own Slack. Real-time messaging, channels, threads, file sharing, webhooks.

> ✅ **Already running** as `mm-demo` on port 8265. SMTP is configured via `mail-demo`. Skip directly to **Things to try** below.

**Browse to:** http://4.154.17.25:8265  
**Login:** `testadmin@gmail.com` / `testadmin`
```bash
ssh itstack@4.154.17.25
mkdir -p ~/demo/mattermost && cd ~/demo/mattermost
cat > docker-compose.yml << 'EOF'
services:
  mattermost-db:
    image: postgres:16
    container_name: mm-db-demo
    environment:
      POSTGRES_DB: mattermost
      POSTGRES_USER: mattermost
      POSTGRES_PASSWORD: Lab02Password!
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U mattermost -d mattermost"]
      interval: 10s
      retries: 10
    networks: [mm-demo-net]

  mattermost:
    image: mattermost/mattermost-team-edition:latest
    container_name: mm-demo
    ports:
      - "8265:8065"
    depends_on:
      mattermost-db:
        condition: service_healthy
    environment:
      MM_SQLSETTINGS_DRIVERNAME: postgres
      MM_SQLSETTINGS_DATASOURCE: "postgres://mattermost:Lab02Password!@mattermost-db:5432/mattermost?sslmode=disable"
      MM_SERVICESETTINGS_SITEURL: "http://localhost:8265"
    networks: [mm-demo-net]

networks:
  mm-demo-net:
EOF
docker compose up -d
echo "Mattermost starting (~90s)..."
```

**Browse to:** http://localhost:8265  
**Setup:** Create admin account via the setup wizard (`admin@lab.localhost` / `Lab02Password!`)
> **Note:** The existing deployment uses `testadmin@gmail.com` / `testadmin` as the admin account.

### Things to try:

1. **Create Team & Channels**
   - Setup wizard creates your first team
   - Create channels: `#announcements`, `#dev-team`, `#ops-alerts`, `#random`
   - Try public vs private channels

2. **Send Messages with Formatting**
   - Use Markdown: `**bold**`, `_italic_`, `` `code` ``, code blocks with syntax highlighting
   - Mention a user: `@admin`
   - Use emoji: `:thumbsup:` → 👍

3. **Direct Messages**
   - Compose → New Direct Message → select yourself (works for testing)
   - In production: DM between any two team members

4. **Threads**
   - Hover over a message → Reply → create a thread
   - See thread view in the right sidebar

5. **File Sharing**
   - Drag and drop a file into the message box
   - Image files preview inline

6. **Incoming Webhooks**
   - Main Menu → Integrations → Incoming Webhooks → Add
   - Copy the webhook URL
   ```bash
   # Post a message via webhook (from VM):
   curl -X POST http://localhost:8265/hooks/YOUR_HOOK_ID \
     -H "Content-Type: application/json" \
     -d '{"text":"🚨 **Test alert** from IT-Stack webhook integration", "channel":"ops-alerts"}'
   ```
   - See the message appear in `#ops-alerts` channel

7. **Bot Accounts**
   - Integrations → Bot Accounts → Add Bot
   - Name: `it-stack-bot` → used by Zabbix for alert notifications

8. **Slash Commands**
   - In any channel: `/help` → see all commands
   - `/away` → change status
   - `/invite @user` → invite to channel

```bash
docker compose down -v
```

---

## Module 08 — Jitsi Meet (Video Conferencing)

> **What it is:** Your own Zoom/Google Meet. No accounts needed for guests, no call limits, end-to-end encrypted.

> ✅ **Already running** as `jitsi-web-lab01` (+ prosody, jicofo, jvb) on port 8880. Guest mode enabled. JVB UDP :10000 is open in the NSG. Skip directly to **Things to try** below.
>
> ⚠️ **Must use the real IP, not localhost** — video transport uses WebRTC UDP to the public IP. SSH tunneling will result in one-way audio/video.

**Browse to:** http://4.154.17.25:8880  
**No login required** — guest mode.

**Re-deploy from scratch (fresh VM only):**
```bash
ssh itstack@4.154.17.25
mkdir -p ~/demo/jitsi && cd ~/demo/jitsi
cat > docker-compose.yml << 'EOF'
services:
  prosody:
    image: jitsi/prosody:stable
    container_name: jitsi-prosody-demo
    expose: ["5222", "5269", "5347", "5280"]
    environment:
      AUTH_TYPE: internal
      ENABLE_AUTH: 1
      ENABLE_GUESTS: 1
      XMPP_DOMAIN: meet.jitsi
      XMPP_AUTH_DOMAIN: auth.meet.jitsi
      XMPP_MUC_DOMAIN: muc.meet.jitsi
      XMPP_GUEST_DOMAIN: guest.meet.jitsi
      XMPP_INTERNAL_MUC_DOMAIN: internal-muc.meet.jitsi
      XMPP_MODULES: ""
      JICOFO_AUTH_USER: focus
      JICOFO_AUTH_PASSWORD: Lab02JicofoPass!
      JVB_AUTH_USER: jvb
      JVB_AUTH_PASSWORD: Lab02JvbPass!
      TZ: UTC
    networks: [jitsi-demo-net]

  jicofo:
    image: jitsi/jicofo:stable
    container_name: jitsi-jicofo-demo
    environment:
      AUTH_TYPE: internal
      XMPP_DOMAIN: meet.jitsi
      XMPP_AUTH_DOMAIN: auth.meet.jitsi
      XMPP_INTERNAL_MUC_DOMAIN: internal-muc.meet.jitsi
      XMPP_SERVER: prosody
      JICOFO_AUTH_USER: focus
      JICOFO_AUTH_PASSWORD: Lab02JicofoPass!
      JVB_BREWERY_MUC: jvbbrewery
      JIBRI_BREWERY_MUC: jibribrewery
      TZ: UTC
    depends_on: [prosody]
    networks: [jitsi-demo-net]

  jvb:
    image: jitsi/jvb:stable
    container_name: jitsi-jvb-demo
    ports:
      - "10000:10000/udp"
    environment:
      DOCKER_HOST_ADDRESS: "4.154.17.25"
      XMPP_AUTH_DOMAIN: auth.meet.jitsi
      XMPP_INTERNAL_MUC_DOMAIN: internal-muc.meet.jitsi
      XMPP_SERVER: prosody
      JVB_AUTH_USER: jvb
      JVB_AUTH_PASSWORD: Lab02JvbPass!
      JVB_BREWERY_MUC: jvbbrewery
      TZ: UTC
    depends_on: [prosody]
    networks: [jitsi-demo-net]

  web:
    image: jitsi/web:stable
    container_name: jitsi-web-demo
    ports:
      - "8880:80"
    environment:
      PUBLIC_URL: "http://4.154.17.25:8880"
      XMPP_DOMAIN: meet.jitsi
      XMPP_AUTH_DOMAIN: auth.meet.jitsi
      XMPP_MUC_DOMAIN: muc.meet.jitsi
      XMPP_GUEST_DOMAIN: guest.meet.jitsi
      XMPP_BOSH_URL_BASE: http://prosody:5280
      ENABLE_AUTH: 1
      ENABLE_GUESTS: 1
      TZ: UTC
    depends_on: [prosody, jicofo, jvb]
    networks: [jitsi-demo-net]

networks:
  jitsi-demo-net:
EOF
# Also open UDP 10000 for video (required):
sudo ufw allow 10000/udp 2>/dev/null; true
docker compose up -d
sleep 15
```

**Browse to:** http://4.154.17.25:8880 (**must use the VM's real IP, not localhost — video won't work over localhost**)

### Things to try:

1. **Start a Conference**
   - Enter room name: `it-stack-demo`
   - Allow microphone/camera access
   - Share the link with someone else to join

2. **Screen Sharing**
   - Click the screen share button → select a window or entire screen

3. **Chat in Conference**
   - Click the chat bubble during a call → send messages to all participants

4. **Tile View / Speaker View**
   - Switch between layouts during a multi-person call

5. **Security: Add Password to Room**
   - Info icon (i) → Add password → set `demo123`
   - Anyone joining must enter the password

6. **Recording (if Jibri configured)** — shows the button even in standalone mode

> **Note:** Video requires UDP port 10000 open in Azure NSG AND your browser connecting to the real IP (not an SSH tunnel). If video doesn't work, it's the UDP port.

```bash
docker compose down -v
```

---

## Module 11 — Zammad (Help Desk / Ticketing)

> **What it is:** Your own Jira Service Management or Zendesk. Email support, live chat, ticket tracking.

> ⏳ **Not yet deployed on this VM.** Zammad's JavaScript asset compilation requires ~1.5 GB of free disk space during first start. The 30 GB OS disk reached capacity before this step could complete.
>
> **To deploy Zammad:**  
> 1. Expand the OS disk to 64 GB (see [18-azure-lab-deployment.md → Disk Expansion](18-azure-lab-deployment.md))  
> 2. Run: `docker compose -f ~/it-stack-labs/zammad/docker-compose.yml up -d`  
> 3. Browse to: http://4.154.17.25:8380 and complete the setup wizard

**Setup wizard credentials (first run):**
1. Admin email: `admin@itstack.local`
2. Password: `Lab02Password!`
3. Organization name: `IT-Stack Lab`
4. Email: skip for now (click "Skip")
5. Done

### Things to try:

1. **Create Your First Ticket**
   - New Ticket → Inbound Phone / Email
   - Title: `Cannot access Nextcloud`
   - Customer: create new → `jdoe@lab.localhost`
   - Group: `Users` → State: `open` → Priority: `2 normal`
   - Body: `User reports unable to log in. Error: Invalid credentials.`

2. **Ticket Assignment**
   - Click the ticket → Assign to agent (yourself)
   - Change state to `pending reminder` → set reminder for tomorrow

3. **Add Internal Note**
   - In the ticket → text area → switch from "Ticket" to "Note (internal)"
   - Write: `Checked with Keycloak — user account was locked. Unlocked and reset.`
   - Notes are not visible to the customer

4. **Merge Tickets**
   - Create a second ticket from the same customer
   - Open first ticket → gear icon → Merge → select second ticket

5. **SLA Configuration**
   - Admin (top-right) → Manage → Macros → view default macros
   - Admin → Manage → SLAs → create "Critical: 1hr first response"

6. **Organizations**
   - Admin → Manage → Organizations → New Organization
   - Name: `IT-Stack Corp` → add jdoe as member

7. **Email Channel (simulated)**
   - Admin → Channels → Email → see where you'd configure Gmail/IMAP

---

## Module 10 — FreePBX (VoIP / PBX)

> **What it is:** Your own enterprise phone system. Replaces RingCentral / 8x8. Handles inbound/outbound calls, IVR, voicemail, call recording.

> ⏱ **First startup takes 15–30 minutes** (downloads and installs 100+ modules)

```bash
ssh itstack@4.154.17.25
# FreePBX was already tested in phase3 — if containers were cleaned, restart:
bash ~/lab-phase3.sh --only-freepbx
```

**Browse to:** http://localhost:8301/admin  
**Login:** Click "FreePBX Administration" → setup wizard on first run

### Things to try:

1. **Admin Dashboard**
   - See the FreePBX dashboard with module status
   - System Status panel: Asterisk, Database, SIP trunks

2. **Create Extensions**
   - Applications → Extensions → Add Extension → chan_pjsip
   - Extension: `1001`, Display Name: `John Doe`
   - Password: `securepass123` → Submit
   - Create a second: Extension `1002`, Display Name: `Jane Smith`

3. **Ring Groups**
   - Applications → Ring Groups → Add Ring Group
   - Ring-Group Number: `600`
   - Extensions In This Group: 1001, 1002
   - Ring Strategy: `ringall`

4. **IVR / Auto Attendant**
   - Applications → IVR → Add IVR
   - Name: "IT-Stack Main Menu"
   - Press 1 → route to extension 1001
   - Press 2 → route to ring group 600

5. **Voicemail**
   - Admin → User Management → Admin
   - Applications → Voicemail → see all voicemail boxes
   - Extension 1001's voicemail box auto-created

6. **Call Recording**
   - Admin → Reports → Asterisk Logfiles
   - Admin → Reports → Asterisk Info → see channels, peers, registrations

7. **SIP Trunk (simulated)**
   - Connectivity → Trunks → Add Trunk → pjsip
   - Trunk Name: `SIP-Provider-Demo`
   - (Would connect to a real SIP provider like Twilio, VoIP.ms, etc.)

---

## Module 12 — SuiteCRM (Customer Relationship Management)

> **What it is:** Your own Salesforce. Manage leads, accounts, contacts, campaigns, and sales pipelines.

```bash
ssh itstack@4.154.17.25
bash ~/lab-phase3.sh --only-suitecrm
```

**Browse to:** http://localhost:8302  
**Login:** `admin` / `Admin01!`

### Things to try:

1. **Dashboard Overview**
   - See the Sales Pipeline, Saved Reports, and Activity Summary dashlets
   - Customize: drag dashlets, add new ones

2. **Create an Account (Company)**
   - Accounts → Create Account
   - Name: `Acme Corporation`
   - Industry: `Technology`, Annual Revenue: `$5,000,000`
   - Phone: `555-0100`, Website: `www.acme.example.com`

3. **Create a Contact**
   - Contacts → Create Contact
   - First: `Alice`, Last: `Smith`, Account: `Acme Corporation`
   - Email: `alice@acme.example.com`, Phone: `555-0101`

4. **Create a Lead**
   - Leads → Create Lead
   - Name: `Bob Johnson`, Company: `New Prospect Inc.`
   - Status: `New`, Lead Source: `Web Site`
   - Convert Lead → creates Account + Contact + Opportunity

5. **Create an Opportunity**
   - Opportunities → Create Opportunity
   - Name: `Acme - CRM License Q1`
   - Account: `Acme Corporation`
   - Amount: `$25,000`, Close Date: (next month)
   - Sales Stage: `Proposal/Price Quote`

6. **Activities: Calls & Meetings**
   - Activities → Log Call → Account: Acme → Description: `Demo call with Alice`
   - Activities → Schedule Meeting → invitees: admin + alice@acme.example.com

7. **Cases (Support Tickets)**
   - Support → Cases → Create Case
   - Subject: `Cannot log into portal`
   - Account: Acme Corporation, Priority: High

8. **Reports**
   - Reports → Create Report → Rows and Columns
   - Module: Opportunities → Filter: Close Date = this quarter
   - See your Q1 pipeline

---

## Module 13 — Odoo (ERP)

> **What it is:** Your own SAP / QuickBooks. Invoicing, inventory, employees, payroll, projects — all in one.

```bash
ssh itstack@4.154.17.25
bash ~/lab-phase3.sh --only-odoo
```

**Browse to:** http://localhost:8303  
**Database setup:** Click "Create Database" → 
- Name: `itstack`, Email: `admin@itstack.local`, Password: `Admin01!`
- Language: English, Country: United States
- Demo data: ✅ (check this for pre-populated data to explore)

### Things to try:

1. **Install Core Apps**
   - Main menu → Apps → install:
     - Invoicing, Inventory, Employees, Project, CRM, Purchase

2. **Create a Customer Invoice**
   - Accounting (or Invoicing) → Customers → Invoices → New
   - Customer: create or pick from demo data
   - Add line: Product "Consulting Services" → Qty 10 → Price $150
   - Confirm → see the PDF preview → Send by Email

3. **Inventory Management**
   - Inventory → Products → Create
   - Name: `Laptop Dell XPS`, Type: Storable, Cost: $1200
   - Update Quantity → On Hand: 20
   - See warehouse locations, delivery orders

4. **Employee Management**
   - Employees → New Employee
   - Name: John Doe, Job Position: IT Administrator
   - Private Info → set bank account (for payroll)
   - Work Schedule: 40-hour week

5. **Project Management**
   - Project → New Project: `IT-Stack Deployment`
   - Create tasks: Installation, Testing, Go-Live
   - Assign tasks to employees, set deadlines, track time

6. **Purchase Orders**
   - Purchase → Orders → New
   - Vendor: Dell Technologies → Order Line: Laptop Dell XPS, Qty 5
   - Confirm Order → see the receipt/billing workflow

7. **CRM Pipeline**
   - CRM → My Pipeline → see Kanban view
   - Create a new lead/opportunity → drag through stages

```bash
docker compose --project-directory ~/demo/odoo down -v 2>/dev/null || true
```

---

## Module 14 — OpenKM (Document Management)

> **What it is:** Your own SharePoint document library. Version control, metadata, workflows, full-text search.

```bash
ssh itstack@4.154.17.25
bash ~/lab-phase3.sh --only-openkm
```

**Browse to:** http://localhost:8304/OpenKM  
**Login:** `okmAdmin` / `admin`

### Things to try:

1. **Upload Documents**
   - Left panel: `okm:root` → right-click → New Folder → name: `IT-Stack Docs`
   - Upload → drag your IT-Stack documentation files

2. **Document Properties & Metadata**
   - Click an uploaded document → Properties panel
   - Add metadata: Author, Department, Expiry Date
   - See version history (automatically tracks every change)

3. **Full-Text Search**
   - Top search box → search for a word inside a PDF
   - OpenKM indexes content of Word, PDF, Excel files

4. **Workflows**
   - Administration → Workflow → see built-in approval workflows
   - Submit a document for review → assign reviewer

5. **Access Control**
   - Right-click a folder → Manage Permissions
   - Set read-only for group `users`, write for `admins`

6. **WebDAV Access**
   - Tools → Administration → Repositories → see WebDAV URL
   - Mount as a network drive → `http://localhost:8304/OpenKM/webdav/okm%3Aroot`

---

## Module 16 — Snipe-IT (IT Asset Management)

> **What it is:** Your own ServiceNow ITAM. Track laptops, servers, software licenses, accessories.

```bash
ssh itstack@4.154.17.25
bash ~/lab-phase4.sh --only-snipeit
```

**Browse to:** http://localhost:8305  
**First run:** Setup wizard
1. Site Name: `IT-Stack Assets`, URL: `http://localhost:8305`
2. Admin: email `admin@lab.localhost`, password `Lab02Password!`

### Things to try:

1. **Create Asset Categories**
   - Settings → Categories → Create Category
   - Laptops, Servers, Network Equipment, Peripherals

2. **Add Hardware Assets**
   - Assets → Create New Asset
   - Asset Tag: `IT-001`, Model: select or create
   - Create model first: Dell XPS 15 → Category: Laptops → Manufacturer: Dell
   - Status: Ready to Deploy

3. **Check Out to a User**
   - Open IT-001 → Checkout → To a User → John Doe
   - Set Expected Checkin date → Submit
   - See asset is now "Deployed" to John Doe

4. **Software Licenses**
   - Licenses → Create License
   - Name: `Microsoft Office 365`, Seats: 50, Cost: $12/seat
   - Checkout a seat to user John Doe

5. **Asset Audit**
   - Reports → Asset Audit → see all assets with last checked-in dates
   - Export to CSV

6. **Depreciation**
   - Settings → Depreciation → create 3-Year Straight Line
   - Apply to IT-001 → see current book value calculation

---

## Module 17 — GLPI (IT Service Management / CMDB)

> **What it is:** Your own ServiceNow. Help desk tickets, CMDB, change management, SLAs.

```bash
ssh itstack@4.154.17.25
bash ~/lab-phase4.sh --only-glpi
```

**Browse to:** http://localhost:8306  
**Login:** `glpi` / `glpi`  
> Change the password immediately when prompted (set to `Lab02Password!`)

### Things to try:

1. **CMDB — Add a Computer**
   - Assets → Computers → Add
   - Name: `lab-db1`, Serial: `VMAZ001`
   - OS: Ubuntu 24.04, RAM: 32768 MB, CPU: 8 cores
   - Location: Data Center → Rack 1 → Unit 3

2. **Network Equipment**
   - Assets → Network Equipment → Add
   - Add switch, router, access points → see network topology view

3. **Help Desk Ticket**
   - Assistance → Tickets → Add
   - Title: `lab-db1 PostgreSQL high CPU`
   - Category: Database → Assign to Tech group
   - Priority: Very High → set due date

4. **Problem Management**
   - Assistance → Problems → Add
   - Describe a recurring issue → link related tickets

5. **Change Management**
   - Assistance → Changes → Add
   - Title: `Upgrade PostgreSQL 15 → 16`
   - Type: Normal → Status: Evaluation → add implementation plan

6. **SLA**
   - Setup → SLAs → create:
     - Critical: 1h response, 4h resolution
     - High: 4h response, 8h resolution

7. **Reports**
   - Tools → Reports → see built-in reports
   - Assets by status, tickets by technician, MTTR charts

---

## Module 19 — Zabbix (Infrastructure Monitoring)

> **What it is:** Your own Datadog. Monitor servers, services, network devices. Alerts via email, Mattermost, PagerDuty.

```bash
ssh itstack@4.154.17.25
bash ~/lab-phase4.sh --only-zabbix
```

**Browse to:** http://localhost:8307  
**Login:** `Admin` / `zabbix` → change to `Lab02Password!` when prompted

### Things to try:

1. **Dashboard**
   - See the Global View dashboard with host availability, triggers, maps
   - Problems widget: shows active alerts color-coded by severity

2. **Add a Host (Monitor the Azure VM itself)**
   - Data Collection → Hosts → Create Host
   - Hostname: `lab-single`, Groups: `Linux servers`
   - Interfaces: Agent — IP: `172.17.0.1` (Docker bridge to host)
   - Apply template: `Linux by Zabbix agent`
   - See CPU, memory, disk, network metrics appear

3. **View Hosts Map**
   - Monitoring → Maps → Local network
   - See topology map with green/red host status

4. **Create a Simple Trigger**
   - Go to a host → Triggers → Create trigger
   - Name: `High CPU on lab-single`
   - Expression: `avg(/lab-single/system.cpu.util,5m)>80`
   - Severity: High

5. **Action — Alert via Webhook**
   - Alerts → Actions → Trigger actions → Create
   - Connect to Mattermost incoming webhook URL
   - Set message template for the alert notification

6. **Graphs**
   - Monitoring → Graphs → select host `lab-single`
   - CPU utilization, memory, network I/O — real-time graphs

7. **API — Get Hosts via curl**
   ```bash
   TOKEN=$(curl -s -X POST http://localhost:8307/api_jsonrpc.php \
     -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","method":"user.login","id":1,"params":{"username":"Admin","password":"zabbix"}}' \
     | python3 -c "import sys,json; print(json.load(sys.stdin)['result'])")
   curl -s -X POST http://localhost:8307/api_jsonrpc.php \
     -H "Content-Type: application/json" \
     -d "{\"jsonrpc\":\"2.0\",\"method\":\"host.get\",\"id\":2,\"auth\":\"$TOKEN\",\"params\":{\"output\":[\"hostid\",\"host\"]}}" \
     | python3 -m json.tool
   ```

---

## Module 15 — Taiga (Project Management)

> **What it is:** Your own Jira + Trello. Scrum boards, Kanban, sprints, epics, user stories.

```bash
ssh itstack@4.154.17.25
bash ~/lab-phase4.sh --only-taiga
```

**Browse to:** http://localhost:9001  
**Login:** `admin` / `Lab01Password!`

### Things to try:

1. **Create a Project**
   - New Project → Scrum → Name: `IT-Stack Phase 1`
   - Add members: create user `jdoe` via admin panel first

2. **Backlog — User Stories**
   - Backlog → + button → create user stories:
     - "As an admin I want to deploy FreeIPA so users can authenticate"
     - "As a user I want to log in to Nextcloud via SSO"
   - Assign story points: 3, 5, 8 (Fibonacci)

3. **Sprint Planning**
   - Backlog → New Sprint → Sprint 1 / 2 weeks
   - Drag user stories from Backlog into the sprint

4. **Kanban Board**
   - Kanban view → see stories in New / In Progress / Ready for Test / Done
   - Move a card through the pipeline

5. **Issues**
   - Issues → + button → Bug: `FreeIPA install fails on Azure (cgroupv2)`
   - Assign severity: Critical, Priority: High, Assign to: admin

6. **Epics**
   - Epics (lightning bolt icon) → Create Epic: `Phase 1: Foundation`
   - Link the user stories to this epic

7. **GitHub Integration** (needs GitHub API token)
   - Project Settings → Integrations → GitHub
   - Connect to `it-stack-dev/it-stack-freeipa` → see commits per user story

---

## Module 20 — Graylog (Centralized Log Management)

> **What it is:** Your own Splunk. Collect logs from all 20 services, search in milliseconds, alert on log patterns.

```bash
ssh itstack@4.154.17.25
bash ~/lab-phase4.sh --only-graylog
```

**Browse to:** http://localhost:9002  
**Login:** `admin` / `Admin01!`

### Things to try:

1. **Overview Dashboard**
   - See all configured inputs, streams, and message count

2. **Create a GELF UDP Input**
   - System → Inputs → Select Input: `GELF UDP` → Launch
   - Title: `IT-Stack GELF`, Port: `12201`, Bind: `0.0.0.0`
   - Start input → now ready to receive logs

3. **Send Test Logs**
   ```bash
   # From the Azure VM (SSH in):
   echo '{"version":"1.1","host":"lab-single","short_message":"IT-Stack test log entry","level":6,"_service":"demo","_module":"keycloak"}' \
     | nc -u -w 2 localhost 12201
   # Send 10 logs with different levels:
   for i in {1..10}; do
     echo "{\"version\":\"1.1\",\"host\":\"lab-single\",\"short_message\":\"Test message #$i\",\"level\":$((i % 7)),\"_index\":$i}" \
       | nc -u -w 1 localhost 12201
   done
   ```

4. **Search Logs**
   - Search → `*` → see all messages → real-time updates
   - Search: `_service:demo` → filter by service
   - Search: `level:3` → only errors (level 3 = error)

5. **Search with Time Range**
   - Last 5 minutes → click a message → see all fields
   - Create a saved search: `IT-Stack Errors`

6. **Create a Stream**
   - Streams → Create Stream: `Keycloak Auth Failures`
   - Rule: `_service equals keycloak` AND `level ≤ 3`
   - Stream receives all Keycloak error logs

7. **Create an Alert**
   - Alerts → Event Definitions → Create Event Definition
   - Title: `Auth Failures Spike`
   - Condition: Stream `Keycloak Auth Failures` → message count > 10 in 5 minutes
   - Notification: HTTP webhook → Mattermost `#ops-alerts`

8. **Pipeline Processing**
   - System → Pipelines → Create Pipeline: `Enrich Logs`
   - Rule: `set_field("environment", "lab-test")`
   - All messages from the GELF input get the tag `environment: lab-test`

---

## MailHog — Fake Email Server (Lab Demo)

> **What it is:** A lightweight fake SMTP server with a web inbox. All emails sent by any IT-Stack service in the lab are caught here — nothing is delivered to real addresses. It replaces iRedMail for quick lab testing.

**Status:** Already running on the Azure demo VM (started in prior session).

**Browse to:** http://4.154.17.25:8025  
**Login:** None — open access

### Things to try:

1. **View the current inbox**
   - Open http://4.154.17.25:8025 in your browser
   - You should see the test "Welcome to IT-Stack!" email already in the inbox
   - Click it → see HTML and plain text tabs, headers, source

2. **Send a test email (Python)**
   ```bash
   ssh itstack@4.154.17.25
   python3 -c "
   import smtplib
   from email.mime.multipart import MIMEMultipart
   from email.mime.text import MIMEText
   msg = MIMEMultipart('alternative')
   msg['Subject'] = 'Test from IT-Stack Lab'
   msg['From'] = 'admin@itstack.local'
   msg['To'] = 'jdoe@itstack.local'
   msg.attach(MIMEText('Plain text body', 'plain'))
   msg.attach(MIMEText('<b>HTML body</b><br>From IT-Stack', 'html'))
   s = smtplib.SMTP('localhost', 1025)
   s.send_message(msg)
   s.quit()
   print('Sent — check http://4.154.17.25:8025')
   "
   ```

3. **Configure any service to send mail to MailHog**
   - SMTP host: `mailhog-demo` (inside Docker network) or `localhost` (from VM shell)
   - SMTP port: `1025`
   - No authentication required
   - No TLS required
   - Example: In Nextcloud → Settings → Basic settings → Send mode: SMTP → `localhost:1025`

4. **Watch live email arrive**
   - Keep the MailHog UI open in a tab
   - Trigger a Nextcloud password-reset email or Zammad notification
   - Watch it appear in MailHog in real time

> **Real email is already running:** `docker-mailserver` (`mail-demo`) provides full IMAP + SMTP on ports 143 and 587. Thunderbird and Nextcloud Mail (webmail) both connect to it. MailHog remains available on port 8025 as a catch-all for service notifications.

---

## Thunderbird — Desktop Email + Calendar + Contacts Client

> **What it is:** Mozilla Thunderbird is the **primary email client** for IT-Stack. It connects to **docker-mailserver** for IMAP/SMTP email, Nextcloud for calendar/contacts (CalDAV/CardDAV), and FreeIPA for the global address book. **The mail server is already deployed and running** — no extra setup required.

**Download:** https://www.thunderbird.net (free, available on Windows/macOS/Linux)

### Integration Map

| Thunderbird Feature | IT-Stack Service | Protocol | Lab Port | Status |
|--------------------|-----------------|----------|---------|--------|
| Send & receive email | docker-mailserver | IMAP/SMTP | **143 / 587** | ✅ Running |
| Webmail (browser) | Nextcloud Mail | IMAP | **8280** | ✅ Running |
| Calendar sync | Nextcloud (06) | CalDAV | 8280 | ✅ Running |
| Contact sync | Nextcloud (06) | CardDAV | 8280 | ✅ Running |
| Global address book | FreeIPA (01) | LDAP | 389 | ⚠️ Start separately |
| Modern auth (production) | Keycloak (02) | OAuth2 | 8180 | ⚠️ Production only |
| Email signing/encryption | FreeIPA CA (01) | S/MIME | — | ⚠️ Production only |

### Quick Setup: Email (docker-mailserver — already running ✅)

> The mail server is **already deployed** at `mail-demo` on the VM. No setup required.

In Thunderbird: **Edit → Account Settings → Add Mail Account**

```
Name:     John Doe
Email:    jdoe@itstack.local
Password: LabUser01!

Click "Configure Manually", then enter:

IMAP  →  4.154.17.25  port 143  None (no SSL)  Normal password
SMTP  →  4.154.17.25  port 587  None (no SSL)  Normal password
Username: jdoe@itstack.local  (full email address)
```

> ⚠️ **Lab note:** Security is set to **None** (plaintext). This is intentional for the lab environment. Production deployments use SSL/TLS on port 993 and STARTTLS on port 587.

**Available accounts:**

| Email address | Password | Inbox |
|--------------|----------|-------|
| `admin@itstack.local` | `Lab01Password!` | 5 messages pre-loaded |
| `jdoe@itstack.local` | `LabUser01!` | 2 messages pre-loaded |
| `jsmith@itstack.local` | `LabUser01!` | Empty |

### Quick Setup: Calendar + Contacts (Nextcloud — currently running)

**Install two Thunderbird add-ons first:**
1. Open Thunderbird → **Tools → Add-ons and Themes** → search **TbSync** → Install
2. Search **Provider for CalDAV & CardDAV** → Install → Restart Thunderbird

**Then:** Tools → TbSync → Add New Account → CalDAV & CardDAV → Manual

```
Server:    http://4.154.17.25:8280/remote.php/dav/
Username:  admin
Password:  Lab02Password!
```

Click Next → discover all calendars and address books → enable what you want → Save.

**Test:** Create an event in Nextcloud (http://4.154.17.25:8280 → Calendar) → within 30 seconds it appears in Thunderbird Calendar.

### Quick Setup: Global Address Book (FreeIPA LDAP)

> FreeIPA must be running for this. Start it with `bash ~/lab-phase1.sh --only-freeipa`

In Thunderbird: **Tools → Account Settings → Composition & Addressing → Use a different LDAP server → Edit Directories → Add**

```
Name:      IT-Stack Directory
Hostname:  4.154.17.25
Port:      389
Base DN:   cn=users,cn=accounts,dc=lab,dc=localhost
Bind DN:   uid=admin,cn=users,cn=accounts,dc=lab,dc=localhost
Password:  Lab01Password!
```

**Test:** Compose a new email → type `jdo` in the To: field → Thunderbird autocompletes `jdoe@itstack.local (John Doe)`.

### Things to try:

1. **Send email from Thunderbird** (jdoe→admin) → check admin inbox in Thunderbird or at http://4.154.17.25:8280 (Nextcloud Mail)
2. **Reply to a pre-loaded email in admin's inbox** — Thunderbird connects via IMAP port 143
3. **Check webmail in browser:** http://4.154.17.25:8280 → click ✉ envelope icon — same inbox, same messages
4. **Create a meeting in Thunderbird Calendar** → verify in Nextcloud Calendar at http://4.154.17.25:8280
5. **Configure Zammad email notifications** → all helpdesk alerts route to your Thunderbird inbox
6. **Check MailHog** at http://4.154.17.25:8025 — catches notification emails from Nextcloud/Mattermost/etc.

> **Two email surfaces for complete lab coverage:**
> - **Thunderbird (desktop)** → IMAP port 143, no SSL, connects to docker-mailserver directly
> - **Nextcloud Mail (browser)** → http://4.154.17.25:8280 → ✉ icon — same mailbox, accessible anywhere

> **Full guide:** See [23-thunderbird-integration.md](23-thunderbird-integration.md) for OAuth2, S/MIME certificates, enterprise autoconfig, and the complete holistic onboarding workflow.

---

## How to Test Integrations

### Email-Specific Test Suite (`test-email.sh`) — 47 tests

Dedicated test suite for the full email stack: docker-mailserver, Nextcloud Mail webmail, and MailHog.

```bash
ssh itstack@4.154.17.25

bash ~/test-email.sh                     # full suite — 47 tests
bash ~/test-email.sh --section imap      # IMAP auth + mailbox access (8 tests)
bash ~/test-email.sh --section smtp      # SMTP send + AUTH (7 tests)
bash ~/test-email.sh --section flow      # end-to-end send → deliver → IMAP verify (6 tests)
bash ~/test-email.sh --section nextcloud # Nextcloud Mail webmail (7 tests)
bash ~/test-email.sh --section mailhog   # MailHog catch-all (5 tests)
bash ~/test-email.sh --verbose           # all tests + debug output
```

**Expected: 47/47 PASS** (verified 2026-03-11). Each section maps to a manual step in [23-thunderbird-integration.md](23-thunderbird-integration.md).

---

### Method 1: Automated Test Suite (recommended)

The VM has pre-built test scripts for all 4 deployment phases. Each script runs health checks, functional tests, and integration verifications.

```bash
ssh itstack@4.154.17.25

# Run all phases (takes ~45 min)
nohup bash ~/lab-all.sh > ~/lab-all.log 2>&1 &
tail -f ~/lab-all.log

# Or run individual phases:
bash ~/lab-phase1.sh   # FreeIPA + Keycloak + PostgreSQL + Redis + Traefik
bash ~/lab-phase2.sh   # Nextcloud + Mattermost + Jitsi + iRedMail + Zammad
bash ~/lab-phase3.sh   # FreePBX + SuiteCRM + Odoo + OpenKM
bash ~/lab-phase4.sh   # Taiga + Snipe-IT + GLPI + Elasticsearch + Zabbix + Graylog
```

**Check results:**
```bash
# Pass/fail summary
grep -E '\[PASS\]|\[FAIL\]' ~/lab-all.log

# Count totals
grep -c '\[PASS\]' ~/lab-all.log
grep -c '\[FAIL\]' ~/lab-all.log

# Watch live progress
tail -f ~/lab-all.log
```

**Expected totals when complete:**

| Phase | Expected PASS | Covers |
|-------|--------------|--------|
| Phase 1 | 14/14 | Identity + DB + Proxy |
| Phase 2 | 20–25 | Collaboration + Email |
| Phase 3 | 14–16 | Business apps |
| Phase 4 | 20–25 | IT Management + Monitoring |
| **Total** | **~72–80** | **All 20 modules** |

---

### Method 2: Manual HTTP Health Checks

Quick sanity check — all services respond on their ports:

```bash
ssh itstack@4.154.17.25

# Run all health checks in 10 seconds
for port in 8025 8065 8069 8080 8180 8265 8280 8302 8303 8305; do
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:$port/)
  echo "Port $port → HTTP $code"
done
```

Expected output:
```
Port 8025 → HTTP 200   (MailHog)
Port 8065 → HTTP 200   (Mattermost API)
Port 8069 → HTTP 303   (Odoo redirect)
Port 8080 → HTTP 200   (Traefik dashboard)
Port 8180 → HTTP 302   (Keycloak → admin)
Port 8265 → HTTP 200   (Mattermost UI)
Port 8280 → HTTP 302   (Nextcloud → login)
Port 8302 → HTTP 200   (SuiteCRM)
Port 8303 → HTTP 303   (Odoo)
Port 8305 → HTTP 302   (Snipe-IT)
```

---

### Method 3: Integration-Specific Tests

**Test SSO (Keycloak → Nextcloud):**
```bash
# Get a Keycloak token
TOKEN=$(curl -s -X POST http://localhost:8180/realms/it-stack/protocol/openid-connect/token \
  -d "grant_type=password&client_id=nextcloud&client_secret=YOUR_SECRET&username=testuser&password=Test01!" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
echo "Token: ${TOKEN:0:50}..."

# Use token to call Nextcloud API
curl -H "Authorization: Bearer $TOKEN" http://localhost:8280/ocs/v1.php/cloud/user
```

**Test email flow (SMTP → MailHog):**
```bash
# Send email and verify it arrived
python3 -c "
import smtplib; from email.mime.text import MIMEText
msg = MIMEText('Integration test'); msg['Subject']='Test'; msg['From']='test@itstack.local'; msg['To']='inbox@itstack.local'
s = smtplib.SMTP('localhost',1025); s.send_message(msg); s.quit(); print('SENT')
"
# Check MailHog API
curl -s http://localhost:8025/api/v2/messages | python3 -c "import sys,json; msgs=json.load(sys.stdin); print(f'MailHog has {msgs[\"total\"]} message(s)')"
```

**Test CalDAV (Nextcloud calendar):**
```bash
# Verify CalDAV endpoint is accessible
curl -u admin:Lab02Password! \
  http://localhost:8280/remote.php/dav/calendars/admin/ \
  -w "\nHTTP Status: %{http_code}\n" -s -o /dev/null
# Expected: HTTP Status: 200 or 207
```

**Test LDAP (FreeIPA directory):**
```bash
# Requires ldap-utils installed on VM
docker exec freeipa-demo ldapsearch \
  -x -H ldap://localhost \
  -D "cn=Directory Manager" \
  -w Lab01Password! \
  -b "cn=users,cn=accounts,dc=lab,dc=localhost" \
  "(objectClass=person)" uid mail | grep "^uid:\|^mail:"
```

**Test PostgreSQL connectivity (for app databases):**
```bash
# Check all app databases exist
docker exec pg-demo psql -U postgres -c "\l" | grep -E "nextcloud|mattermost|keycloak|zammad"
```

---

### Method 4: The Integration Testing Checklist

Use the master checklist in [Integration Guide](../02-implementation/12-integration-guide.md#testing-checklist) which covers:

- **SSO:** login once → all services auto-authenticate
- **VoIP:** click-to-call, call logging, voicemail-to-email
- **Business process:** lead → customer → invoice → document
- **Project workflow:** story → sprint → time tracking → billing
- **IT operations:** new employee → account → email → phone → asset → ticket
- **Thunderbird client:** IMAP → calendar sync → contacts → LDAP autocomplete

---

## Check Test Suite Results

While exploring services, the automated test suite is running in the background on the VM. Check progress at any time:

```bash
# Quick summary
ssh itstack@4.154.17.25 "grep -cE '\[PASS\]' ~/lab-all.log; grep -cE '\[FAIL\]' ~/lab-all.log; grep '^>>' ~/lab-all.log | tail -3"

# Full pass/fail list
ssh itstack@4.154.17.25 "grep -E '\[PASS\]|\[FAIL\]' ~/lab-all.log"

# Live tail
ssh itstack@4.154.17.25 "tail -f ~/lab-all.log"

# FreeIPA image build status
ssh itstack@4.154.17.25 "tail -3 ~/freeipa-build.log"
```

**Expected results when complete:**
- Phase 1 (skip FreeIPA): 14/14 PASS
- Phase 2: 20–25 PASS (Zammad ~4, Nextcloud ~4, Mattermost ~3, Jitsi ~3, iRedMail ~3)
- Phase 3: 14–16 PASS
- Phase 4: 20–25 PASS
- FreeIPA (after image build): 4/4 PASS
- **Total: ~72–80 PASS across all phases**

---

## Post-Testing Cleanup

```bash
# Stop all running containers
ssh itstack@4.154.17.25 "docker stop \$(docker ps -q) 2>/dev/null; docker rm \$(docker ps -aq) 2>/dev/null; docker volume prune -f; echo Cleaned"

# Deallocate VM to stop Azure billing
az vm deallocate --resource-group rg-it-stack-phase1 --name lab-single --no-wait
```

---

*IT-Stack GUI Walkthrough Guide v1.0 — 2026-03-11*  
*Azure VM: 4.154.17.25 | All 20 services covered*
