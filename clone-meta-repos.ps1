#!/usr/bin/env pwsh
# clone-meta-repos.ps1 — Clone all 6 meta repos into C:\it-stack-dev\repos\meta\

$meta = "C:\it-stack-dev\repos\meta"
$org  = "it-stack-dev"

$repos = @(
    "it-stack-docs",
    "it-stack-installer",
    "it-stack-testing",
    "it-stack-ansible",
    "it-stack-terraform",
    "it-stack-helm"
)

Write-Host "Cloning meta repos into $meta..." -ForegroundColor Cyan
Set-Location $meta

foreach ($repo in $repos) {
    if (Test-Path "$meta\$repo") {
        Write-Host "  [SKIP] $repo (already exists)" -ForegroundColor DarkYellow
    } else {
        Write-Host "  Cloning $repo..." -ForegroundColor Gray
        git clone "https://github.com/$org/$repo.git" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK]   $repo" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] $repo" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "Repos cloned to: $meta" -ForegroundColor Yellow
Get-ChildItem $meta -Directory | Select-Object Name | Format-Table -HideTableHeaders
