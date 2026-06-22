param(
    [string]$AndroidApplicationId = 'com.msiazondev.flowfit',
    [string]$AndroidAuthScheme = '',
    [string]$AndroidDevAuthScheme = '',
    [string]$SupabaseUrl = '',
    [string]$SupabasePublishableKey = '',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

function Assert-ProductionValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    if (
        [string]::IsNullOrWhiteSpace($Value) -or
        $Value -match 'YOUR_|REPLACE_WITH|<your-|your[-_]|com\.example\.|com\.yourcompany\.|(^|[./-])smoke($|[./-])|(^|[./:-])(example|invalid|test|localhost)(\.|/|:|$)|127\.0\.0\.1|\$\([^)]+\)'
    ) {
        throw "$Name is still placeholder/test/reserved-shaped: $Value"
    }
}

function Assert-SupabasePublishableKey {
    param(
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
        throw 'SupabasePublishableKey must be a real Supabase publishable client key in sb_publishable_ format.'
    }
}

function Set-GradleProperty {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $pattern = "^\s*$([regex]::Escape($Name))\s*="
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match $pattern) {
            $lines[$index] = "$Name=$Value"
            return
        }
    }

    $lines.Add("$Name=$Value")
}

if ([string]::IsNullOrWhiteSpace($AndroidAuthScheme)) {
    $AndroidAuthScheme = $AndroidApplicationId
}
if ([string]::IsNullOrWhiteSpace($AndroidDevAuthScheme)) {
    $AndroidDevAuthScheme = "$AndroidAuthScheme.dev"
}

Assert-ProductionValue 'AndroidApplicationId' $AndroidApplicationId
Assert-ProductionValue 'AndroidAuthScheme' $AndroidAuthScheme
Assert-ProductionValue 'AndroidDevAuthScheme' $AndroidDevAuthScheme

$gradlePropertiesPath = Join-Path $repoRoot 'android/gradle.properties'
$lines = [System.Collections.Generic.List[string]]::new()
if (Test-Path $gradlePropertiesPath) {
    foreach ($line in Get-Content $gradlePropertiesPath) {
        $lines.Add($line)
    }
}

if (-not $lines.Contains('# FlowFit release identity (non-secret).')) {
    if ($lines.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($lines[$lines.Count - 1])) {
        $lines.Add('')
    }
    $lines.Add('# FlowFit release identity (non-secret).')
}

Set-GradleProperty -Name 'FLOWFIT_ANDROID_APPLICATION_ID' -Value $AndroidApplicationId
Set-GradleProperty -Name 'FLOWFIT_AUTH_SCHEME' -Value $AndroidAuthScheme
Set-GradleProperty -Name 'FLOWFIT_DEV_AUTH_SCHEME' -Value $AndroidDevAuthScheme
Set-Content -Path $gradlePropertiesPath -Value $lines

$hasSupabaseUrl = -not [string]::IsNullOrWhiteSpace($SupabaseUrl)
$hasSupabaseKey = -not [string]::IsNullOrWhiteSpace($SupabasePublishableKey)
if ($hasSupabaseUrl -xor $hasSupabaseKey) {
    throw 'Provide both -SupabaseUrl and -SupabasePublishableKey, or omit both.'
}

if ($hasSupabaseUrl -and $hasSupabaseKey) {
    Assert-ProductionValue 'SupabaseUrl' $SupabaseUrl
    Assert-ProductionValue 'SupabasePublishableKey' $SupabasePublishableKey

    if ($SupabaseUrl -notmatch '^https://[a-z0-9-]+\.supabase\.co$') {
        throw 'SupabaseUrl must look like https://PROJECT_REF.supabase.co.'
    }
    Assert-SupabasePublishableKey -Value $SupabasePublishableKey

    $secretsPath = Join-Path $repoRoot 'lib/secrets.dart'
    if ((Test-Path $secretsPath) -and -not $Force) {
        throw 'lib/secrets.dart already exists. Re-run with -Force to overwrite it.'
    }

    $secrets = @"
class SupabaseConfig {
  static const String url = '$SupabaseUrl';
  static const String publishableKey = '$SupabasePublishableKey';

  @Deprecated('Use publishableKey instead.')
  static const String anonKey = publishableKey;
}
"@
    Set-Content -Path $secretsPath -Value $secrets
}

Write-Host "Wrote Android release identity to android/gradle.properties."
if ($hasSupabaseUrl) {
    Write-Host "Wrote Supabase client config to lib/secrets.dart without printing the key."
} else {
    Write-Host "Skipped lib/secrets.dart because Supabase values were not provided."
}
