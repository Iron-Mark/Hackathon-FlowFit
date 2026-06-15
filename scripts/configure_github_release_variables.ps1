param(
    [string]$Repo = 'Iron-Mark/Hackathon-FlowFit',
    [string]$EnvFile = '',
    [switch]$SupportEmailVerified,
    [switch]$DryRun
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

    if (-not (Test-Path $envPath)) {
        throw "Release env file does not exist: $envPath"
    }

    foreach ($line in Get-Content $envPath) {
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

function Get-RequiredEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "$Name is required."
    }
    return $value.Trim()
}

function Test-PlaceholderValue {
    param([string]$Value)

    return (
        [string]::IsNullOrWhiteSpace($Value) -or
        $Value -match 'YOUR_|REPLACE_WITH|<your-|your[-_]|project_ref|placeholder|dnasghxxqwibwqnljvxr|(^|[./-])smoke($|[./-])|(^|[./:-])(example|invalid|test|localhost)(\.|/|:|$)|127\.0\.0\.1|\$\([^)]+\)'
    )
}

function Assert-Repository {
    param([Parameter(Mandatory = $true)][string]$Value)

    if ($Value -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        throw 'Repo must use owner/name syntax, for example Iron-Mark/Hackathon-FlowFit.'
    }
}

function Assert-PublicWebBaseUrl {
    param([Parameter(Mandatory = $true)][string]$Value)

    if (Test-PlaceholderValue $Value) {
        throw "FLOWFIT_PUBLIC_WEB_BASE_URL is placeholder/test/reserved-shaped: $Value"
    }

    $uri = $null
    if (-not [System.Uri]::TryCreate($Value.Trim().TrimEnd('/'), [System.UriKind]::Absolute, [ref]$uri)) {
        throw 'FLOWFIT_PUBLIC_WEB_BASE_URL must be an absolute HTTPS URL.'
    }
    if ($uri.Scheme -ne 'https') {
        throw 'FLOWFIT_PUBLIC_WEB_BASE_URL must use HTTPS.'
    }
    if (-not [string]::IsNullOrWhiteSpace($uri.Query) -or -not [string]::IsNullOrWhiteSpace($uri.Fragment)) {
        throw 'FLOWFIT_PUBLIC_WEB_BASE_URL must not include query strings or fragments.'
    }
}

function Assert-WebBaseHref {
    param([Parameter(Mandatory = $true)][string]$Value)

    if ($Value -notmatch '^/.*/$') {
        throw 'FLOWFIT_WEB_BASE_HREF must start and end with "/", for example /Hackathon-FlowFit/.'
    }
    if ($Value.Contains('//')) {
        throw 'FLOWFIT_WEB_BASE_HREF must not contain duplicate slashes.'
    }
}

function Assert-Email {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    if ($Value -notmatch '^[^@\s<>]+@[^@\s<>]+\.[^@\s<>]+$' -or $Value -match '[\r\n]') {
        throw "$Name must be a single valid email address."
    }
}

function Assert-SupabaseUrl {
    param([Parameter(Mandatory = $true)][string]$Value)

    if ((Test-PlaceholderValue $Value) -or $Value -notmatch '^https://[a-z0-9-]+\.supabase\.co$') {
        throw 'SUPABASE_URL must be a real Supabase Project URL.'
    }
}

function Assert-SupabasePublishableKey {
    param([Parameter(Mandatory = $true)][string]$Value)

    $normalized = $Value.Trim()
    $lower = $normalized.ToLowerInvariant()
    if (
        [string]::IsNullOrWhiteSpace($normalized) -or
        $lower -match '\.\.\.|your_|replace_with|<your-|your-|project_ref|placeholder|dnasghxxqwibwqnljvxr|sb_secret_|service_role|\s' -or
        $lower -match '(^|[_-])(example|smoke|test)($|[_-])' -or
        $normalized -notmatch '^sb_publishable_[A-Za-z0-9_-]{20,}$'
    ) {
        throw 'SUPABASE_PUBLISHABLE_KEY must be a real Supabase publishable client key in sb_publishable_ format.'
    }
}

function ConvertTo-BoolText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $normalized = $Value.Trim().ToLowerInvariant()
    if ($normalized -eq 'true') {
        return 'true'
    }
    if ($normalized -eq 'false') {
        return 'false'
    }
    throw "$Name must be true or false."
}

function Set-ReleaseVariable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Value,
        [switch]$Redact
    )

    $displayValue = if ($Redact) { '<redacted>' } else { $Value }
    if ($DryRun) {
        Write-Host "Would set $Name=$displayValue"
        return
    }

    # Keep this command shape searchable in release guards: gh variable set
    & gh variable set $Name --repo $Repo --body $Value
    if ($LASTEXITCODE -ne 0) {
        throw "gh variable set failed for $Name."
    }
    Write-Host "Set $Name=$displayValue"
}

Import-ReleaseEnvFile -Path $EnvFile
Assert-Repository -Value $Repo

if (-not $DryRun -and -not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'GitHub CLI is required unless -DryRun is used.'
}

$publicWebBaseUrl = Get-RequiredEnv 'FLOWFIT_PUBLIC_WEB_BASE_URL'
$supportEmail = Get-RequiredEnv 'FLOWFIT_SUPPORT_EMAIL'
$supportEmail = $supportEmail.Trim()
$supabaseUrl = Get-RequiredEnv 'SUPABASE_URL'
$supabasePublishableKey = Get-RequiredEnv 'SUPABASE_PUBLISHABLE_KEY'
$webBaseHref = [Environment]::GetEnvironmentVariable('FLOWFIT_WEB_BASE_HREF')

$supportVerifiedValue = [Environment]::GetEnvironmentVariable('FLOWFIT_SUPPORT_EMAIL_VERIFIED')
if ([string]::IsNullOrWhiteSpace($supportVerifiedValue)) {
    $supportVerifiedValue = if ($SupportEmailVerified) { 'true' } else { 'false' }
}
$supportVerifiedValue = ConvertTo-BoolText -Name 'FLOWFIT_SUPPORT_EMAIL_VERIFIED' -Value $supportVerifiedValue
if ($supportVerifiedValue -eq 'true' -and -not $SupportEmailVerified) {
    throw 'SupportEmailVerified must be passed before setting true.'
}

Assert-PublicWebBaseUrl -Value $publicWebBaseUrl
if (-not [string]::IsNullOrWhiteSpace($webBaseHref)) {
    $webBaseHref = $webBaseHref.Trim()
    Assert-WebBaseHref -Value $webBaseHref
}
Assert-Email -Name 'FLOWFIT_SUPPORT_EMAIL' -Value $supportEmail
Assert-SupabaseUrl -Value $supabaseUrl
Assert-SupabasePublishableKey -Value $supabasePublishableKey

Set-ReleaseVariable -Name 'FLOWFIT_PUBLIC_WEB_BASE_URL' -Value $publicWebBaseUrl.Trim().TrimEnd('/')
if (-not [string]::IsNullOrWhiteSpace($webBaseHref)) {
    Set-ReleaseVariable -Name 'FLOWFIT_WEB_BASE_HREF' -Value $webBaseHref
}
Set-ReleaseVariable -Name 'FLOWFIT_SUPPORT_EMAIL' -Value $supportEmail
Set-ReleaseVariable -Name 'FLOWFIT_SUPPORT_EMAIL_VERIFIED' -Value $supportVerifiedValue
Set-ReleaseVariable -Name 'SUPABASE_URL' -Value $supabaseUrl
Set-ReleaseVariable -Name 'SUPABASE_PUBLISHABLE_KEY' -Value $supabasePublishableKey -Redact

if ($DryRun) {
    Write-Host 'GH_RELEASE_VARIABLES_DRY_RUN_OK'
} else {
    Write-Host 'GH_RELEASE_VARIABLES_SET_OK'
}
