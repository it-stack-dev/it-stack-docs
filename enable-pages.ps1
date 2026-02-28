$token = gh auth token
$headers = @{ Authorization = "Bearer $token"; Accept = "application/vnd.github.v3+json"; "Content-Type" = "application/json" }
$body = @{ build_type = "workflow" } | ConvertTo-Json
try {
    $r = Invoke-RestMethod "https://api.github.com/repos/it-stack-dev/it-stack-docs/pages" -Method POST -Headers $headers -Body $body
    Write-Host "Pages enabled: $($r.html_url)" -ForegroundColor Green
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    $msg  = $_.ErrorDetails.Message
    if ($code -eq 409) { Write-Host "Pages already enabled." -ForegroundColor Yellow }
    else { Write-Host "Error $code`: $msg" -ForegroundColor Red }
}
