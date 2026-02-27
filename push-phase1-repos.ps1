#!/usr/bin/env pwsh
# push-phase1-repos.ps1 — Init, commit, and push all 5 Phase 1 scaffolded repos to GitHub

$org = "it-stack-dev"

$modules = @(
    @{ Repo = "it-stack-freeipa";    Dir = "C:\IT-Stack\it-stack-dev\repos\01-identity" }
    @{ Repo = "it-stack-keycloak";   Dir = "C:\IT-Stack\it-stack-dev\repos\01-identity" }
    @{ Repo = "it-stack-postgresql"; Dir = "C:\IT-Stack\it-stack-dev\repos\02-database" }
    @{ Repo = "it-stack-redis";      Dir = "C:\IT-Stack\it-stack-dev\repos\02-database" }
    @{ Repo = "it-stack-traefik";    Dir = "C:\IT-Stack\it-stack-dev\repos\07-infrastructure" }
)

foreach ($m in $modules) {
    $path = Join-Path $m.Dir $m.Repo
    Write-Host ""
    Write-Host "==> $($m.Repo)" -ForegroundColor Cyan
    Set-Location $path

    # Init git
    git init -b main 2>&1 | Out-Null

    # Set remote
    git remote remove origin 2>&1 | Out-Null
    git remote add origin "https://github.com/$org/$($m.Repo).git"

    # Stage all
    git add -A

    # Commit
    git commit -m "feat: initial scaffold — standard IT-Stack module structure" 2>&1 | Out-Null

    # Force push (repo was created with auto-README)
    $result = git push --force origin main 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Pushed to github.com/$org/$($m.Repo)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $result" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Yellow
