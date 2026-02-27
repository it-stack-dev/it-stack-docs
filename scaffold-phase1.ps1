#!/usr/bin/env pwsh
# scaffold-phase1.ps1 — Clone and scaffold all Phase 1 modules
# Phase 1: FreeIPA, Keycloak, PostgreSQL, Redis, Traefik

$org     = "it-stack-dev"
$base    = "C:\IT-Stack\it-stack-dev\repos"
$here    = "C:\IT-Stack"

$phase1 = @(
    @{ module = "freeipa";    dir = "01-identity"    }
    @{ module = "keycloak";   dir = "01-identity"    }
    @{ module = "postgresql"; dir = "02-database"    }
    @{ module = "redis";      dir = "02-database"    }
    @{ module = "traefik";    dir = "07-infrastructure" }
)

Write-Host "=== Phase 1 Module Scaffolding ===" -ForegroundColor Cyan
Write-Host ""

foreach ($m in $phase1) {
    $repo    = "it-stack-$($m.module)"
    $destDir = "$base\$($m.dir)\$repo"

    Write-Host "── $repo ──────────────────────────────────" -ForegroundColor Cyan

    # Clone if not already cloned
    if (!(Test-Path $destDir)) {
        Write-Host "  Cloning $repo..." -ForegroundColor Gray
        git clone "https://github.com/$org/$repo.git" $destDir 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [FAIL] Could not clone $repo" -ForegroundColor Red
            continue
        }
        Write-Host "  [OK] Cloned to $destDir" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] Already cloned at $destDir" -ForegroundColor DarkYellow
    }

    # Run scaffold
    Write-Host "  Scaffolding..." -ForegroundColor Gray
    & "$here\scaffold-module.ps1" -Module $m.module -ReposBase $base -Push

    Write-Host ""
}

Write-Host "=== Phase 1 scaffolding complete ===" -ForegroundColor Green
