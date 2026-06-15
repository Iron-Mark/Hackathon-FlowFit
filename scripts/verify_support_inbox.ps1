param(
    [string]$SupportEmail = '',
    [string]$EnvFile = '',
    [string]$OutFile = 'build/support-inbox-verification.json',
    [switch]$ConfirmedInbound,
    [string]$EvidenceNote = '',
    [switch]$SkipDns
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Import-ReleaseEnvFile {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }

    $envPath = if ([System.IO.Path]::IsPathRooted($Path)) {
        $Path
    } else {
        Join-Path $repoRoot $Path
    }

    if (-not (Test-Path -LiteralPath $envPath)) {
        throw "Release env file does not exist: $envPath"
    }

    foreach ($line in Get-Content -LiteralPath $envPath) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) {
            continue
        }
        if ($trimmed -notmatch '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$') {
            throw "Invalid release env file line: $line"
        }

        $name = $matches[1]
        $value = $matches[2].Trim()
        if (
            ($value.StartsWith("'") -and $value.EndsWith("'")) -or
            ($value.StartsWith('"') -and $value.EndsWith('"'))
        ) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        [Environment]::SetEnvironmentVariable($name, $value, 'Process')
    }
}

function Assert-SupportEmail {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $normalized = $Value.Trim()
    if (
        [string]::IsNullOrWhiteSpace($normalized) -or
        $normalized -notmatch '^[A-Za-z0-9._+-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$' -or
        $normalized -match '["''<>?&/%\x00-\x1F\x7F]' -or
        $normalized -match 'YOUR_|REPLACE_WITH|<your-|example\.|invalid\.|\.test$|localhost'
    ) {
        throw "$Name must be a real plain support mailbox, for example support@flowfit.com."
    }

    return $normalized
}

function Get-RepoRelativePath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.Path]::GetRelativePath($repoRoot, $Path).Replace('\', '/')
}

function Find-SupportEmailOccurrences {
    param(
        [Parameter(Mandatory = $true)][string]$Email,
        [Parameter(Mandatory = $true)][string]$DefaultEmail
    )

    $paths = @(
        'web/privacy.html',
        'web/account-deletion.html',
        'lib/core/config/flowfit_runtime_config.dart',
        'lib/screens/profile/settings/general/privacy_policy_screen.dart',
        'lib/screens/profile/settings/general/help_support_screen.dart',
        'lib/screens/profile/settings/general/about_us_screen.dart'
    )

    $records = @()
    foreach ($path in $paths) {
        $fullPath = Join-Path $repoRoot $path
        if (-not (Test-Path -LiteralPath $fullPath)) {
            continue
        }

        $content = [string](Get-Content -Raw -LiteralPath $fullPath)
        $hasConfiguredSupportEmail = $content.Contains($Email)
        $hasDefaultReplacementToken = $content.Contains($DefaultEmail)
        $hasMailto = $content.Contains("mailto:$Email") -or $content.Contains("mailto:$DefaultEmail")

        $records += [pscustomobject]@{
            path = $path
            hasConfiguredSupportEmail = $hasConfiguredSupportEmail
            hasDefaultReplacementToken = $hasDefaultReplacementToken
            hasMailto = $hasMailto
        }
    }

    return $records
}

function Resolve-MxEvidence {
    param([Parameter(Mandatory = $true)][string]$Domain)

    if ($SkipDns) {
        return [pscustomobject]@{
            checked = $false
            status = 'skipped'
            records = @()
            detail = 'DNS MX lookup skipped by -SkipDns.'
        }
    }

    if (Get-Command Resolve-DnsName -ErrorAction SilentlyContinue) {
        try {
            $records = @(Resolve-DnsName -Name $Domain -Type MX -ErrorAction Stop | ForEach-Object {
                [pscustomobject]@{
                    exchange = [string]$_.NameExchange
                    preference = [int]$_.Preference
                }
            })
            return [pscustomobject]@{
                checked = $true
                status = if ($records.Count -gt 0) { 'pass' } else { 'fail' }
                records = $records
                detail = if ($records.Count -gt 0) { "MX records found for $Domain." } else { "No MX records found for $Domain." }
            }
        } catch {
            return [pscustomobject]@{
                checked = $true
                status = 'fail'
                records = @()
                detail = $_.Exception.Message
            }
        }
    }

    if (Get-Command nslookup -ErrorAction SilentlyContinue) {
        $output = & nslookup -type=mx $Domain 2>&1
        $text = ($output | Out-String).Trim()
        $hasMx = $text -match 'mail exchanger|MX preference|exchanger ='
        return [pscustomobject]@{
            checked = $true
            status = if ($hasMx) { 'pass' } else { 'unknown' }
            records = @()
            detail = if ($hasMx) { "nslookup reported MX records for $Domain." } else { "nslookup did not return parseable MX records for $Domain." }
        }
    }

    return [pscustomobject]@{
        checked = $false
        status = 'unknown'
        records = @()
        detail = 'No DNS lookup tool is available.'
    }
}

Push-Location $repoRoot
try {
    Import-ReleaseEnvFile -Path $EnvFile

    if ([string]::IsNullOrWhiteSpace($SupportEmail)) {
        $SupportEmail = [Environment]::GetEnvironmentVariable('FLOWFIT_SUPPORT_EMAIL')
    }
    if ([string]::IsNullOrWhiteSpace($SupportEmail)) {
        $SupportEmail = 'support@flowfit.com'
    }

    $supportEmail = Assert-SupportEmail -Name 'SupportEmail' -Value $SupportEmail
    if ($ConfirmedInbound -and [string]::IsNullOrWhiteSpace($EvidenceNote)) {
        throw 'EvidenceNote is required with -ConfirmedInbound. Include the date/source of the external test email receipt.'
    }

    $defaultSupportEmail = 'support@flowfit.com'
    $domain = ($supportEmail -split '@', 2)[1]
    $occurrences = Find-SupportEmailOccurrences -Email $supportEmail -DefaultEmail $defaultSupportEmail
    $mx = Resolve-MxEvidence -Domain $domain
    $confirmedAt = if ($ConfirmedInbound) { (Get-Date).ToUniversalTime().ToString('o') } else { $null }
    $releaseVerifiedEnvValue = if ($ConfirmedInbound) { 'true' } else { 'false' }

    $summary = if ($ConfirmedInbound) {
        "ready-for-release-variable-dns-$($mx.status)"
    } else {
        'manual-inbound-confirmation-required'
    }

    $evidence = [pscustomobject]@{
        generatedAt = (Get-Date).ToUniversalTime().ToString('o')
        supportEmail = $supportEmail
        domain = $domain
        confirmedInbound = [bool]$ConfirmedInbound
        confirmedAt = $confirmedAt
        evidenceNote = $EvidenceNote
        releaseVariable = [pscustomobject]@{
            name = 'FLOWFIT_SUPPORT_EMAIL_VERIFIED'
            valueWhenReady = $releaseVerifiedEnvValue
        }
        sourceOccurrences = $occurrences
        dnsMx = $mx
        summary = $summary
        nextStep = if ($ConfirmedInbound) {
            "Set FLOWFIT_SUPPORT_EMAIL_VERIFIED=true with scripts/configure_github_release_variables.ps1 -SupportEmailVerified. DNS MX status recorded as $($mx.status)."
        } else {
            'Send an external test email to the support inbox, confirm receipt, then rerun this script with -ConfirmedInbound.'
        }
    }

    $outPath = if ([System.IO.Path]::IsPathRooted($OutFile)) {
        [System.IO.Path]::GetFullPath($OutFile)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutFile))
    }
    $relativeOut = [System.IO.Path]::GetRelativePath($repoRoot, $outPath)
    if ($relativeOut.StartsWith('..') -or [System.IO.Path]::IsPathRooted($relativeOut)) {
        throw "OutFile must stay inside the repository: $OutFile"
    }

    $parent = Split-Path -Parent $outPath
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    $evidence | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $outPath -Encoding utf8NoBOM

    Write-Host "Support inbox evidence written: $(Get-RepoRelativePath $outPath)"
    Write-Host "Support email: $supportEmail"
    Write-Host "Inbound confirmation: $([bool]$ConfirmedInbound)"
    Write-Host "DNS MX status: $($mx.status)"
    if (-not $ConfirmedInbound) {
        Write-Host 'Manual inbound-mail confirmation is still required before setting FLOWFIT_SUPPORT_EMAIL_VERIFIED=true.'
    }
    Write-Host 'SUPPORT_INBOX_EVIDENCE_WRITTEN'

    if (-not $ConfirmedInbound) {
        exit 2
    }
} finally {
    Pop-Location
}
