#!/usr/bin/env pwsh
# add-gitattributes.ps1 — Add .gitattributes to all scaffolded component repos

$gitattributes = @"
# Git line ending normalization for IT-Stack repos
* text=auto eol=lf

*.md        text eol=lf
*.yml       text eol=lf
*.yaml      text eol=lf
*.json      text eol=lf
*.sh        text eol=lf
*.ps1       text eol=lf
*.py        text eol=lf
*.js        text eol=lf
*.ts        text eol=lf
*.xml       text eol=lf
*.conf      text eol=lf
*.env       text eol=lf
Makefile    text eol=lf
Dockerfile  text eol=lf

*.png       binary
*.jpg       binary
*.jpeg      binary
*.gif       binary
*.ico       binary
*.pdf       binary
*.zip       binary
*.tar.gz    binary
*.key       binary
*.p12       binary
*.pfx       binary
"@

$modules = @(
    @{ Repo = "it-stack-freeipa";    Dir = "C:\IT-Stack\it-stack-dev\repos\01-identity" }
    @{ Repo = "it-stack-keycloak";   Dir = "C:\IT-Stack\it-stack-dev\repos\01-identity" }
    @{ Repo = "it-stack-postgresql"; Dir = "C:\IT-Stack\it-stack-dev\repos\02-database" }
    @{ Repo = "it-stack-redis";      Dir = "C:\IT-Stack\it-stack-dev\repos\02-database" }
    @{ Repo = "it-stack-traefik";    Dir = "C:\IT-Stack\it-stack-dev\repos\07-infrastructure" }
)

foreach ($m in $modules) {
    $path = Join-Path $m.Dir $m.Repo
    Set-Location $path
    $gitattributes | Set-Content ".gitattributes" -Encoding UTF8
    git add .gitattributes
    git commit -m "chore: add .gitattributes for consistent LF line endings"
    $result = git push origin main 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] $($m.Repo)" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $($m.Repo): $result" -ForegroundColor Red
    }
}

Write-Host "Done." -ForegroundColor Yellow
