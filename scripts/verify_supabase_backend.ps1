param(
    [string]$SqlFile = 'supabase/verification/verify_flowfit_backend.sql',
    [switch]$ValidateOnly,
    [switch]$Linked,
    [switch]$Local,
    [string]$DbUrl = '',
    [ValidateSet('table', 'json', 'csv')]
    [string]$Output = 'table',
    [switch]$RequireAllPass,
    [string]$OutFile = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath

function Resolve-VerificationSqlPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'SqlFile is required.'
    }

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    return Join-Path $repoRoot $Path
}

function Assert-ReadOnlyVerificationSql {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Supabase backend verification SQL file does not exist: $Path"
    }

    $content = Get-Content -Raw -LiteralPath $Path
    $mutatingPattern = '(?im)^\s*(create|alter|drop|delete|insert|update|truncate|grant|revoke|comment|begin|commit)\b'
    if ($content -match $mutatingPattern) {
        throw 'Supabase backend verification SQL must stay read-only.'
    }

    if (-not $content.Contains('flowfit_backend_verification')) {
        throw 'Supabase backend verification SQL must expose the flowfit_backend_verification result CTE.'
    }

    return $content
}

function Resolve-TargetCount {
    $count = 0
    if ($Linked) { $count++ }
    if ($Local) { $count++ }
    if (-not [string]::IsNullOrWhiteSpace($DbUrl)) { $count++ }
    return $count
}

function Resolve-RepoOutputPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ''
    }

    $fullPath = if ([System.IO.Path]::IsPathRooted($Path)) {
        [System.IO.Path]::GetFullPath($Path)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
    }

    $repoFullPath = [System.IO.Path]::GetFullPath($repoRoot)
    $repoPrefix = $repoFullPath.TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    ) + [System.IO.Path]::DirectorySeparatorChar

    if (
        $fullPath -ne $repoFullPath -and
        -not $fullPath.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)
    ) {
        throw "OutFile must stay inside the repository: $Path"
    }

    return $fullPath
}

function Convert-CommandOutputToText {
    param([object[]]$OutputLines)

    if ($null -eq $OutputLines) {
        return ''
    }

    return ($OutputLines | ForEach-Object {
        if ($_ -is [System.Management.Automation.ErrorRecord]) {
            $_.ToString()
        } else {
            [string]$_
        }
    }) -join [System.Environment]::NewLine
}

function Resolve-JsonPayloadFromCommandOutput {
    param([Parameter(Mandatory = $true)][string]$Text)

    $trimmedText = $Text.Trim()
    if ($trimmedText.StartsWith('{') -or $trimmedText.StartsWith('[')) {
        return $trimmedText
    }

    $lines = $Text -split "`r?`n"
    for ($index = 0; $index -lt $lines.Count; $index++) {
        $candidate = ($lines[$index..($lines.Count - 1)] -join [System.Environment]::NewLine).Trim()
        if (-not ($candidate.StartsWith('{') -or $candidate.StartsWith('['))) {
            continue
        }

        try {
            $null = $candidate | ConvertFrom-Json -ErrorAction Stop
            return $candidate
        } catch {
            continue
        }
    }

    return $trimmedText
}

function Assert-AllBackendChecksPassed {
    param([Parameter(Mandatory = $true)][string]$JsonText)

    $jsonPayload = Resolve-JsonPayloadFromCommandOutput -Text $JsonText

    try {
        $parsed = $jsonPayload | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw 'Supabase backend verification output was not valid JSON; use -Output json with -RequireAllPass.'
    }

    if ($parsed -is [System.Array]) {
        $rows = @($parsed)
    } elseif ($parsed.PSObject.Properties.Name -contains 'rows') {
        $rows = @($parsed.rows)
    } else {
        $rows = @($parsed)
    }

    $statusRows = @(
        $rows | Where-Object {
            $_.PSObject.Properties.Name -contains 'status'
        }
    )

    if ($statusRows.Count -eq 0) {
        throw 'Supabase backend verification output did not include status rows.'
    }

    $failures = @(
        $statusRows | Where-Object {
            "$($_.status)".ToLowerInvariant() -ne 'pass'
        }
    )

    if ($failures.Count -gt 0) {
        $details = $failures | ForEach-Object {
            $checkName = if ($_.PSObject.Properties.Name -contains 'check_name') {
                $_.check_name
            } else {
                'unnamed check'
            }
            $detail = if ($_.PSObject.Properties.Name -contains 'detail') {
                $_.detail
            } else {
                ''
            }

            if ([string]::IsNullOrWhiteSpace($detail)) {
                "$checkName=$($_.status)"
            } else {
                "$checkName=$($_.status): $detail"
            }
        }
        throw "Supabase backend verification returned non-pass checks: $($details -join '; ')"
    }

    Write-Host "SUPABASE_BACKEND_VERIFICATION_ALL_PASS ($($statusRows.Count) checks)"
}

$resolvedSqlFile = Resolve-VerificationSqlPath -Path $SqlFile
$null = Assert-ReadOnlyVerificationSql -Path $resolvedSqlFile
Write-Host "Validated read-only Supabase backend verification SQL: $resolvedSqlFile"

if ($ValidateOnly) {
    Write-Host 'SUPABASE_BACKEND_VERIFICATION_SQL_OK'
    return
}

if ((Resolve-TargetCount) -ne 1) {
    throw 'Choose exactly one target: -Linked, -Local, or -DbUrl <percent-encoded-postgres-url>. Use -ValidateOnly for static validation only.'
}

if ($RequireAllPass -and $Output -ne 'json') {
    throw 'Use -Output json with -RequireAllPass so backend verification statuses can be parsed.'
}

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    throw 'npx is required to run supabase@latest. Install Node.js/npm or run the SQL through Supabase MCP execute_sql or the dashboard SQL editor.'
}

$cliSqlFile = $resolvedSqlFile
try {
    $relativeSqlFile = [System.IO.Path]::GetRelativePath($repoRoot, $resolvedSqlFile)
    if (
        -not $relativeSqlFile.StartsWith('..') -and
        -not [System.IO.Path]::IsPathRooted($relativeSqlFile)
    ) {
        $cliSqlFile = $relativeSqlFile -replace '\\', '/'
    }
} catch {
    $cliSqlFile = $resolvedSqlFile
}

$commandArgs = @(
    '-y',
    'supabase@latest',
    'db',
    'query',
    '--file',
    $cliSqlFile,
    '--output',
    $Output
)

if ($Linked) {
    $commandArgs += '--linked'
} elseif ($Local) {
    $commandArgs += '--local'
} else {
    $commandArgs += @('--db-url', $DbUrl)
}

Push-Location $repoRoot
try {
    $commandOutput = & npx @commandArgs 2>&1
    $exitCode = $LASTEXITCODE
} finally {
    Pop-Location
}

$commandOutputText = Convert-CommandOutputToText -OutputLines $commandOutput
if (-not [string]::IsNullOrWhiteSpace($OutFile)) {
    $resolvedOutFile = Resolve-RepoOutputPath -Path $OutFile
    $outDirectory = Split-Path -Parent $resolvedOutFile
    if (-not [string]::IsNullOrWhiteSpace($outDirectory)) {
        New-Item -ItemType Directory -Force -Path $outDirectory | Out-Null
    }
    Set-Content -LiteralPath $resolvedOutFile -Value $commandOutputText -Encoding utf8
    Write-Host "Supabase backend verification evidence written: $resolvedOutFile"
}

if (-not [string]::IsNullOrWhiteSpace($commandOutputText)) {
    Write-Host $commandOutputText
}

if ($exitCode -ne 0) {
    throw 'Supabase backend verification query failed.'
}

if ($RequireAllPass) {
    Assert-AllBackendChecksPassed -JsonText $commandOutputText
}

Write-Host 'SUPABASE_BACKEND_VERIFICATION_RUN_OK'
