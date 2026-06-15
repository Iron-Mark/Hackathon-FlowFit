param(
    [switch]$Strict,
    [switch]$SupportEmailVerified,
    [string]$EnvFile = '',
    [ValidateSet('Auto', 'Recovery', 'Release')]
    [string]$McpMode = 'Auto',
    [string]$McpConfigPath = '.mcp.json',
    [string]$OutFile = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$results = New-Object System.Collections.Generic.List[object]
$supportEmailVerifiedForAudit = $false
$effectiveMcpMode = if ($McpMode -eq 'Auto') {
    if ($Strict) { 'Release' } else { 'Recovery' }
} else {
    $McpMode
}

function Add-Result {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PASS', 'WARN', 'FAIL')]
        [string]$Level,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Detail,
        [bool]$StrictFailure = $false
    )

    $effectiveLevel = $Level
    if ($Strict -and $Level -eq 'WARN' -and $StrictFailure) {
        $effectiveLevel = 'FAIL'
    }

    $script:results.Add([pscustomobject]@{
        Level = $effectiveLevel
        Name = $Name
        Detail = $Detail
    })
}

function Add-Pass {
    param([string]$Name, [string]$Detail)
    Add-Result -Level 'PASS' -Name $Name -Detail $Detail
}

function Add-Warn {
    param([string]$Name, [string]$Detail, [bool]$StrictFailure = $true)
    Add-Result -Level 'WARN' -Name $Name -Detail $Detail -StrictFailure $StrictFailure
}

function Add-Fail {
    param([string]$Name, [string]$Detail)
    Add-Result -Level 'FAIL' -Name $Name -Detail $Detail
}

function Get-RepoPath {
    param([string]$Path)
    return Join-Path $repoRoot $Path
}

function Read-RepoText {
    param([string]$Path)

    $fullPath = Get-RepoPath $Path
    if (-not (Test-Path $fullPath)) {
        return $null
    }

    return Get-Content -Raw $fullPath
}

function Read-AuditText {
    param([string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        if (-not (Test-Path -LiteralPath $Path)) {
            return $null
        }
        return Get-Content -Raw -LiteralPath $Path
    }

    return Read-RepoText $Path
}

function Read-Properties {
    param([string]$Path)

    $properties = @{}
    $fullPath = Get-RepoPath $Path
    if (-not (Test-Path $fullPath)) {
        return $properties
    }

    foreach ($line in Get-Content $fullPath) {
        if ($line -match '^\s*$' -or $line -match '^\s*#') {
            continue
        }
        if ($line -match '^\s*([^=]+?)\s*=\s*(.*)\s*$') {
            $properties[$matches[1].Trim()] = $matches[2].Trim()
        }
    }

    return $properties
}

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

function Resolve-XcconfigValue {
    param(
        [AllowNull()][string]$Value,
        [hashtable]$Properties
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $Value
    }

    $resolved = $Value.Trim()
    if ($null -eq $Properties) {
        return $resolved
    }

    foreach ($key in $Properties.Keys) {
        $placeholder = '$(' + [string]$key + ')'
        $replacement = [string]$Properties[$key]
        $resolved = $resolved.Replace($placeholder, $replacement)
    }

    return $resolved.Trim()
}

function Test-PlaceholderValue {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $true
    }

    return (
        $Value -match 'YOUR_|REPLACE_WITH|<your-|your[-_]|com\.example\.|com\.yourcompany\.|(^|[./-])smoke($|[./-])|(^|[./:-])(example|invalid|test|localhost)(\.|/|:|$)|127\.0\.0\.1|\$\([^)]+\)'
    )
}

function Test-SupabasePublishableKey {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $false
    }

    $normalized = $Value.Trim()
    $lower = $normalized.ToLowerInvariant()
    if (
        $lower -match '\.\.\.|your_|replace_with|<your-|your-|project_ref|placeholder|dnasghxxqwibwqnljvxr|sb_secret_|service_role|\s' -or
        $lower -match '(^|[_-])(example|smoke|test)($|[_-])'
    ) {
        return $false
    }

    return $normalized -match '^sb_publishable_[A-Za-z0-9_-]{20,}$'
}

function Test-PublicWebBaseUrl {
    param([string]$Value)

    if (Test-PlaceholderValue $Value) {
        return @{
            Valid = $false
            Detail = 'FLOWFIT_PUBLIC_WEB_BASE_URL is missing, placeholder/test-shaped, reserved, or not set to a deployed HTTPS URL for store submission.'
        }
    }

    $normalized = $Value.Trim().TrimEnd('/')
    $uri = $null
    if (-not [System.Uri]::TryCreate($normalized, [System.UriKind]::Absolute, [ref]$uri)) {
        return @{
            Valid = $false
            Detail = 'FLOWFIT_PUBLIC_WEB_BASE_URL must be an absolute HTTPS URL without query strings or fragments.'
        }
    }
    if ($uri.Scheme -ne 'https') {
        return @{
            Valid = $false
            Detail = 'FLOWFIT_PUBLIC_WEB_BASE_URL must use HTTPS.'
        }
    }
    if ([string]::IsNullOrWhiteSpace($uri.Host)) {
        return @{
            Valid = $false
            Detail = 'FLOWFIT_PUBLIC_WEB_BASE_URL must include a public host.'
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($uri.Query) -or -not [string]::IsNullOrWhiteSpace($uri.Fragment)) {
        return @{
            Valid = $false
            Detail = 'FLOWFIT_PUBLIC_WEB_BASE_URL must not include query strings or fragments.'
        }
    }

    return @{
        Valid = $true
        Detail = 'FLOWFIT_PUBLIC_WEB_BASE_URL is configured for deployed compliance URLs, including path-based static hosts when needed.'
    }
}

function Get-AndroidSetting {
    param(
        [hashtable]$GradleProperties,
        [string]$Name
    )

    $envName = "ORG_GRADLE_PROJECT_$Name"
    $envValue = [Environment]::GetEnvironmentVariable($envName)
    if (-not [string]::IsNullOrWhiteSpace($envValue)) {
        return @{
            Value = $envValue
            Source = "environment $envName"
        }
    }

    if ($GradleProperties.ContainsKey($Name)) {
        return @{
            Value = $GradleProperties[$Name]
            Source = 'android/gradle.properties'
        }
    }

    return @{
        Value = $null
        Source = 'not configured'
    }
}

function Assert-RequiredText {
    param(
        [string]$Name,
        [string]$Path,
        [string]$Content,
        [string]$Needle,
        [string]$Detail
    )

    if ($null -eq $Content) {
        Add-Fail $Name "Missing $Path."
        return
    }

    if ($Content.Contains($Needle)) {
        Add-Pass $Name $Detail
    } else {
        Add-Fail $Name "Missing expected text in $Path."
    }
}

function Test-McpConfig {
    $path = $script:McpConfigPath
    $content = Read-AuditText $path
    if ($null -eq $content) {
        Add-Fail 'Supabase MCP config' "Missing project-scoped $path."
        return
    }

    try {
        $json = $content | ConvertFrom-Json
        $url = [string]$json.mcpServers.supabase.url
    } catch {
        Add-Fail 'Supabase MCP config' '.mcp.json is not valid JSON.'
        return
    }

    if ([string]::IsNullOrWhiteSpace($url)) {
        Add-Fail 'Supabase MCP config' '.mcp.json does not define mcpServers.supabase.url.'
        return
    }

    if (-not $url.StartsWith('https://mcp.supabase.com/mcp')) {
        Add-Fail 'Supabase MCP config' 'Supabase MCP URL does not use the hosted Supabase MCP endpoint.'
        return
    }

    if ($url -notmatch 'project_ref=') {
        Add-Fail 'Supabase MCP project scope' 'MCP URL is not scoped to a Supabase project_ref.'
    } elseif ($url.Contains('REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF')) {
        Add-Warn 'Supabase MCP project scope' 'MCP project_ref still uses the placeholder project ref.'
    } else {
        Add-Pass 'Supabase MCP project scope' 'MCP URL includes a project_ref.'
    }

    $hasReadOnly = $url -match '(^|[?&])read_only=true($|&)'
    if ($script:effectiveMcpMode -eq 'Release') {
        if ($hasReadOnly) {
            Add-Pass 'Supabase MCP release read-only' 'MCP URL enables read_only=true for post-migration release hardening.'
        } else {
            Add-Warn 'Supabase MCP release read-only' 'Strict release MCP posture should add read_only=true after migrations and advisors are complete.'
        }
    } elseif ($hasReadOnly) {
        Add-Fail 'Supabase MCP recovery write access' 'Recovery MCP config is read-only; migrations need development write access.'
    } else {
        Add-Pass 'Supabase MCP recovery write access' 'MCP URL does not force read_only=true.'
    }

    $requiredFeatures = @('database', 'docs', 'debugging', 'development')
    foreach ($feature in $requiredFeatures) {
        if ($url -notmatch "features=.*$feature") {
            Add-Fail 'Supabase MCP feature groups' "MCP URL does not include the $feature feature group."
            return
        }
    }

    Add-Pass 'Supabase MCP feature groups' 'MCP URL includes database, docs, debugging, and development groups.'
}

function Test-Secrets {
    $example = Read-RepoText 'lib/secrets.dart.example'
    if ($null -eq $example) {
        Add-Fail 'Supabase secrets example' 'Missing lib/secrets.dart.example.'
    } else {
        if ($example.Contains('publishableKey') -and $example.Contains('anonKey = publishableKey')) {
            Add-Pass 'Supabase secrets example' 'Example uses publishableKey plus deprecated anonKey alias.'
        } else {
            Add-Fail 'Supabase secrets example' 'Example must expose publishableKey and anonKey compatibility alias.'
        }
    }

    $runtimeConfig = Read-RepoText 'lib/core/config/supabase_runtime_config.dart'
    if (
        $null -ne $runtimeConfig -and
        $runtimeConfig.Contains("String.fromEnvironment(") -and
        $runtimeConfig.Contains("'SUPABASE_URL'") -and
        $runtimeConfig.Contains("'SUPABASE_PUBLISHABLE_KEY'")
    ) {
        Add-Pass 'Supabase build-time config' 'Tracked runtime config reads Supabase URL and publishable key from dart defines.'
    } else {
        Add-Fail 'Supabase build-time config' 'Missing tracked Supabase dart-define runtime config.'
    }

    $envUrl = [Environment]::GetEnvironmentVariable('SUPABASE_URL')
    $envKey = [Environment]::GetEnvironmentVariable('SUPABASE_PUBLISHABLE_KEY')
    $hasEnvUrl = -not [string]::IsNullOrWhiteSpace($envUrl)
    $hasEnvKey = -not [string]::IsNullOrWhiteSpace($envKey)
    if ($hasEnvUrl -xor $hasEnvKey) {
        Add-Fail 'Supabase release environment' 'Set both SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY, or neither.'
    } elseif ($hasEnvUrl -and $hasEnvKey) {
        $envUrl = $envUrl.Trim()
        $envKey = $envKey.Trim()
        if (Test-PlaceholderValue $envUrl -or $envUrl -notmatch '^https://[a-z0-9-]+\.supabase\.co$') {
            Add-Fail 'Supabase release URL' 'SUPABASE_URL is missing, placeholder/test-shaped, or not a Supabase project URL.'
        } else {
            Add-Pass 'Supabase release URL' 'SUPABASE_URL is configured for release builds.'
        }
        if ($envKey -match 'sb_secret_|service_role') {
            Add-Fail 'Supabase release publishable key' 'SUPABASE_PUBLISHABLE_KEY contains a secret/service-role credential.'
        } elseif (-not (Test-SupabasePublishableKey $envKey)) {
            Add-Fail 'Supabase release publishable key' 'SUPABASE_PUBLISHABLE_KEY is missing, placeholder/test-shaped, or not a real sb_publishable_ key.'
        } else {
            Add-Pass 'Supabase release publishable key' 'SUPABASE_PUBLISHABLE_KEY uses the current sb_publishable_ format.'
        }
        return
    }

    $secretsPath = 'lib/secrets.dart'
    $secrets = Read-RepoText $secretsPath
    if ($null -eq $secrets) {
        Add-Warn 'Supabase client credentials' 'No SUPABASE_URL/SUPABASE_PUBLISHABLE_KEY environment and no ignored lib/secrets.dart fallback.'
        return
    }

    if ($secrets -match 'sb_secret_|service_role') {
        Add-Fail 'Local Supabase credentials' 'lib/secrets.dart appears to contain a secret/service-role credential. Remove it from Flutter client config.'
    }

    if ($secrets.Contains('dnasghxxqwibwqnljvxr')) {
        Add-Fail 'Local Supabase project ref' 'lib/secrets.dart still points at the old Supabase project ref.'
    }

    if ($secrets -match 'YOUR_PROJECT_REF|YOUR_KEY|REPLACE_WITH') {
        Add-Warn 'Local Supabase credentials' 'lib/secrets.dart still contains placeholder values.'
    }

    $urlMatch = [regex]::Match($secrets, "url\s*=\s*'([^']+)'")
    if (-not $urlMatch.Success -or $urlMatch.Groups[1].Value -notmatch '^https://[a-z0-9-]+\.supabase\.co$') {
        Add-Warn 'Local Supabase URL' 'lib/secrets.dart does not contain a valid-looking Supabase project URL.'
    } else {
        Add-Pass 'Local Supabase URL' 'lib/secrets.dart contains a Supabase project URL.'
    }

    $keyMatch = [regex]::Match($secrets, "publishableKey\s*=\s*'([^']+)'")
    if (-not $keyMatch.Success) {
        Add-Fail 'Local Supabase publishable key' 'lib/secrets.dart does not define SupabaseConfig.publishableKey.'
    } elseif (-not (Test-SupabasePublishableKey $keyMatch.Groups[1].Value)) {
        Add-Warn 'Local Supabase publishable key' 'publishableKey still contains a placeholder value.'
    } else {
        Add-Pass 'Local Supabase publishable key' 'publishableKey uses the current sb_publishable_ format.'
    }
}

function Test-ReleaseEnvTemplate {
    $content = Read-RepoText '.env.release.example'
    if ($null -eq $content) {
        Add-Fail 'Release env template' 'Missing .env.release.example.'
        return
    }

    $requiredNames = @(
        'FLOWFIT_SUPPORT_EMAIL',
        'FLOWFIT_SUPPORT_EMAIL_VERIFIED',
        'FLOWFIT_PUBLIC_WEB_BASE_URL',
        'SUPABASE_URL',
        'SUPABASE_PUBLISHABLE_KEY',
        'ORG_GRADLE_PROJECT_FLOWFIT_ANDROID_APPLICATION_ID',
        'ORG_GRADLE_PROJECT_FLOWFIT_AUTH_SCHEME'
    )

    foreach ($name in $requiredNames) {
        if (-not ($content -match "(?m)^$([regex]::Escape($name))=")) {
            Add-Fail 'Release env template' ".env.release.example is missing $name."
            return
        }
    }

    if ($content -match 'sb_secret_|service_role|dnasghxxqwibwqnljvxr') {
        Add-Fail 'Release env template' '.env.release.example contains a server-only key marker or old Supabase project ref.'
    } else {
        Add-Pass 'Release env template' '.env.release.example lists release inputs and secret placeholders without server-only keys.'
    }
}

function Get-OptionalEnv {
    param([Parameter(Mandatory = $true)][string]$Name)

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        return ''
    }

    return $value.Trim()
}

function Test-SupabaseMigration {
    $path = 'supabase/migrations/20260614062844_recreate_flowfit_backend.sql'
    $content = Read-RepoText $path
    if ($null -eq $content) {
        Add-Fail 'Canonical Supabase migration' "Missing $path."
        return
    }

    Add-Pass 'Canonical Supabase migration' "Found $path."

    if ($content -match '(?i)security\s+definer') {
        Add-Fail 'Supabase privileged functions' 'Canonical migration contains security definer in an exposed public schema.'
    } else {
        Add-Pass 'Supabase privileged functions' 'Canonical migration does not contain security definer.'
    }

    Assert-RequiredText 'Account deletion RPC mode' $path $content 'security invoker' 'request_account_deletion runs as security invoker.'
    Assert-RequiredText 'Account deletion RPC grant' $path $content 'grant execute on function public.request_account_deletion() to authenticated;' 'Only authenticated users receive execute on request_account_deletion.'
    Assert-RequiredText 'Canonical policy cleanup' $path $content 'from pg_policies' 'Migration drops existing policies on managed public tables before recreating canonical RLS.'
    if ($content -match '(?s)revoke all\s+on\s+public\.user_profiles') {
        Add-Pass 'Canonical grant cleanup' 'Migration revokes stale Data API table grants before applying expected grants.'
    } else {
        Add-Fail 'Canonical grant cleanup' 'Migration does not revoke stale Data API table grants before applying expected grants.'
    }
    if ($content -match "(?s)from pg_constraint\s+where conrelid = 'public\.user_profiles'::regclass\s+and contype = 'c'.*alter table public\.user_profiles drop constraint if exists") {
        Add-Pass 'Canonical profile check repair' 'Migration drops legacy user_profiles CHECK constraints before applying canonical checks.'
    } else {
        Add-Fail 'Canonical profile check repair' 'Migration does not remove stale user_profiles CHECK constraints from legacy fragmented setups.'
    }
    if (
        $content.Contains('create table if not exists public.flowfit_recovery_quarantine') -and
        $content.Contains('alter table public.flowfit_recovery_quarantine enable row level security;') -and
        ($content -match '(?s)insert into public\.flowfit_recovery_quarantine.*delete from public\.user_profiles') -and
        ($content -match '(?s)grant select,\s*delete\s+on public\.flowfit_recovery_quarantine\s+to service_role;')
    ) {
        Add-Pass 'Recovery cleanup quarantine' 'Migration copies invalid legacy rows to a service-role-only quarantine table before cleanup deletes.'
    } else {
        Add-Fail 'Recovery cleanup quarantine' 'Migration must quarantine invalid legacy rows before cleanup deletes.'
    }
    Assert-RequiredText 'Helper function execute revoke' $path $content 'revoke all on function public.update_updated_at_column()' 'Migration revokes direct execute access on trigger helper function.'
    Assert-RequiredText 'Deletion queue retention' $path $content 'drop constraint if exists account_deletion_requests_user_id_fkey' 'Deletion request queue is not cascaded away when an auth user is later deleted.'
    if (
        $content.Contains("set_config('app.flowfit_account_deletion_rpc', '1', true)") -and
        $content.Contains("coalesce(current_setting('app.flowfit_account_deletion_rpc', true), '') = '1'") -and
        $content.Contains('Deletion RPC can create own pending account deletion requests')
    ) {
        Add-Pass 'Deletion queue RPC insert gate' 'Account deletion queue inserts require the request_account_deletion RPC transaction flag.'
    } else {
        Add-Fail 'Deletion queue RPC insert gate' 'Account deletion queue inserts must be gated behind request_account_deletion(), not broad direct client inserts.'
    }
    if (
        $content.Contains('create or replace function public.has_pending_account_deletion(target_user_id uuid)') -and
        $content.Contains("and status in ('pending', 'processing')") -and
        $content.Contains('grant execute on function public.has_pending_account_deletion(uuid)') -and
        ([regex]::Matches($content, 'not public\.has_pending_account_deletion\(user_id\)').Count -ge 8)
    ) {
        Add-Pass 'Pending deletion write guard' 'RLS blocks authenticated app-data writes after an account deletion request is pending or processing.'
    } else {
        Add-Fail 'Pending deletion write guard' 'Migration must block profile, buddy, workout, and heart-rate writes after pending deletion.'
    }

    foreach ($table in @(
        'user_profiles',
        'buddy_profiles',
        'workout_sessions',
        'heart_rate',
        'account_deletion_requests'
    )) {
        $rlsNeedle = "alter table public.$table enable row level security;"
        if ($content.Contains($rlsNeedle)) {
            Add-Pass "RLS: $table" "RLS is enabled for public.$table."
        } else {
            Add-Fail "RLS: $table" "Missing RLS enable statement for public.$table."
        }
    }

    foreach ($table in @(
        'public.user_profiles',
        'public.buddy_profiles',
        'public.workout_sessions',
        'public.heart_rate'
    )) {
        if ($content.Contains($table)) {
            Add-Pass "Data API grant target: $table" "Migration references $table in authenticated grants/policies."
        } else {
            Add-Fail "Data API grant target: $table" "Migration does not reference $table."
        }
    }

    if ($content -match '(?s)grant select, insert, update, delete\s+on\s+public\.user_profiles,\s+public\.buddy_profiles,\s+public\.workout_sessions,\s+public\.heart_rate\s+to authenticated;') {
        Add-Pass 'Data API authenticated grants' 'Migration grants authenticated access to app tables; RLS still controls row access.'
    } else {
        Add-Fail 'Data API authenticated grants' 'Migration is missing the explicit authenticated grant block for app tables.'
    }

    if ($content -match '(?s)grant usage on schema extensions\s+to authenticated,\s+service_role;') {
        Add-Pass 'Extensions schema usage grants' 'Migration grants runtime roles access to extension-backed UUID defaults.'
    } else {
        Add-Fail 'Extensions schema usage grants' 'Migration must grant authenticated/service_role usage on extensions for gen_random_uuid() defaults.'
    }

    if ($content -match '(?s)grant select, insert, update, delete\s+on\s+public\.user_profiles,\s+public\.buddy_profiles,\s+public\.workout_sessions,\s+public\.heart_rate\s+to service_role;') {
        Add-Pass 'Data API service-role app grants' 'Migration grants service_role access for server-side maintenance workflows.'
    } else {
        Add-Fail 'Data API service-role app grants' 'Migration is missing explicit service_role grants for app tables under the new explicit-grants model.'
    }

    if ($content -match '(?s)grant select, update\s+on public\.account_deletion_requests\s+to service_role;') {
        Add-Pass 'Deletion queue service-role grant' 'Migration grants service_role select/update access to process deletion requests.'
    } else {
        Add-Fail 'Deletion queue service-role grant' 'Migration is missing service_role select/update access for account_deletion_requests.'
    }

    if (
        $content -match '(?s)grant select\s+on public\.account_deletion_requests\s+to authenticated;' -and
        $content -match '(?s)grant insert \(user_id, user_email, status, requested_at\)\s+on public\.account_deletion_requests\s+to authenticated;'
    ) {
        Add-Pass 'Deletion queue authenticated grant scope' 'Authenticated insert access is column-scoped and still constrained by the RPC-gated RLS policy.'
    } else {
        Add-Fail 'Deletion queue authenticated grant scope' 'Authenticated account_deletion_requests access must be select plus column-scoped insert only.'
    }
}

function Test-SupabaseConfig {
    $content = Read-RepoText 'supabase/config.toml'
    if ($null -eq $content) {
        Add-Fail 'Supabase local config' 'Missing supabase/config.toml.'
        return
    }

    if ($content.Contains('com.oldstlabs.flowfit://auth-callback') -and $content.Contains('com.oldstlabs.flowfit.dev://auth-callback')) {
        Add-Pass 'Supabase maintained-fork redirect URLs' 'Local Supabase config includes maintained-fork mobile auth redirects.'
    } else {
        Add-Fail 'Supabase maintained-fork redirect URLs' 'Local Supabase config is missing maintained-fork mobile auth redirects.'
    }

    if ($content.Contains('com.example.flowfit://auth-callback') -or $content.Contains('com.example.flowfit.dev://auth-callback')) {
        Add-Fail 'Supabase legacy redirect URLs' 'Local Supabase config still allows legacy com.example.flowfit mobile auth callbacks.'
    } else {
        Add-Pass 'Supabase legacy redirect URLs' 'Local Supabase config does not allow legacy com.example.flowfit mobile auth callbacks.'
    }

    $emailAuthMatch = [regex]::Match($content, '(?s)\[auth\.email\](.*?)(\r?\n\[|$)')
    $emailAuthBlock = if ($emailAuthMatch.Success) { $emailAuthMatch.Groups[1].Value } else { '' }
    if ($emailAuthBlock -match 'enable_confirmations\s*=\s*false') {
        Add-Warn 'Supabase email confirmation' 'Local config has email confirmation disabled for first smoke tests; re-enable it for realistic shared dev or production.' -StrictFailure $false
    } else {
        Add-Pass 'Supabase email confirmation' 'Local config does not disable email confirmation.'
    }
}

function Test-AndroidReleaseConfig {
    $buildFile = Read-RepoText 'android/app/build.gradle.kts'
    if ($null -eq $buildFile) {
        Add-Fail 'Android Gradle release guard' 'Missing android/app/build.gradle.kts.'
        return
    }

    foreach ($needle in @(
        'Release builds must not use placeholder, smoke, or example FlowFit package/auth IDs.',
        'Signed release builds must pass matching Dart auth schemes:',
        'ORG_GRADLE_PROJECT_FLOWFIT_ALLOW_DEBUG_RELEASE_SIGNING=true'
    )) {
        if (-not $buildFile.Contains($needle)) {
            Add-Fail 'Android Gradle release guard' "Missing guard text: $needle"
            return
        }
    }
    Add-Pass 'Android Gradle release guard' 'Release signing, placeholder ID, and Dart auth-scheme guards are present.'

    if ($buildFile.Contains('namespace = "com.oldstlabs.flowfit"') -and -not $buildFile.Contains('namespace = "com.example.flowfit"')) {
        Add-Pass 'Android native namespace' 'Gradle namespace uses the maintained fork package.'
    } else {
        Add-Fail 'Android native namespace' 'Gradle namespace must use com.oldstlabs.flowfit, not com.example.flowfit.'
    }

    $kotlinRoot = Get-RepoPath 'android/app/src/main/kotlin'
    $legacyPackageSources = @()
    if (Test-Path $kotlinRoot) {
        $legacyPackageSources = @(
            Get-ChildItem -Path $kotlinRoot -Recurse -Filter '*.kt' |
                Where-Object { (Get-Content -Raw $_.FullName).Contains('package com.example.flowfit') }
        )
    }
    if (
        (Test-Path (Get-RepoPath 'android/app/src/main/kotlin/com/oldstlabs/flowfit/MainActivity.kt')) -and
        $legacyPackageSources.Count -eq 0
    ) {
        Add-Pass 'Android Kotlin package namespace' 'Native Kotlin sources use com.oldstlabs.flowfit.'
    } else {
        Add-Fail 'Android Kotlin package namespace' 'Native Kotlin sources must live under and declare com.oldstlabs.flowfit.'
    }

    $mainManifest = Read-RepoText 'android/app/src/main/AndroidManifest.xml'
    $debugManifest = Read-RepoText 'android/app/src/debug/AndroidManifest.xml'
    $manifestComponentIssues = New-Object System.Collections.Generic.List[string]
    $manifestComponents = New-Object System.Collections.Generic.HashSet[string]
    foreach ($manifest in @($mainManifest, $debugManifest)) {
        if ($null -eq $manifest) {
            continue
        }

        foreach ($match in [regex]::Matches($manifest, 'android:name="\.(?<class>[A-Za-z_][A-Za-z0-9_]*)"')) {
            [void]$manifestComponents.Add($match.Groups['class'].Value)
        }
    }

    foreach ($component in $manifestComponents) {
        $componentPath = Get-RepoPath "android/app/src/main/kotlin/com/oldstlabs/flowfit/$component.kt"
        if (-not (Test-Path $componentPath)) {
            $manifestComponentIssues.Add($component)
        }
    }

    if ($manifestComponentIssues.Count -eq 0) {
        Add-Pass 'Android manifest app components' 'Relative Android manifest components have matching Kotlin classes.'
    } else {
        Add-Fail 'Android manifest app components' "Missing Kotlin class files for manifest components: $($manifestComponentIssues -join ', ')."
    }

    $gradleProperties = Read-Properties 'android/gradle.properties'
    $requiredSettings = @(
        'FLOWFIT_ANDROID_APPLICATION_ID',
        'FLOWFIT_AUTH_SCHEME'
    )

    foreach ($setting in $requiredSettings) {
        $resolved = Get-AndroidSetting -GradleProperties $gradleProperties -Name $setting
        if (Test-PlaceholderValue $resolved.Value) {
            Add-Warn "Android production setting: $setting" "$setting is $($resolved.Source)."
        } else {
            Add-Pass "Android production setting: $setting" "$setting is configured via $($resolved.Source)."
        }
    }

    if ($null -ne $mainManifest -and $mainManifest.Contains('${flowfitDevAuthScheme}')) {
        Add-Fail 'Android release auth schemes' 'Release manifest registers the development auth scheme.'
    } elseif ($null -ne $debugManifest -and $debugManifest.Contains('${flowfitDevAuthScheme}')) {
        Add-Pass 'Android release auth schemes' 'Development auth scheme is isolated to the debug manifest.'
    } else {
        Add-Warn 'Android release auth schemes' 'No debug-only development auth scheme manifest was found.' -StrictFailure $false
    }

    if ($null -ne $mainManifest -and $mainManifest.Contains('ACCESS_BACKGROUND_LOCATION')) {
        Add-Fail 'Android foreground location surface' 'Release manifest must not request ACCESS_BACKGROUND_LOCATION until native background geofencing is implemented and tested.'
    } elseif ($null -ne $mainManifest -and $mainManifest.Contains('ACCESS_FINE_LOCATION') -and $mainManifest.Contains('ACCESS_COARSE_LOCATION')) {
        Add-Pass 'Android foreground location surface' 'Release manifest declares foreground location without background location.'
    } else {
        Add-Fail 'Android foreground location surface' 'Release manifest must declare foreground fine/coarse location for maps and missions.'
    }

    if ($null -ne $mainManifest -and $mainManifest.Contains('NativeGeofence')) {
        Add-Fail 'Android native geofence surface' 'Release manifest still registers native_geofence background components.'
    } else {
        Add-Pass 'Android native geofence surface' 'Release manifest does not register unused native_geofence background components.'
    }

    $keyPropertiesPath = 'android/key.properties'
    $keyProperties = Read-Properties $keyPropertiesPath
    if ($keyProperties.Count -eq 0) {
        $signingEnv = @{
            FLOWFIT_ANDROID_KEYSTORE_BASE64 = Get-OptionalEnv 'FLOWFIT_ANDROID_KEYSTORE_BASE64'
            FLOWFIT_ANDROID_KEYSTORE_PASSWORD = Get-OptionalEnv 'FLOWFIT_ANDROID_KEYSTORE_PASSWORD'
            FLOWFIT_ANDROID_KEY_ALIAS = Get-OptionalEnv 'FLOWFIT_ANDROID_KEY_ALIAS'
            FLOWFIT_ANDROID_KEY_PASSWORD = Get-OptionalEnv 'FLOWFIT_ANDROID_KEY_PASSWORD'
        }
        $providedSigningEnv = @($signingEnv.Values | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($providedSigningEnv.Count -eq 4) {
            foreach ($field in @('FLOWFIT_ANDROID_KEYSTORE_PASSWORD', 'FLOWFIT_ANDROID_KEY_ALIAS', 'FLOWFIT_ANDROID_KEY_PASSWORD')) {
                if ($signingEnv[$field] -match 'REPLACE_WITH|YOUR_') {
                    Add-Fail 'Android upload signing' "$field contains a placeholder value."
                    return
                }
            }
            try {
                $null = [Convert]::FromBase64String($signingEnv['FLOWFIT_ANDROID_KEYSTORE_BASE64'])
            } catch {
                Add-Fail 'Android upload signing' 'FLOWFIT_ANDROID_KEYSTORE_BASE64 is not valid base64.'
                return
            }

            Add-Pass 'Android upload signing' 'Android upload signing env secrets are present for CI/local release materialization.'
            return
        }

        if ($providedSigningEnv.Count -gt 0) {
            Add-Fail 'Android upload signing' 'Android signing env is incomplete. Set FLOWFIT_ANDROID_KEYSTORE_BASE64, FLOWFIT_ANDROID_KEYSTORE_PASSWORD, FLOWFIT_ANDROID_KEY_ALIAS, and FLOWFIT_ANDROID_KEY_PASSWORD together.'
            return
        }

        Add-Warn 'Android upload signing' 'Missing android/key.properties; Play Store upload artifact cannot be produced yet.'
        return
    }

    $requiredKeyFields = @('storeFile', 'storePassword', 'keyAlias', 'keyPassword')
    foreach ($field in $requiredKeyFields) {
        if (-not $keyProperties.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($keyProperties[$field])) {
            Add-Fail 'Android upload signing' "android/key.properties is missing $field."
            return
        }
        if ($field -ne 'storeFile' -and $keyProperties[$field] -match 'REPLACE_WITH|YOUR_') {
            Add-Fail 'Android upload signing' "android/key.properties contains a placeholder $field."
            return
        }
    }

    $storeFilePath = Join-Path (Get-RepoPath 'android') $keyProperties['storeFile']
    if (Test-Path $storeFilePath) {
        Add-Pass 'Android upload signing' 'android/key.properties and referenced upload keystore are present.'
    } else {
        Add-Warn 'Android upload signing' 'android/key.properties exists, but the referenced upload keystore file is missing.'
    }
}

function Test-IosReleaseConfig {
    $content = Read-RepoText 'ios/Flutter/FlowFit.xcconfig'
    if ($null -eq $content) {
        Add-Fail 'iOS release config' 'Missing ios/Flutter/FlowFit.xcconfig.'
        return
    }

    $properties = Read-Properties 'ios/Flutter/FlowFit.xcconfig'
    $bundleId = $properties['FLOWFIT_IOS_BUNDLE_IDENTIFIER']
    if (Test-PlaceholderValue $bundleId) {
        Add-Warn 'iOS production bundle ID' 'FLOWFIT_IOS_BUNDLE_IDENTIFIER still uses a local/example value.'
    } else {
        Add-Pass 'iOS production bundle ID' 'FLOWFIT_IOS_BUNDLE_IDENTIFIER is production-shaped.'
    }

    $infoPlist = Read-RepoText 'ios/Runner/Info.plist'
    if ($null -ne $infoPlist -and $infoPlist.Contains('$(FLOWFIT_IOS_BUNDLE_IDENTIFIER)') -and -not $infoPlist.Contains('$(FLOWFIT_IOS_DEV_AUTH_SCHEME)')) {
        Add-Pass 'iOS auth URL schemes' 'Info.plist registers only the production iOS auth scheme.'
    } else {
        Add-Fail 'iOS auth URL schemes' 'Info.plist must register the production auth scheme and exclude development schemes from release artifacts.'
    }

    if (
        $null -ne $infoPlist -and
        $infoPlist.Contains('NSLocationWhenInUseUsageDescription') -and
        -not $infoPlist.Contains('NSLocationAlways') -and
        -not $infoPlist.Contains('UIBackgroundModes')
    ) {
        Add-Pass 'iOS foreground location surface' 'Info.plist declares only when-in-use location for release.'
    } else {
        Add-Fail 'iOS foreground location surface' 'Info.plist must avoid Always/background location until native background geofencing is implemented and tested.'
    }

    $releaseScript = Read-RepoText 'scripts/store_release_build.ps1'
    if (
        $null -ne $releaseScript -and
        $releaseScript.Contains("'iOS'") -and
        $releaseScript.Contains("'ipa'") -and
        $releaseScript.Contains('--export-options-plist')
    ) {
        Add-Pass 'iOS App Store wrapper' 'store_release_build.ps1 includes the guarded iOS IPA/export-options path.'
    } else {
        Add-Fail 'iOS App Store wrapper' 'store_release_build.ps1 does not expose the iOS IPA/export-options release path.'
    }

    if ($null -ne $releaseScript -and $releaseScript.Contains('Assert-SupabaseClientConfig')) {
        Add-Pass 'Store Supabase config guard' 'store_release_build.ps1 validates production Supabase client config before building artifacts.'
    } else {
        Add-Fail 'Store Supabase config guard' 'store_release_build.ps1 does not require production Supabase client config before store builds.'
    }

    $gitignore = Read-RepoText '.gitignore'
    $missingAppleIgnores = @()
    foreach ($pattern in @('*.p12', '*.mobileprovision', '*.provisionprofile', 'AuthKey_*.p8', 'export_options*.plist')) {
        if ($null -eq $gitignore -or -not $gitignore.Contains($pattern)) {
            $missingAppleIgnores += $pattern
        }
    }

    if ($missingAppleIgnores.Count -eq 0) {
        Add-Pass 'Apple signing ignores' '.gitignore blocks common App Store signing and API-key artifacts.'
    } else {
        Add-Fail 'Apple signing ignores' "Missing .gitignore patterns: $($missingAppleIgnores -join ', ')."
    }
}

function Test-WebAndStoreConfig {
    $privacy = Read-RepoText 'web/privacy.html'
    $deletion = Read-RepoText 'web/account-deletion.html'
    $defaultSupportEmail = 'support@flowfit.com'
    $configuredSupportEmail = [Environment]::GetEnvironmentVariable('FLOWFIT_SUPPORT_EMAIL')
    $expectedSupportEmail = if ([string]::IsNullOrWhiteSpace($configuredSupportEmail)) {
        $defaultSupportEmail
    } else {
        $configuredSupportEmail.Trim()
    }

    if ($null -eq $privacy) {
        Add-Fail 'Public privacy page' 'Missing web/privacy.html.'
    } elseif ($privacy.Contains('<title>FlowFit Privacy Policy</title>')) {
        Add-Pass 'Public privacy page' 'web/privacy.html has the expected title.'
    } else {
        Add-Fail 'Public privacy page' 'web/privacy.html is missing the expected title.'
    }

    if ($null -eq $deletion) {
        Add-Fail 'Public account deletion page' 'Missing web/account-deletion.html.'
    } elseif ($deletion.Contains('<title>FlowFit Account Deletion</title>')) {
        Add-Pass 'Public account deletion page' 'web/account-deletion.html has the expected title.'
    } else {
        Add-Fail 'Public account deletion page' 'web/account-deletion.html is missing the expected title.'
    }

    if ($null -ne $privacy -and $null -ne $deletion -and $privacy.Contains('account-deletion.html') -and $deletion.Contains('privacy.html')) {
        Add-Pass 'Public compliance page links' 'Privacy and account deletion pages link to each other.'
    } else {
        Add-Fail 'Public compliance page links' 'Privacy and account deletion pages do not cross-link.'
    }

    $supportMailtoTerm = if ($null -ne $deletion -and $deletion.Contains("mailto:$expectedSupportEmail")) {
        "mailto:$expectedSupportEmail"
    } else {
        "mailto:$defaultSupportEmail"
    }

    $deletionRequiredTerms = @(
        $supportMailtoTerm,
        'FlowFit account deletion request',
        'associated app data',
        'without reinstalling the app',
        'Profile &gt; Settings &gt; Delete Account'
    )
    $missingDeletionTerms = @()
    foreach ($term in $deletionRequiredTerms) {
        if ($null -eq $deletion -or -not $deletion.Contains($term)) {
            $missingDeletionTerms += $term
        }
    }

    if ($missingDeletionTerms.Count -eq 0) {
        Add-Pass 'Public account deletion request path' 'Deletion page has email request, associated-data, no-reinstall, and in-app path wording.'
    } else {
        Add-Fail 'Public account deletion request path' "Deletion page is missing: $($missingDeletionTerms -join ', ')."
    }

    $activeSettings = Read-RepoText 'lib/screens/profile/settings/settings_screen.dart'
    if (
        $null -ne $activeSettings -and
        $activeSettings.Contains('Delete Account') -and
        $activeSettings.Contains("Navigator.pushNamed(context, '/delete-account')")
    ) {
        Add-Pass 'In-app account deletion path' 'Active settings screen exposes Profile > Settings > Delete Account.'
    } else {
        Add-Fail 'In-app account deletion path' 'Active settings screen must expose a Delete Account row that navigates to /delete-account.'
    }

    if ($null -ne $privacy -and $privacy.Contains('account and associated app data') -and $privacy.Contains('account-deletion.html')) {
        Add-Pass 'Privacy deletion disclosure' 'Privacy page links to account deletion and mentions associated app data.'
    } else {
        Add-Fail 'Privacy deletion disclosure' 'Privacy page must link to account deletion and mention associated app data.'
    }

    $webBaseUrl = [Environment]::GetEnvironmentVariable('FLOWFIT_PUBLIC_WEB_BASE_URL')
    $webBaseUrlResult = Test-PublicWebBaseUrl $webBaseUrl
    if (-not $webBaseUrlResult.Valid) {
        Add-Warn 'Public web deployment URL' $webBaseUrlResult.Detail
    } else {
        Add-Pass 'Public web deployment URL' $webBaseUrlResult.Detail
    }

    $filesWithDefaultSupport = @()
    $filesWithExpectedSupport = @()
    foreach ($path in @(
        'web/privacy.html',
        'web/account-deletion.html',
        'lib/screens/profile/settings/general/privacy_policy_screen.dart',
        'lib/screens/profile/settings/general/help_support_screen.dart',
        'lib/screens/profile/settings/general/about_us_screen.dart'
    )) {
        $content = Read-RepoText $path
        if ($null -ne $content -and $content.Contains('support@flowfit.com')) {
            $filesWithDefaultSupport += $path
        }
        if ($null -ne $content -and $content.Contains($expectedSupportEmail)) {
            $filesWithExpectedSupport += $path
        }
    }

    if ($filesWithExpectedSupport.Count -gt 0 -and -not $supportEmailVerifiedForAudit) {
        Add-Warn 'Production support inbox' "Configured support inbox $expectedSupportEmail appears in $($filesWithExpectedSupport.Count) public/in-app files; verify it before store submission."
    } elseif ($filesWithExpectedSupport.Count -gt 0) {
        Add-Pass 'Production support inbox' "Configured support inbox $expectedSupportEmail is present and marked verified for this audit run."
    } elseif ($expectedSupportEmail -ne $defaultSupportEmail -and $filesWithDefaultSupport.Count -gt 0 -and -not $supportEmailVerifiedForAudit) {
        Add-Warn 'Production support inbox' "Source templates still use $defaultSupportEmail; store_release_build.ps1 will replace it with configured support inbox $expectedSupportEmail, which still needs verification."
    } elseif ($expectedSupportEmail -ne $defaultSupportEmail -and $filesWithDefaultSupport.Count -gt 0) {
        Add-Pass 'Production support inbox' "Configured support inbox $expectedSupportEmail is marked verified; source templates use $defaultSupportEmail as the wrapper replacement token."
    } elseif ($filesWithDefaultSupport.Count -gt 0 -and -not $supportEmailVerifiedForAudit) {
        Add-Warn 'Production support inbox' "Default support@flowfit.com appears in $($filesWithDefaultSupport.Count) public/in-app files; verify or replace it before store submission."
    } elseif ($filesWithDefaultSupport.Count -gt 0) {
        Add-Pass 'Production support inbox' 'Default support@flowfit.com is present and marked verified for this audit run.'
    } else {
        Add-Fail 'Production support inbox' "No configured support inbox or source replacement token found in public/in-app support files."
    }
}

function Test-Tooling {
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        Add-Pass 'Docker tooling' 'Docker CLI is available for local Supabase validation.'
    } else {
        Add-Warn 'Docker tooling' 'Docker CLI is not available; local Supabase db reset/lint validation cannot run on this machine.' -StrictFailure $false
    }

    if (Get-Command supabase -ErrorAction SilentlyContinue) {
        Add-Pass 'Supabase CLI' 'Supabase CLI is available directly.'
    } elseif (Get-Command npx -ErrorAction SilentlyContinue) {
        Add-Pass 'Supabase CLI' 'npx is available for on-demand Supabase CLI commands, for example npx -y supabase@latest.'
    } else {
        Add-Warn 'Supabase CLI' 'Supabase CLI is not installed globally and npx is unavailable; use Supabase MCP after OAuth or install the CLI.' -StrictFailure $false
    }
}

Push-Location $repoRoot
try {
    Import-ReleaseEnvFile -Path $EnvFile
    $supportEmailVerifiedForAudit = $SupportEmailVerified -or (
        [Environment]::GetEnvironmentVariable('FLOWFIT_SUPPORT_EMAIL_VERIFIED') -eq 'true'
    )

    Write-Host '==> FlowFit release readiness audit'
    if ($Strict) {
        Write-Host 'Mode: strict pre-release'
    } else {
        Write-Host 'Mode: advisory'
    }

    Test-McpConfig
    Test-ReleaseEnvTemplate
    Test-Secrets
    Test-SupabaseMigration
    Test-SupabaseConfig
    Test-AndroidReleaseConfig
    Test-IosReleaseConfig
    Test-WebAndStoreConfig
    Test-Tooling

    Write-Host ''
    foreach ($result in $results) {
        Write-Host ("[{0}] {1} - {2}" -f $result.Level, $result.Name, $result.Detail)
    }

    $failCount = @($results | Where-Object { $_.Level -eq 'FAIL' }).Count
    $warnCount = @($results | Where-Object { $_.Level -eq 'WARN' }).Count
    $passCount = @($results | Where-Object { $_.Level -eq 'PASS' }).Count

    Write-Host ''
    Write-Host "Audit summary: $passCount pass, $warnCount warn, $failCount fail."

    if (-not [string]::IsNullOrWhiteSpace($OutFile)) {
        $outPath = $OutFile
        if (-not [System.IO.Path]::IsPathRooted($outPath)) {
            $outPath = Join-Path $repoRoot $outPath
        }

        $outDirectory = Split-Path -Parent $outPath
        if (-not [string]::IsNullOrWhiteSpace($outDirectory) -and -not (Test-Path $outDirectory)) {
            New-Item -ItemType Directory -Path $outDirectory -Force | Out-Null
        }

        [pscustomobject]@{
            generatedAt = (Get-Date).ToUniversalTime().ToString('o')
            mode = if ($Strict) { 'strict' } else { 'advisory' }
            supportEmailVerified = [bool]$supportEmailVerifiedForAudit
            summary = [pscustomobject]@{
                pass = $passCount
                warn = $warnCount
                fail = $failCount
            }
            results = @($results.ToArray())
        } | ConvertTo-Json -Depth 6 | Set-Content -Path $outPath

        Write-Host "Audit evidence written: $outPath"
    }

    if ($failCount -gt 0) {
        exit 1
    }
}
finally {
    Pop-Location
}
