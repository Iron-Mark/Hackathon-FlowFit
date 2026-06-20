param(
    [string]$Device = '6ece264d',
    [string]$EnvFile = '',
    [switch]$Release
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

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

function Assert-SupabasePublishableKey {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $normalized = $Value.Trim()
    $lower = $normalized.ToLowerInvariant()
    if (
        [string]::IsNullOrWhiteSpace($normalized) -or
        $lower -match '\.\.\.|your_|replace_with|<your-|your-|project_ref|placeholder|dnasghxxqwibwqnljvxr|sb_secret_|service_role|\s' -or
        $lower -match '(^|[_-])(example|smoke|test)($|[_-])' -or
        $normalized -notmatch '^sb_publishable_[A-Za-z0-9_-]{20,}$'
    ) {
        throw "$Source must provide a real Supabase publishable client key in sb_publishable_ format."
    }
}

function Assert-SupabaseClientValues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [Parameter(Mandatory = $true)]
        [string]$PublishableKey
    )

    if ($Url -match 'YOUR_|REPLACE_WITH|<your-|project_ref|placeholder|dnasghxxqwibwqnljvxr|(^|[./:-])(example|invalid|test|localhost)(\.|/|:|$)|127\.0\.0\.1') {
        throw "$Source Supabase URL still contains placeholder or old project values."
    }
    if ($Url -notmatch '^https://[a-z0-9-]+\.supabase\.co$') {
        throw "$Source must provide a valid Supabase Project URL."
    }

    Assert-SupabasePublishableKey -Source "$Source Supabase publishable key" -Value $PublishableKey
}

function Resolve-SupabaseClientConfig {
    $envUrl = [Environment]::GetEnvironmentVariable('SUPABASE_URL')
    $envKey = [Environment]::GetEnvironmentVariable('SUPABASE_PUBLISHABLE_KEY')
    $hasEnvUrl = -not [string]::IsNullOrWhiteSpace($envUrl)
    $hasEnvKey = -not [string]::IsNullOrWhiteSpace($envKey)

    if ($hasEnvUrl -xor $hasEnvKey) {
        throw 'Provide both SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY, or provide neither and use the local fallback lib/secrets.dart.'
    }

    if ($hasEnvUrl -and $hasEnvKey) {
        $envUrl = $envUrl.Trim()
        $envKey = $envKey.Trim()
        Assert-SupabaseClientValues -Source 'environment' -Url $envUrl -PublishableKey $envKey
        return [pscustomobject]@{
            Source = 'environment'
            Url = $envUrl
            PublishableKey = $envKey
        }
    }

    $secretsPath = Join-Path $repoRoot 'lib/secrets.dart'
    if (-not (Test-Path -LiteralPath $secretsPath)) {
        throw 'Phone app runs require SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY, or ignored lib/secrets.dart. See docs/SUPABASE_RECOVERY_RUNBOOK.md.'
    }

    $secrets = Get-Content -Raw -LiteralPath $secretsPath
    if ($secrets -match 'sb_secret_|service_role') {
        throw 'lib/secrets.dart contains a secret/service-role credential. Use only a publishable client key.'
    }
    if ($secrets -match 'YOUR_|REPLACE_WITH|<your-|dnasghxxqwibwqnljvxr') {
        throw 'lib/secrets.dart still contains placeholder or old Supabase project values.'
    }

    $urlMatch = [regex]::Match($secrets, "url\s*=\s*'([^']+)'")
    $keyMatch = [regex]::Match($secrets, "publishableKey\s*=\s*'([^']+)'")
    if (-not $urlMatch.Success) {
        throw 'lib/secrets.dart must define SupabaseConfig.url.'
    }
    if (-not $keyMatch.Success) {
        throw 'lib/secrets.dart must define SupabaseConfig.publishableKey.'
    }

    Assert-SupabaseClientValues `
        -Source 'lib/secrets.dart' `
        -Url $urlMatch.Groups[1].Value `
        -PublishableKey $keyMatch.Groups[1].Value

    return [pscustomobject]@{
        Source = 'lib/secrets.dart'
        Url = $urlMatch.Groups[1].Value
        PublishableKey = $keyMatch.Groups[1].Value
    }
}

function Assert-MapTileUrlTemplate {
    param([Parameter(Mandatory = $true)][string]$Value)

    if ($Value -notmatch '^https://') {
        throw 'FLOWFIT_MAP_TILE_URL_TEMPLATE must be an HTTPS URL template.'
    }
    foreach ($token in @('{z}', '{x}', '{y}')) {
        if (-not $Value.Contains($token)) {
            throw "FLOWFIT_MAP_TILE_URL_TEMPLATE must include $token."
        }
    }
    if ($Value -match 'tile\.(openstreetmap|osm)\.org') {
        throw 'FLOWFIT_MAP_TILE_URL_TEMPLATE must not point at public OpenStreetMap tile servers for production traffic.'
    }
}

function Assert-MapTileSubdomains {
    param([Parameter(Mandatory = $true)][string]$Value)

    if ($Value -notmatch '^[A-Za-z0-9.-]+(,[A-Za-z0-9.-]+)*$') {
        throw 'FLOWFIT_MAP_TILE_SUBDOMAINS must be a comma-separated list such as a,b,c.'
    }
}

function Get-OptionalMapTileDartDefines {
    $defines = @()
    foreach ($name in @('FLOWFIT_MAP_TILE_URL_TEMPLATE', 'FLOWFIT_MAP_TILE_SUBDOMAINS')) {
        $value = [Environment]::GetEnvironmentVariable($name)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $trimmed = $value.Trim()
            if ($name -eq 'FLOWFIT_MAP_TILE_URL_TEMPLATE') {
                Assert-MapTileUrlTemplate -Value $trimmed
            } elseif ($name -eq 'FLOWFIT_MAP_TILE_SUBDOMAINS') {
                Assert-MapTileSubdomains -Value $trimmed
            }
            $defines += "--dart-define=$name=$trimmed"
        }
    }

    return $defines
}

Import-ReleaseEnvFile -Path $EnvFile
$config = Resolve-SupabaseClientConfig

$command = @(
    'flutter',
    'run',
    '-d',
    $Device,
    '-t',
    'lib/main.dart',
    "--dart-define=SUPABASE_URL=$($config.Url)",
    "--dart-define=SUPABASE_PUBLISHABLE_KEY=$($config.PublishableKey)"
)
$command += Get-OptionalMapTileDartDefines
if ($Release) {
    $command += '--release'
}

Write-Host "Running phone app on $Device using Supabase config from $($config.Source)."
& $command[0] $command[1..($command.Length - 1)]
if ($LASTEXITCODE -ne 0) {
    throw 'flutter run failed.'
}
