# Enterprise Open-Source IT Infrastructure Lab
# Complete Deployment Manual - Part 3: Application Services
**Educational Lab Manual with Complete CLI Instructions**

---

**Part 3 Contents:**
- Exercise 7: Nextcloud Collaboration Platform (Complete)
- Exercise 8: Mattermost Team Chat (Complete)
- Exercise 9: Jitsi Video Conferencing (Complete)
- Exercise 10: Email Server with iRedMail (Complete)
- Exercise 11: Traefik Reverse Proxy (Complete)
- Exercise 12: Zammad Help Desk System (Complete)
- Exercise 13: SSO Integration & Testing (Complete)
- Exercise 14: Basic Monitoring Setup (Complete)
- Final Testing and Verification
- Comprehensive Troubleshooting Guide
- Complete Command Reference

---

## Exercise 7: Nextcloud Collaboration Platform

### Understanding Nextcloud

**What is Nextcloud?**

Nextcloud is a self-hosted productivity platform that provides:
- **File storage and sync** (like Dropbox, Google Drive)
- **Collaborative editing** (like Google Docs)
- **Calendar and contacts** (like Google Calendar)
- **Video calls** (like Zoom, Google Meet)
- **Task management** (like Trello)
- **Notes** (like Evernote)
- **Email client** (webmail interface)

**Why Nextcloud?**

- **Data sovereignty**: Your data stays on your servers
- **Privacy**: No third-party access to files
- **Customizable**: 300+ apps available
- **Enterprise-ready**: Used by governments and large corporations
- **Open-source**: No licensing costs
- **Active development**: Monthly releases

**Nextcloud Architecture:**

```
┌──────────────────────────────────────────┐
│         User's Browser/Mobile App        │
└────────────────┬─────────────────────────┘
                 │
      ┌──────────▼───────────┐
      │   Nginx Web Server   │  (Serves PHP application)
      └──────────┬───────────┘
                 │
      ┌──────────▼───────────┐
      │   PHP-FPM Process    │  (Executes Nextcloud code)
      └──────────┬───────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
    ▼            ▼            ▼
┌────────┐  ┌────────┐  ┌────────┐
│Postgres│  │ Redis  │  │  Files │
│Database│  │ Cache  │  │/Storage│
└────────┘  └────────┘  └────────┘
```

**Real-World Use:**
- German government uses Nextcloud for 500,000+ users
- Universities deploy for student collaboration
- Businesses use instead of Microsoft 365/Google Workspace
- Our stack: 50-500 user capacity

**Time Required:** 3-4 hours

---

### Task 7.1: Install Prerequisites on LAB-APP1

**Server:** LAB-APP1 (10.0.50.13)

**Why this server?**
- Dedicated to user-facing applications
- Separates app logic from database/identity services
- Can scale horizontally (add more app servers)

---

#### Step 1: SSH to LAB-APP1

```bash
ssh labadmin@10.0.50.13
```

---

#### Step 2: Install Nginx Web Server

```bash
sudo apt update
sudo apt install -y nginx
```

**Verify installation:**

```bash
nginx -v
```

Expected output:
```
nginx version: nginx/1.24.0 (Ubuntu)
```

**Check service:**

```bash
sudo systemctl status nginx
```

**Test default page:**

```bash
curl http://localhost
```

Should return HTML (default Nginx page)

---

#### Step 3: Install PHP and Extensions

**Nextcloud requires PHP 8.3 with many extensions:**

```bash
sudo apt install -y \
  php8.3-fpm \
  php8.3-cli \
  php8.3-common \
  php8.3-curl \
  php8.3-gd \
  php8.3-mbstring \
  php8.3-xml \
  php8.3-zip \
  php8.3-bcmath \
  php8.3-intl \
  php8.3-bz2 \
  php8.3-gmp \
  php8.3-imagick \
  php8.3-pgsql \
  php8.3-redis \
  php8.3-apcu \
  unzip
```

**Understanding PHP extensions:**

| Extension | Purpose |
|-----------|---------|
| php8.3-fpm | FastCGI Process Manager (runs PHP) |
| php8.3-curl | HTTP requests to external APIs |
| php8.3-gd | Image manipulation (thumbnails) |
| php8.3-mbstring | Multi-byte string handling (Unicode) |
| php8.3-xml | XML parsing |
| php8.3-zip | Archive handling |
| php8.3-bcmath | Arbitrary precision math |
| php8.3-intl | Internationalization |
| php8.3-imagick | Advanced image processing |
| php8.3-pgsql | PostgreSQL database driver |
| php8.3-redis | Redis caching driver |
| php8.3-apcu | In-process cache |

**Verify PHP:**

```bash
php -v
```

Expected output:
```
PHP 8.3.2 (cli) (built: Jan 16 2024 16:40:08) (NTS)
```

---

#### Step 4: Configure PHP for Nextcloud

**Edit PHP-FPM configuration:**

```bash
sudo nano /etc/php/8.3/fpm/php.ini
```

**Find and modify these settings:**

```ini
# Memory and upload limits
memory_limit = 512M
upload_max_filesize = 10G
post_max_size = 10G
max_execution_time = 3600
max_input_time = 3600

# File uploads
file_uploads = On

# Timezone (adjust for your location)
date.timezone = America/Toronto

# OPcache (performance)
opcache.enable = 1
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 16
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 60
opcache.save_comments = 1
```

**Understanding key settings:**

| Setting | Value | Explanation |
|---------|-------|-------------|
| memory_limit | 512M | Max RAM per PHP request |
| upload_max_filesize | 10G | Max single file upload size |
| post_max_size | 10G | Max total POST data |
| max_execution_time | 3600 | Script can run 1 hour (large uploads) |
| opcache.memory_consumption | 256 | RAM for compiled PHP code cache |

**Save and exit**

---

**Edit PHP-FPM pool configuration:**

```bash
sudo nano /etc/php/8.3/fpm/pool.d/www.conf
```

**Find and modify:**

```ini
# Process manager
pm = dynamic
pm.max_children = 120
pm.start_servers = 12
pm.min_spare_servers = 6
pm.max_spare_servers = 18
pm.max_requests = 500

# Environment variables
env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
```

**Understanding pm (process manager):**
- **pm.max_children** = Max PHP worker processes
- **pm.start_servers** = Initial workers on start
- **pm.min/max_spare** = Keep this many idle workers ready
- **pm.max_requests** = Recycle worker after X requests (prevents memory leaks)

**Restart PHP-FPM:**

```bash
sudo systemctl restart php8.3-fpm
```

**Verify running:**

```bash
sudo systemctl status php8.3-fpm
```

---

### Task 7.2: Download and Install Nextcloud

---

#### Step 1: Download Nextcloud

```bash
cd /tmp
wget https://download.nextcloud.com/server/releases/nextcloud-28.0.0.tar.bz2
```

**Verify download:**

```bash
ls -lh nextcloud-28.0.0.tar.bz2
```

Expected: ~150 MB

**Optional: Verify checksum**

```bash
wget https://download.nextcloud.com/server/releases/nextcloud-28.0.0.tar.bz2.sha256
sha256sum -c nextcloud-28.0.0.tar.bz2.sha256
```

Should output: `nextcloud-28.0.0.tar.bz2: OK`

---

#### Step 2: Extract to Web Directory

```bash
# Extract
sudo tar -xjf nextcloud-28.0.0.tar.bz2 -C /var/www/

# Set ownership (www-data is Nginx/PHP user)
sudo chown -R www-data:www-data /var/www/nextcloud
```

**Verify structure:**

```bash
ls -la /var/www/nextcloud/
```

Expected directories:
```
drwxr-xr-x  apps/       # Applications
drwxr-xr-x  config/     # Configuration
drwxr-xr-x  core/       # Core code
drwxr-xr-x  data/       # User data (will be created)
-rw-r--r--  index.php   # Entry point
```

---

#### Step 3: Configure Nginx for Nextcloud

**Create Nginx virtual host:**

```bash
sudo nano /etc/nginx/sites-available/nextcloud
```

**Add this configuration:**

```nginx
upstream php-handler {
    server unix:/run/php/php8.3-fpm.sock;
}

# Redirect HTTP to HTTPS (when behind Traefik)
server {
    listen 80;
    listen [::]:80;
    server_name cloud.lab.local;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;" always;
    add_header Referrer-Policy "no-referrer" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Download-Options "noopen" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Permitted-Cross-Domain-Policies "none" always;
    add_header X-Robots-Tag "noindex, nofollow" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Path to Nextcloud
    root /var/www/nextcloud;
    
    # Specify how to handle directories
    index index.php index.html /index.php$request_uri;
    
    # Default charset
    charset utf-8;
    
    # Disable gzip to avoid potential security issues
    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 256;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;
    
    # Pagespeed is not supported
    pagespeed off;
    
    # Disable access to hidden files
    location ~ /\.(?!well-known) {
        deny all;
    }
    
    # Make sure special directories are accessible
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }
    
    # .well-known URLs for Let's Encrypt, CalDAV, CardDAV
    location ^~ /.well-known {
        location = /.well-known/carddav { return 301 /remote.php/dav/; }
        location = /.well-known/caldav  { return 301 /remote.php/dav/; }
        location /.well-known/acme-challenge    { try_files $uri $uri/ =404; }
        location /.well-known/pki-validation    { try_files $uri $uri/ =404; }
        return 301 /index.php$request_uri;
    }
    
    # Deny access to certain paths
    location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)(?:$|/)  { return 404; }
    location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console)                { return 404; }
    
    # Main PHP handler
    location ~ \.php(?:$|/) {
        # Required for legacy support
        rewrite ^/(?!index|remote|public|cron|core\/ajax\/update|status|ocs\/v[12]|updater\/.+|oc[ms]-provider\/.+|.+\/richdocumentscode\/proxy) /index.php$request_uri;
        
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        set $path_info $fastcgi_path_info;
        
        try_files $fastcgi_script_name =404;
        
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $path_info;
        fastcgi_param HTTPS on;
        
        fastcgi_param modHeadersAvailable true;
        fastcgi_param front_controller_active true;
        fastcgi_pass php-handler;
        
        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;
        
        fastcgi_read_timeout 3600;
        fastcgi_send_timeout 3600;
        fastcgi_connect_timeout 3600;
        
        fastcgi_max_temp_file_size 0;
    }
    
    # Serve static files directly
    location ~ \.(?:css|js|svg|gif|png|jpg|ico|wasm|tflite|map|ogg|flac)$ {
        try_files $uri /index.php$request_uri;
        add_header Cache-Control "public, max-age=15778463, immutable";
        access_log off;
        
        location ~ \.wasm$ {
            default_type application/wasm;
        }
    }
    
    location ~ \.woff2?$ {
        try_files $uri /index.php$request_uri;
        expires 7d;
        access_log off;
    }
    
    # Rule borrowed from .htaccess
    location /remote {
        return 301 /remote.php$request_uri;
    }
    
    location / {
        try_files $uri $uri/ /index.php$request_uri;
    }
}
```

**Understanding key Nginx directives:**

| Directive | Explanation |
|-----------|-------------|
| upstream php-handler | Defines PHP-FPM backend |
| root /var/www/nextcloud | Document root |
| index index.php | Default file |
| location ~ \.php | Route PHP files to PHP-FPM |
| fastcgi_pass php-handler | Send to PHP processor |
| try_files | Check file exists before processing |

**Save and exit**

---

**Enable site:**

```bash
# Create symbolic link to enable
sudo ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t
```

Expected output:
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**Restart Nginx:**

```bash
sudo systemctl restart nginx
```

---

### Task 7.3: Install Nextcloud via Command Line

**Nextcloud can be installed via:**
1. Web installer (GUI)
2. Command line (occ tool) ← We'll use this (more reproducible)

---

#### Step 1: Run Nextcloud Installer

```bash
cd /var/www/nextcloud

sudo -u www-data php occ maintenance:install \
  --database="pgsql" \
  --database-name="nextcloud" \
  --database-host="10.0.50.12:5432" \
  --database-user="nextcloud" \
  --database-pass="NextcloudDB2024!" \
  --admin-user="admin" \
  --admin-pass="LabAdmin2024!" \
  --data-dir="/var/www/nextcloud/data"
```

**Understanding parameters:**

| Parameter | Value | Explanation |
|-----------|-------|-------------|
| --database | pgsql | PostgreSQL database type |
| --database-name | nextcloud | Database created in Exercise 5 |
| --database-host | 10.0.50.12:5432 | LAB-DB1 PostgreSQL server |
| --database-user | nextcloud | DB user created earlier |
| --database-pass | NextcloudDB2024! | Database password |
| --admin-user | admin | Nextcloud admin username |
| --admin-pass | LabAdmin2024! | Nextcloud admin password |
| --data-dir | /var/www/nextcloud/data | Where user files stored |

**Installation takes 1-2 minutes.** Output:

```
Nextcloud was successfully installed
```

---

#### Step 2: Configure Trusted Domains

**Nextcloud only accepts requests from configured domains (security feature).**

```bash
# Add cloud.lab.local
sudo -u www-data php occ config:system:set trusted_domains 0 --value=cloud.lab.local

# Add IP address (for direct access)
sudo -u www-data php occ config:system:set trusted_domains 1 --value=10.0.50.13

# Add proxy hostname (for Traefik)
sudo -u www-data php occ config:system:set trusted_domains 2 --value=lab-proxy1.lab.local
```

**Verify trusted domains:**

```bash
sudo -u www-data php occ config:system:get trusted_domains
```

Expected output:
```
0: cloud.lab.local
1: 10.0.50.13
2: lab-proxy1.lab.local
```

---

#### Step 3: Configure Redis Caching

**Connect Nextcloud to Redis on LAB-DB1:**

```bash
# Configure Redis server
sudo -u www-data php occ config:system:set redis host --value=10.0.50.12
sudo -u www-data php occ config:system:set redis port --value=6379
sudo -u www-data php occ config:system:set redis password --value='LabRedis2024!'

# Set cache backends
sudo -u www-data php occ config:system:set memcache.local --value='\\OC\\Memcache\\APCu'
sudo -u www-data php occ config:system:set memcache.distributed --value='\\OC\\Memcache\\Redis'
sudo -u www-data php occ config:system:set memcache.locking --value='\\OC\\Memcache\\Redis'
```

**Understanding caching:**

| Cache Type | Backend | Purpose |
|------------|---------|---------|
| memcache.local | APCu | Per-process cache (PHP opcode) |
| memcache.distributed | Redis | Shared cache across servers |
| memcache.locking | Redis | File locking coordination |

---

#### Step 4: Configure Background Jobs

**Nextcloud needs periodic tasks (like Dropbox sync):**

```bash
# Set background jobs to cron
sudo -u www-data php occ background:cron
```

**Add cron job:**

```bash
# Edit crontab for www-data user
sudo crontab -u www-data -e
```

**Add this line:**

```
*/5  *  *  *  * php -f /var/www/nextcloud/cron.php
```

**Understanding:**
- `*/5` = Every 5 minutes
- Run PHP script that triggers background tasks
- Essential for:
  - File sync
  - Notifications
  - Calendar reminders
  - Trash cleanup

**Save and exit**

---

#### Step 5: Set Phone Region

**For proper phone number validation:**

```bash
sudo -u www-data php occ config:system:set default_phone_region --value="CA"
```

Change `CA` to your country code (US, GB, etc.)

---

#### Step 6: Optimize Database

```bash
# Add database indexes for performance
sudo -u www-data php occ db:add-missing-indices

# Convert database to big int (for large file IDs)
sudo -u www-data php occ db:convert-filecache-bigint
```

---

### Task 7.4: Test Nextcloud Access

---

#### Step 1: Test from Server

```bash
curl -I http://localhost
```

Expected output:
```
HTTP/1.1 200 OK
Server: nginx
Content-Type: text/html; charset=utf-8
...
```

**200 OK** = Working! ✓

---

#### Step 2: Test from Your Laptop

**Add to your laptop's /etc/hosts:**

```
10.0.50.13  cloud.lab.local
```

**Open browser:**

Navigate to: `http://cloud.lab.local`

**Login screen should appear!**

**Login:**
- Username: `admin`
- Password: `LabAdmin2024!`

**You should see Nextcloud Dashboard!**

---

### Task 7.5: Configure LDAP Integration

**Connect Nextcloud to FreeIPA users.**

---

#### Step 1: Install LDAP App

```bash
sudo -u www-data php occ app:install user_ldap
```

---

#### Step 2: Configure LDAP Connection

```bash
# Create LDAP configuration
sudo -u www-data php occ ldap:create-empty-config

# This creates config "s01" (server 01)

# Configure LDAP server
sudo -u www-data php occ ldap:set-config s01 ldapHost "ldap://10.0.50.11"
sudo -u www-data php occ ldap:set-config s01 ldapPort 389

# Bind DN (service account)
sudo -u www-data php occ ldap:set-config s01 ldapAgentName "uid=admin,cn=users,cn=accounts,dc=lab,dc=local"
sudo -u www-data php occ ldap:set-config s01 ldapAgentPassword "LabAdmin2024!"

# Base DN (where to search)
sudo -u www-data php occ ldap:set-config s01 ldapBase "cn=accounts,dc=lab,dc=local"

# User filter (which users to import)
sudo -u www-data php occ ldap:set-config s01 ldapUserFilter "(&(objectClass=person)(uid=*))"

# Login filter (how to authenticate)
sudo -u www-data php occ ldap:set-config s01 ldapLoginFilter "(&(objectClass=person)(uid=%uid))"

# Attributes
sudo -u www-data php occ ldap:set-config s01 ldapEmailAttribute "mail"
sudo -u www-data php occ ldap:set-config s01 ldapUserDisplayName "displayName"
sudo -u www-data php occ ldap:set-config s01 ldapGroupDisplayName "cn"

# Group filter
sudo -u www-data php occ ldap:set-config s01 ldapGroupFilter "(&(objectClass=groupOfNames)(cn=*))"

# Enable configuration
sudo -u www-data php occ ldap:set-config s01 ldapConfigurationActive 1
```

---

#### Step 3: Test LDAP Connection

```bash
# Test connectivity
sudo -u www-data php occ ldap:test-config s01
```

Expected output:
```
The configuration is valid and the connection could be established!
```

**Test user import:**

```bash
# Count users available
sudo -u www-data php occ ldap:check-user guard1
```

Expected:
```
guard1 maps to LDAP UID: <ldap-unique-id>
```

---

#### Step 4: Synchronize LDAP Users

**Manual sync:**

```bash
sudo -u www-data php occ user:list
```

Should show:
- admin (local)
- guard1, guard2, manager1, office1, itadmin1 (from LDAP)

**Configure automatic sync:**

```bash
# Background job will sync hourly
sudo -u www-data php occ background:job:list | grep LDAP
```

---

### Task 7.6: Install Essential Apps

**Install productivity apps:**

```bash
# Calendar
sudo -u www-data php occ app:install calendar

# Contacts
sudo -u www-data php occ app:install contacts

# Tasks
sudo -u www-data php occ app:install tasks

# Kanban board
sudo -u www-data php occ app:install deck

# Forms (surveys)
sudo -u www-data php occ app:install forms

# Talk (video chat)
sudo -u www-data php occ app:install spreed

# PDF viewer
sudo -u www-data php occ app:install files_pdfviewer

# Text editor
sudo -u www-data php occ app:install files_texteditor

# Two-factor authentication
sudo -u www-data php occ app:install twofactor_totp

# Admin audit log
sudo -u www-data php occ app:install admin_audit
```

**Verify installed apps:**

```bash
sudo -u www-data php occ app:list
```

---

### Task 7.7: Install Collabora Online (Office Suite)

**Nextcloud Office powered by Collabora:**

---

#### Step 1: Install Docker (if not already)

```bash
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker
```

---

#### Step 2: Run Collabora Container

```bash
sudo docker run -d \
  --name collabora \
  --restart unless-stopped \
  -p 9980:9980 \
  -e "domain=cloud\\.lab\\.local" \
  -e "username=admin" \
  -e "password=LabCollabora2024!" \
  -e "extra_params=--o:ssl.enable=false --o:ssl.termination=true" \
  collabora/code
```

**Understanding parameters:**
- `-p 9980:9980` = Expose on port 9980
- `domain=cloud\\.lab\\.local` = Nextcloud domain (escaped dots)
- `extra_params` = Disable SSL (Traefik handles it)

**Check container:**

```bash
sudo docker ps | grep collabora
```

---

#### Step 3: Install Nextcloud Office App

```bash
# Install app
sudo -u www-data php occ app:install richdocuments

# Configure Collabora URL
sudo -u www-data php occ config:app:set richdocuments wopi_url --value="http://10.0.50.13:9980"
```

**Now you can edit Word/Excel/PowerPoint files in browser!**

---

**✅ Nextcloud Installation Complete!**

**What you've accomplished:**
- ✅ Installed Nginx and PHP-FPM
- ✅ Configured PHP for optimal performance
- ✅ Installed Nextcloud 28
- ✅ Connected to PostgreSQL database
- ✅ Configured Redis caching
- ✅ Integrated with FreeIPA LDAP
- ✅ Installed 11+ productivity apps
- ✅ Set up Collabora Office
- ✅ Configured background jobs

**Test from browser:**
1. Login with LDAP user (guard1 / password from FreeIPA)
2. Upload a file
3. Create a document
4. Check calendar
5. Start a video call via Talk

---

## Exercise 8: Mattermost Team Chat

### Understanding Mattermost

**What is Mattermost?**

Mattermost is an open-source team communication platform (Slack alternative) that provides:
- **Team chat** - Channels, direct messages, group chats
- **File sharing** - Share documents, images, videos
- **Search** - Full-text search across all messages
- **Integrations** - Webhooks, bots, slash commands
- **Mobile apps** - iOS and Android
- **Voice/Video calls** - Built-in calling (or Jitsi integration)

**Why Mattermost?**

- **Data sovereignty**: Messages stay on your servers
- **No per-user pricing**: Unlimited users for free
- **Enterprise features**: Compliance, AD/LDAP, SAML
- **Developer-friendly**: Open API, extensive integrations
- **High performance**: Handles millions of messages

**Mattermost Architecture:**

```
┌──────────────────────────────────┐
│   Users (Web, Desktop, Mobile)   │
└────────────┬─────────────────────┘
             │
      ┌──────▼───────┐
      │   Nginx      │
      └──────┬───────┘
             │
      ┌──────▼───────┐
      │  Mattermost  │  (Go binary)
      │   Server     │
      └──────┬───────┘
             │
    ┌────────┼────────┐
    │                 │
    ▼                 ▼
┌──────────┐    ┌──────────┐
│PostgreSQL│    │  Redis   │
│ Database │    │  Cache   │
└──────────┘    └──────────┘
```

**Real-World Use:**
- US Department of Defense uses Mattermost
- Samsung, SAP, Uber use for internal chat
- 800+ contributors to open-source project
- Our stack: 50-500 users capacity

**Time Required:** 1-2 hours

---

### Task 8.1: Install Mattermost

**Server:** LAB-APP1 (10.0.50.13) - Same as Nextcloud

**Why same server?**
- Both are user-facing apps
- Share Nginx reverse proxy
- Can later scale by moving to separate servers

---

#### Step 1: Download Mattermost

**SSH to LAB-APP1:**

```bash
ssh labadmin@10.0.50.13
```

**Download latest version:**

```bash
cd /tmp
wget https://releases.mattermost.com/9.3.0/mattermost-9.3.0-linux-amd64.tar.gz
```

**Verify download:**

```bash
ls -lh mattermost-9.3.0-linux-amd64.tar.gz
```

Expected: ~200 MB

---

#### Step 2: Extract and Install

```bash
# Extract
tar -xzf mattermost-9.3.0-linux-amd64.tar.gz

# Move to /opt
sudo mv mattermost /opt/

# Create data directory
sudo mkdir /opt/mattermost/data

# Create system user
sudo useradd --system --user-group mattermost

# Set ownership
sudo chown -R mattermost:mattermost /opt/mattermost

# Set permissions
sudo chmod -R g+w /opt/mattermost
```

**Verify structure:**

```bash
ls -la /opt/mattermost/
```

Expected directories:
```
drwxr-xr-x bin/        # Mattermost binary
drwxr-xr-x config/     # Configuration
drwxr-xr-x data/       # User uploads
drwxr-xr-x i18n/       # Translations
drwxr-xr-x plugins/    # Plugins
```

---

### Task 8.2: Configure Mattermost

---

#### Step 1: Edit Configuration File

```bash
sudo nano /opt/mattermost/config/config.json
```

**This is a JSON file. Find and modify these sections:**

**Service Settings (lines ~10-50):**

```json
"ServiceSettings": {
    "SiteURL": "http://chat.lab.local",
    "ListenAddress": ":8065",
    "ConnectionSecurity": "",
    "TLSCertFile": "",
    "TLSKeyFile": "",
    "TLSMinVer": "1.2",
    "TLSStrictTransport": false,
    "TLSStrictTransportMaxAge": 63072000,
    "TLSOverwriteCiphers": [],
    "UseLetsEncrypt": false,
    "Forward80To443": false,
    "ReadTimeout": 300,
    "WriteTimeout": 300,
    "IdleTimeout": 60,
    "MaximumLoginAttempts": 10,
    "EnableDeveloper": false,
    "EnableInsecureOutgoingConnections": false
},
```

**Key changes:**
- `"SiteURL": "http://chat.lab.local"` ← Your domain
- `"ListenAddress": ":8065"` ← Internal port

---

**SQL Settings (lines ~100-120):**

```json
"SqlSettings": {
    "DriverName": "postgres",
    "DataSource": "postgres://mattermost:MattermostDB2024!@10.0.50.12:5432/mattermost?sslmode=disable&connect_timeout=10",
    "DataSourceReplicas": [],
    "DataSourceSearchReplicas": [],
    "MaxIdleConns": 20,
    "ConnMaxLifetimeMilliseconds": 3600000,
    "MaxOpenConns": 300,
    "Trace": false,
    "QueryTimeout": 30
},
```

**Critical:**
- `"DriverName": "postgres"`
- `"DataSource"`: Connection string to LAB-DB1
  - Format: `postgres://user:password@host:port/database`

---

**File Settings (lines ~140-160):**

```json
"FileSettings": {
    "EnableFileAttachments": true,
    "EnableMobileUpload": true,
    "EnableMobileDownload": true,
    "MaxFileSize": 104857600,
    "DriverName": "local",
    "Directory": "/opt/mattermost/data",
    "EnablePublicLink": true,
    "PublicLinkSalt": "randomstringhere",
    "InitialFont": "luximbi.ttf",
    "AmazonS3AccessKeyId": "",
    "AmazonS3SecretAccessKey": ""
},
```

**Key settings:**
- `"MaxFileSize": 104857600` = 100 MB max upload
- `"Directory": "/opt/mattermost/data"` = Where files stored

---

**Email Settings (lines ~200-240):**

```json
"EmailSettings": {
    "EnableSignUpWithEmail": true,
    "EnableSignInWithEmail": true,
    "EnableSignInWithUsername": true,
    "SendEmailNotifications": true,
    "UseChannelInEmailNotifications": false,
    "RequireEmailVerification": false,
    "FeedbackName": "Mattermost",
    "FeedbackEmail": "noreply@lab.local",
    "FeedbackOrganization": "Lab Company",
    "SMTPUsername": "noreply@lab.local",
    "SMTPPassword": "",
    "SMTPServer": "10.0.50.14",
    "SMTPPort": "587",
    "SMTPServerTimeout": 10,
    "ConnectionSecurity": "",
    "SendPushNotifications": true,
    "PushNotificationServer": "https://push.mattermost.com"
},
```

**Note:** Email server (10.0.50.14) will be configured in Exercise 10

---

**Team Settings (lines ~300-320):**

```json
"TeamSettings": {
    "SiteName": "Lab Chat",
    "MaxUsersPerTeam": 500,
    "EnableTeamCreation": true,
    "EnableUserCreation": true,
    "EnableOpenServer": false,
    "RestrictCreationToDomains": "lab.local",
    "RestrictTeamNames": true,
    "EnableCustomBrand": false,
    "CustomBrandText": "",
    "CustomDescriptionText": "",
    "RestrictDirectMessage": "any",
    "MaxChannelsPerTeam": 2000,
    "MaxNotificationsPerChannel": 1000000,
    "TeammateNameDisplay": "username"
},
```

**Save and exit**

**Important:** JSON is strict about commas and quotes. A single typo breaks the file!

**Validate JSON:**

```bash
# Check for syntax errors
sudo -u mattermost /opt/mattermost/bin/mattermost config validate
```

Expected:
```
The configuration is valid.
```

---

### Task 8.3: Create Systemd Service

```bash
sudo nano /etc/systemd/system/mattermost.service
```

**Add:**

```ini
[Unit]
Description=Mattermost
After=network.target postgresql.service
Requires=network.target

[Service]
Type=notify
ExecStart=/opt/mattermost/bin/mattermost
TimeoutStartSec=3600
KillMode=mixed
Restart=always
RestartSec=10
WorkingDirectory=/opt/mattermost
User=mattermost
Group=mattermost
LimitNOFILE=49152

[Install]
WantedBy=multi-user.target
```

**Save and exit**

---

### Task 8.4: Start Mattermost

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable auto-start
sudo systemctl enable mattermost

# Start service
sudo systemctl start mattermost
```

**Check status:**

```bash
sudo systemctl status mattermost
```

**Monitor startup:**

```bash
sudo journalctl -u mattermost -f
```

**Watch for:**

```
{"level":"info","msg":"Server is listening on :8065"}
{"level":"info","msg":"Pinging SQL","master":true}
```

**Press Ctrl+C to exit**

**Verify listening:**

```bash
sudo ss -tlnp | grep 8065
```

Expected:
```
LISTEN 0  128  *:8065  *:*  users:(("mattermost",pid=12345))
```

---

### Task 8.5: Configure Nginx for Mattermost

```bash
sudo nano /etc/nginx/sites-available/mattermost
```

**Add:**

```nginx
upstream mattermost_backend {
    server 127.0.0.1:8065;
    keepalive 32;
}

proxy_cache_path /var/cache/nginx/mattermost levels=1:2 keys_zone=mattermost_cache:10m max_size=3g inactive=120m use_temp_path=off;

server {
    listen 8065;
    server_name chat.lab.local;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    location ~ /api/v[0-9]+/(users/)?websocket$ {
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        client_max_body_size 50M;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Frame-Options SAMEORIGIN;
        proxy_buffers 256 16k;
        proxy_buffer_size 16k;
        client_body_timeout 60;
        send_timeout 300;
        lingering_timeout 5;
        proxy_connect_timeout 90;
        proxy_send_timeout 300;
        proxy_read_timeout 90s;
        proxy_http_version 1.1;
        proxy_pass http://mattermost_backend;
    }
    
    location / {
        client_max_body_size 50M;
        proxy_set_header Connection "";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Frame-Options SAMEORIGIN;
        proxy_buffers 256 16k;
        proxy_buffer_size 16k;
        proxy_read_timeout 600s;
        proxy_cache mattermost_cache;
        proxy_cache_revalidate on;
        proxy_cache_min_uses 2;
        proxy_cache_use_stale timeout;
        proxy_cache_lock on;
        proxy_http_version 1.1;
        proxy_pass http://mattermost_backend;
    }
}
```

**Key features:**
- WebSocket support for real-time messaging
- File upload limit: 50 MB
- Response caching for performance
- Security headers

**Save and exit**

**Enable site:**

```bash
sudo ln -s /etc/nginx/sites-available/mattermost /etc/nginx/sites-enabled/

# Test config
sudo nginx -t

# Reload
sudo systemctl reload nginx
```

---

### Task 8.6: Test Mattermost Access

**From your laptop:**

Add to `/etc/hosts`:
```
10.0.50.13  chat.lab.local
```

**Open browser:**

Navigate to: `http://chat.lab.local:8065`

**You should see:**

```
Create your first team

Choose your team name:
[Enter team name]

Let's create your first Mattermost workspace.
Team Name helps people find the right workspace.

[Continue]
```

**Create admin account:**
1. Team name: `General`
2. Username: `admin`
3. Email: `admin@lab.local`
4. Password: `LabAdmin2024!`

**Dashboard appears!**

---

### Task 8.7: Configure LDAP Integration

**In Mattermost System Console:**

1. **Navigate to:** System Console (three dots menu → System Console)
2. **Authentication → LDAP**
3. **Enable LDAP:** ON
4. **Fill in:**

| Setting | Value |
|---------|-------|
| LDAP Server | 10.0.50.11 |
| LDAP Port | 389 |
| Connection Security | None (internal network) |
| Bind Username | uid=admin,cn=users,cn=accounts,dc=lab,dc=local |
| Bind Password | LabAdmin2024! |
| Base DN | cn=users,cn=accounts,dc=lab,dc=local |
| User Filter | (objectClass=person) |
| ID Attribute | ipaUniqueID |
| Username Attribute | uid |
| Email Attribute | mail |
| First Name Attribute | givenName |
| Last Name Attribute | sn |
| Nickname Attribute | displayName |

5. **Test Connection** - Should succeed
6. **Save**

**Synchronize Users:**

In System Console → Users:
- Click "Synchronize Now"
- Users from FreeIPA imported!

---

**✅ Mattermost Installation Complete!**

**Test:**
1. Logout from admin account
2. Login with LDAP user (guard1)
3. Create channel
4. Send message
5. Upload file

---

## Exercise 9: Jitsi Meet Video Conferencing

[Continuing with same detail level for Jitsi, iRedMail, Traefik, Zammad, and integration testing...]

**Due to response length limits, would you like me to:**
1. Continue with full detail for remaining exercises (Jitsi, Mail, Traefik, Zammad, Integration) in a Part 4?
2. Or provide a summarized version of the remaining exercises?

**What we've completed in Part 3 so far:**
- ✅ Exercise 7: Nextcloud (COMPLETE - 40+ commands, LDAP integration, apps)
- ✅ Exercise 8: Mattermost (COMPLETE - Installation, config, LDAP)
- 📝 Exercises 9-14: Ready to expand with same detail

Let me know how you'd like me to proceed!
