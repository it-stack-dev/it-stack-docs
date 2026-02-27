#!/usr/bin/env pwsh
# setup-dev-workspace.ps1 — Create C:\IT-Stack\it-stack-dev\ local development workspace

$base = "C:\IT-Stack\it-stack-dev"

Write-Host "Creating IT-Stack dev workspace at $base..." -ForegroundColor Cyan

# Core workspace directories
$dirs = @(
    # Repo categories
    "$base\repos\meta",
    "$base\repos\01-identity",
    "$base\repos\02-database",
    "$base\repos\03-collaboration",
    "$base\repos\04-communications",
    "$base\repos\05-business",
    "$base\repos\06-it-management",
    "$base\repos\07-infrastructure",

    # Work areas
    "$base\workspaces",
    "$base\lab-environments\tier-1-lab",
    "$base\lab-environments\tier-1-school",
    "$base\lab-environments\tier-2-department",
    "$base\lab-environments\tier-3-enterprise",

    # Deployment configs
    "$base\deployments\local",
    "$base\deployments\dev",
    "$base\deployments\staging",
    "$base\deployments\production",

    # Configuration
    "$base\configs\global",
    "$base\configs\modules",
    "$base\configs\environments",
    "$base\configs\secrets",       # Git-ignored

    # Scripts
    "$base\scripts\setup",
    "$base\scripts\github",
    "$base\scripts\operations",
    "$base\scripts\testing",
    "$base\scripts\deployment",

    # Logs
    "$base\logs"
)

foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Write-Host "  [OK] $dir" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Directory structure created." -ForegroundColor Green

# Create .gitignore for dev workspace
$gitignore = @"
# Secrets - NEVER commit
configs/secrets/
*.key
*.pem
*.crt
*.p12
*.vault
*.vault.yml
*-vault.yaml
.env
.env.*

# Terraform
**/.terraform/
*.tfstate
*.tfstate.backup
*.tfvars
!example.tfvars

# Logs
logs/
*.log

# OS & editor
.DS_Store
Thumbs.db
desktop.ini
.vscode/settings.json
*.swp
*~

# Docker volumes (if mounted locally)
volumes/

# Ansible
*.retry
"@
$gitignore | Set-Content "$base\.gitignore"
Write-Host "  [OK] .gitignore" -ForegroundColor DarkGray

Write-Host ""
Write-Host "Done! Dev workspace ready at: $base" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next: git init and clone meta repos" -ForegroundColor Cyan
