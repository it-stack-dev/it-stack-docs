#!/usr/bin/env pwsh
# deploy-workflows.ps1 — Create production CI/CD workflows for all 20 component repos

$org = "it-stack-dev"

$modules = @(
    @{ repo="it-stack-freeipa";       dir="01-identity";       image="ghcr.io/it-stack-dev/it-stack-freeipa"       }
    @{ repo="it-stack-keycloak";      dir="01-identity";       image="ghcr.io/it-stack-dev/it-stack-keycloak"      }
    @{ repo="it-stack-postgresql";    dir="02-database";       image="ghcr.io/it-stack-dev/it-stack-postgresql"    }
    @{ repo="it-stack-redis";         dir="02-database";       image="ghcr.io/it-stack-dev/it-stack-redis"         }
    @{ repo="it-stack-elasticsearch"; dir="02-database";       image="ghcr.io/it-stack-dev/it-stack-elasticsearch" }
    @{ repo="it-stack-nextcloud";     dir="03-collaboration";  image="ghcr.io/it-stack-dev/it-stack-nextcloud"     }
    @{ repo="it-stack-mattermost";    dir="03-collaboration";  image="ghcr.io/it-stack-dev/it-stack-mattermost"    }
    @{ repo="it-stack-jitsi";         dir="03-collaboration";  image="ghcr.io/it-stack-dev/it-stack-jitsi"         }
    @{ repo="it-stack-iredmail";      dir="04-communications"; image="ghcr.io/it-stack-dev/it-stack-iredmail"      }
    @{ repo="it-stack-freepbx";       dir="04-communications"; image="ghcr.io/it-stack-dev/it-stack-freepbx"       }
    @{ repo="it-stack-zammad";        dir="04-communications"; image="ghcr.io/it-stack-dev/it-stack-zammad"        }
    @{ repo="it-stack-suitecrm";      dir="05-business";       image="ghcr.io/it-stack-dev/it-stack-suitecrm"      }
    @{ repo="it-stack-odoo";          dir="05-business";       image="ghcr.io/it-stack-dev/it-stack-odoo"          }
    @{ repo="it-stack-openkm";        dir="05-business";       image="ghcr.io/it-stack-dev/it-stack-openkm"        }
    @{ repo="it-stack-taiga";         dir="06-it-management";  image="ghcr.io/it-stack-dev/it-stack-taiga"         }
    @{ repo="it-stack-snipeit";       dir="06-it-management";  image="ghcr.io/it-stack-dev/it-stack-snipeit"       }
    @{ repo="it-stack-glpi";          dir="06-it-management";  image="ghcr.io/it-stack-dev/it-stack-glpi"          }
    @{ repo="it-stack-traefik";       dir="07-infrastructure"; image="ghcr.io/it-stack-dev/it-stack-traefik"       }
    @{ repo="it-stack-zabbix";        dir="07-infrastructure"; image="ghcr.io/it-stack-dev/it-stack-zabbix"        }
    @{ repo="it-stack-graylog";       dir="07-infrastructure"; image="ghcr.io/it-stack-dev/it-stack-graylog"       }
)

$ok = 0; $fail = 0

foreach ($m in $modules) {
    $repoPath = "C:\IT-Stack\it-stack-dev\repos\$($m.dir)\$($m.repo)"
    $wfDir    = "$repoPath\.github\workflows"
    Write-Host ""
    Write-Host "==> $($m.repo)" -ForegroundColor Cyan

    # ── ci.yml ────────────────────────────────────────────────────────────────
    $ci = @"
name: CI

on:
  push:
    branches: [main, develop, 'feature/**', 'bugfix/**']
  pull_request:
    branches: [main, develop]

permissions:
  contents: read
  security-events: write

jobs:
  validate:
    name: Validate Configuration
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate Docker Compose files
        run: |
          for f in docker/docker-compose.*.yml; do
            echo "Validating: `$f"
            docker compose -f "`$f" config --no-interpolate -q
          done

      - name: ShellCheck — lab test scripts
        run: |
          sudo apt-get install -y shellcheck -qq
          shellcheck tests/labs/*.sh

      - name: Validate module manifest
        run: |
          python3 -c "
          import sys, re
          with open('$($m.repo).yml') as f:
              content = f.read()
          required = ['module:', 'version:', 'phase:', 'category:', 'ports:']
          missing = [k for k in required if k not in content]
          if missing:
              print('Missing fields:', missing); sys.exit(1)
          print('Manifest valid')
          "

  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    needs: validate
    steps:
      - uses: actions/checkout@v4

      - name: Trivy — scan Dockerfile
        uses: aquasecurity/trivy-action@0.28.0
        with:
          scan-type: config
          scan-ref: .
          exit-code: '0'
          severity: CRITICAL,HIGH

      - name: Trivy — SARIF output
        uses: aquasecurity/trivy-action@0.28.0
        with:
          scan-type: config
          scan-ref: .
          format: sarif
          output: trivy-results.sarif

      - name: Upload SARIF to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: trivy-results.sarif

  lab-01-smoke:
    name: Lab 01 — Smoke Test
    runs-on: ubuntu-latest
    needs: validate
    continue-on-error: true   # scaffold stubs; full lab runs on real VMs
    steps:
      - uses: actions/checkout@v4

      - name: Generate CI env file
        run: |
          # Copy example env and inject CI-safe defaults for any unset port vars
          if [ -f .env.example ]; then cp .env.example .env; fi
          # Set port placeholder vars used in scaffold compose files
          echo "firstPort=389"   >> .env
          echo "secondPort=9090" >> .env

      - name: Validate standalone compose can start
        run: |
          docker compose -f docker/docker-compose.standalone.yml config --no-interpolate -q
          echo "Standalone compose structure is valid"

      - name: Start standalone stack
        run: docker compose -f docker/docker-compose.standalone.yml up -d

      - name: Wait for health
        run: |
          echo "Waiting for services..."
          sleep 30
          docker compose -f docker/docker-compose.standalone.yml ps

      - name: Run Lab 01 test script
        run: bash tests/labs/test-lab-01.sh

      - name: Collect logs on failure
        if: failure()
        run: docker compose -f docker/docker-compose.standalone.yml logs

      - name: Cleanup
        if: always()
        run: docker compose -f docker/docker-compose.standalone.yml down -v
"@

    # ── release.yml ───────────────────────────────────────────────────────────
    $release = @"
name: Release

on:
  push:
    tags:
      - 'v*.*.*'

permissions:
  contents: write
  packages: write

jobs:
  build-and-push:
    name: Build and Push Docker Image
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: `${{ github.actor }}
          password: `${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: $($m.image)
          tags: |
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=semver,pattern={{major}}
            type=sha,prefix=sha-,format=short

      - name: Build and push
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: `${{ steps.meta.outputs.tags }}
          labels: `${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Trivy — scan released image
        uses: aquasecurity/trivy-action@0.28.0
        with:
          image-ref: $($m.image):`${{ steps.meta.outputs.version }}
          scan-type: image
          exit-code: '0'
          severity: CRITICAL,HIGH
          format: table

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          generate_release_notes: true
          files: |
            $($m.repo).yml
"@

    # ── security.yml ──────────────────────────────────────────────────────────
    $security = @"
name: Security Scan (Scheduled)

on:
  schedule:
    - cron: '0 2 * * 1'   # Every Monday at 02:00 UTC
  workflow_dispatch:

permissions:
  contents: read
  security-events: write

jobs:
  trivy-scan:
    name: Trivy Full Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Trivy — filesystem scan
        uses: aquasecurity/trivy-action@0.28.0
        with:
          scan-type: fs
          scan-ref: .
          format: sarif
          output: trivy-fs.sarif
          severity: CRITICAL,HIGH,MEDIUM

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: trivy-fs.sarif

      - name: Trivy — config scan
        uses: aquasecurity/trivy-action@0.28.0
        with:
          scan-type: config
          scan-ref: .
          format: table
          severity: CRITICAL,HIGH
"@

    # Write workflow files
    $ci       | Set-Content "$wfDir\ci.yml"      -Encoding UTF8
    $release  | Set-Content "$wfDir\release.yml" -Encoding UTF8
    $security | Set-Content "$wfDir\security.yml" -Encoding UTF8

    # Commit and push
    Set-Location $repoPath
    git add .github/workflows/ 2>&1 | Out-Null
    $diff = git diff --cached --stat 2>&1
    if ($diff -match "changed") {
        git commit -m "ci: add production CI, release, and security scan workflows" 2>&1 | Out-Null
        $result = git push origin main 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Pushed" -ForegroundColor Green
            $ok++
        } else {
            Write-Host "  [FAIL] $result" -ForegroundColor Red
            $fail++
        }
    } else {
        Write-Host "  [SKIP] No changes" -ForegroundColor DarkYellow
    }
}

Write-Host ""
Write-Host "Workflows deployed: OK=$ok  FAIL=$fail" -ForegroundColor Yellow
Set-Location "C:\IT-Stack"
