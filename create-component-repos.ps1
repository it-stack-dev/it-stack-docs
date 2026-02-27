#!/usr/bin/env pwsh
# create-component-repos.ps1 — Create all 20 component repos in it-stack-dev org

$org = "it-stack-dev"

$modules = @(
    @{ name = "it-stack-freeipa";          desc = "FreeIPA LDAP/Kerberos identity provider — IT-Stack Module 01"; category = "01-identity" }
    @{ name = "it-stack-keycloak";         desc = "Keycloak OAuth2/OIDC/SAML SSO provider — IT-Stack Module 02"; category = "01-identity" }
    @{ name = "it-stack-postgresql";       desc = "PostgreSQL primary database layer — IT-Stack Module 03"; category = "02-database" }
    @{ name = "it-stack-redis";            desc = "Redis cache and session store — IT-Stack Module 04"; category = "02-database" }
    @{ name = "it-stack-elasticsearch";    desc = "Elasticsearch search and log indexing — IT-Stack Module 05"; category = "02-database" }
    @{ name = "it-stack-nextcloud";        desc = "Nextcloud file sync, calendar, and office suite — IT-Stack Module 06"; category = "03-collaboration" }
    @{ name = "it-stack-mattermost";       desc = "Mattermost team messaging and collaboration — IT-Stack Module 07"; category = "03-collaboration" }
    @{ name = "it-stack-jitsi";            desc = "Jitsi video conferencing — IT-Stack Module 08"; category = "03-collaboration" }
    @{ name = "it-stack-iredmail";         desc = "iRedMail email server (SMTP/IMAP) — IT-Stack Module 09"; category = "04-communications" }
    @{ name = "it-stack-freepbx";          desc = "FreePBX/Asterisk VoIP PBX — IT-Stack Module 10"; category = "04-communications" }
    @{ name = "it-stack-zammad";           desc = "Zammad help desk and ticketing — IT-Stack Module 11"; category = "04-communications" }
    @{ name = "it-stack-suitecrm";         desc = "SuiteCRM customer relationship management — IT-Stack Module 12"; category = "05-business" }
    @{ name = "it-stack-odoo";             desc = "Odoo ERP and business management — IT-Stack Module 13"; category = "05-business" }
    @{ name = "it-stack-openkm";           desc = "OpenKM document management system — IT-Stack Module 14"; category = "05-business" }
    @{ name = "it-stack-taiga";            desc = "Taiga agile project management — IT-Stack Module 15"; category = "06-it-management" }
    @{ name = "it-stack-snipeit";          desc = "Snipe-IT IT asset management — IT-Stack Module 16"; category = "06-it-management" }
    @{ name = "it-stack-glpi";             desc = "GLPI IT service management and CMDB — IT-Stack Module 17"; category = "06-it-management" }
    @{ name = "it-stack-traefik";          desc = "Traefik reverse proxy and load balancer — IT-Stack Module 18"; category = "07-infrastructure" }
    @{ name = "it-stack-zabbix";           desc = "Zabbix infrastructure monitoring — IT-Stack Module 19"; category = "07-infrastructure" }
    @{ name = "it-stack-graylog";          desc = "Graylog centralized log management — IT-Stack Module 20"; category = "07-infrastructure" }
)

Write-Host "Creating 20 component repos in $org..." -ForegroundColor Cyan
$ok = 0; $fail = 0

foreach ($m in $modules) {
    $result = gh repo create "$org/$($m.name)" --public --description $m.desc 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK]   $($m.name)" -ForegroundColor Green
        $ok++
    } elseif ($result -match "already exists") {
        Write-Host "  [SKIP] $($m.name) (already exists)" -ForegroundColor DarkYellow
        $ok++
    } else {
        Write-Host "  [FAIL] $($m.name): $result" -ForegroundColor Red
        $fail++
    }
    Start-Sleep -Milliseconds 300
}

Write-Host ""
Write-Host "Done. OK=$ok FAIL=$fail" -ForegroundColor Yellow
Write-Host ""
Write-Host "Apply labels to all component repos next." -ForegroundColor Cyan
