#!/usr/bin/env pwsh
Set-Location "C:\IT-Stack"
New-Item -ItemType Directory docs/architecture, docs/deployment, docs/labs, docs/project, docs/contributing -Force | Out-Null
git mv docs/enterprise-stack-complete-v2.md        docs/architecture/overview.md
git mv docs/integration-guide-complete.md          docs/architecture/integrations.md
git mv docs/lab-deployment-plan.md                 docs/deployment/lab-deployment.md
git mv docs/enterprise-it-stack-deployment.md      docs/deployment/enterprise-reference.md
git mv docs/LAB_MANUAL_STRUCTURE.md                docs/labs/overview.md
git mv docs/enterprise-it-lab-manual.md            docs/labs/part1-network-os.md
git mv docs/enterprise-it-lab-manual-part2.md      docs/labs/part2-identity-database.md
git mv docs/enterprise-it-lab-manual-part3.md      docs/labs/part3-collaboration.md
git mv docs/enterprise-it-lab-manual-part4.md      docs/labs/part4-communications.md
git mv docs/enterprise-lab-manual-part5.md         docs/labs/part5-business-management.md
git mv docs/MASTER-INDEX.md                        docs/project/master-index.md
git mv docs/IT-STACK-GITHUB-GUIDE.md               docs/project/github-guide.md
git mv docs/IT-STACK-TODO.md                       docs/project/todo.md
git mv docs/PROJECT-FRAMEWORK-TEMPLATE.md          docs/contributing/framework-template.md
Write-Host "All moves complete. Exit: $LASTEXITCODE" -ForegroundColor Green
