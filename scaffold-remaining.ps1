#!/usr/bin/env pwsh
# scaffold-remaining.ps1 — Clone, scaffold, and push Phases 2-4 component repos (15 remaining modules)

$org      = "it-stack-dev"
$reposBase = "C:\IT-Stack\it-stack-dev\repos"

# Phase 2-4 modules: category dir, repo name, module name for scaffold script
$modules = @(
    # Phase 2: Collaboration
    @{ cat="03-collaboration";   repo="it-stack-nextcloud";     mod="nextcloud"     }
    @{ cat="03-collaboration";   repo="it-stack-mattermost";    mod="mattermost"    }
    @{ cat="03-collaboration";   repo="it-stack-jitsi";         mod="jitsi"         }
    @{ cat="04-communications";  repo="it-stack-iredmail";      mod="iredmail"      }
    @{ cat="04-communications";  repo="it-stack-zammad";        mod="zammad"        }
    # Phase 3: Back Office
    @{ cat="04-communications";  repo="it-stack-freepbx";       mod="freepbx"       }
    @{ cat="05-business";        repo="it-stack-suitecrm";      mod="suitecrm"      }
    @{ cat="05-business";        repo="it-stack-odoo";          mod="odoo"          }
    @{ cat="05-business";        repo="it-stack-openkm";        mod="openkm"        }
    # Phase 4: IT Management
    @{ cat="06-it-management";   repo="it-stack-taiga";         mod="taiga"         }
    @{ cat="06-it-management";   repo="it-stack-snipeit";       mod="snipeit"       }
    @{ cat="06-it-management";   repo="it-stack-glpi";          mod="glpi"          }
    @{ cat="02-database";        repo="it-stack-elasticsearch";  mod="elasticsearch" }
    @{ cat="07-infrastructure";  repo="it-stack-zabbix";        mod="zabbix"        }
    @{ cat="07-infrastructure";  repo="it-stack-graylog";       mod="graylog"       }
)

$ok = 0; $fail = 0

foreach ($m in $modules) {
    $destDir = "$reposBase\$($m.cat)\$($m.repo)"
    Write-Host ""
    Write-Host "==> $($m.repo)" -ForegroundColor Cyan

    # Clone if not already present
    if (!(Test-Path $destDir)) {
        New-Item -ItemType Directory -Path (Split-Path $destDir) -Force | Out-Null
        git clone "https://github.com/$org/$($m.repo).git" $destDir 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [FAIL] Clone failed" -ForegroundColor Red
            $fail++; continue
        }
        Write-Host "  Cloned" -ForegroundColor DarkGray
    } else {
        Write-Host "  Already exists locally" -ForegroundColor DarkYellow
    }

    # Scaffold
    & "C:\IT-Stack\scaffold-module.ps1" -Module $m.mod -ReposBase $reposBase
    Write-Host "  Scaffolded" -ForegroundColor DarkGray

    # Commit and push (remote already configured by clone)
    Set-Location $destDir

    # Add .gitattributes for consistent LF line endings
    @"
# Git line ending normalization
* text=auto eol=lf
*.md text eol=lf
*.yml text eol=lf
*.yaml text eol=lf
*.json text eol=lf
*.sh text eol=lf
*.ps1 text eol=lf
*.py text eol=lf
*.xml text eol=lf
Makefile text eol=lf
Dockerfile text eol=lf
*.png binary
*.jpg binary
*.zip binary
*.tar.gz binary
*.key binary
*.p12 binary
"@ | Set-Content ".gitattributes" -Encoding UTF8

    git add -A 2>&1 | Out-Null
    git commit -m "feat: initial scaffold — standard IT-Stack module structure" 2>&1 | Out-Null
    $result = git push --force origin main 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Pushed" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "  [FAIL] Push: $result" -ForegroundColor Red
        $fail++
    }
}

Write-Host ""
Write-Host "Scaffolded and pushed: OK=$ok  FAIL=$fail" -ForegroundColor Yellow
