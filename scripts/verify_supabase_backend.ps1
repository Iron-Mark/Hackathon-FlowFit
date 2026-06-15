param(
    [string]$SqlFile = 'supabase/verification/verify_flowfit_backend.sql',
    [switch]$ValidateOnly,
    [switch]$Linked,
    [switch]$Local,
    [string]$DbUrl = '',
    [ValidateSet('table', 'json', 'csv')]
    [string]$Output = 'table'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

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

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    throw 'npx is required to run supabase@latest. Install Node.js/npm or run the SQL through Supabase MCP execute_sql or the dashboard SQL editor.'
}

$args = @(
    '-y',
    'supabase@latest',
    'db',
    'query',
    '--file',
    $resolvedSqlFile,
    '--output',
    $Output
)

if ($Linked) {
    $args += '--linked'
} elseif ($Local) {
    $args += '--local'
} else {
    $args += @('--db-url', $DbUrl)
}

& npx @args
if ($LASTEXITCODE -ne 0) {
    throw 'Supabase backend verification query failed.'
}

Write-Host 'SUPABASE_BACKEND_VERIFICATION_RUN_OK'
