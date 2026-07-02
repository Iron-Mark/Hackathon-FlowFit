param(
    [string]$SupabaseUrl = '',
    [string]$SupabasePublishableKey = '',
    [string]$Email = '',
    [string]$Password = '',
    [string]$EnvFile = '',
    [string]$OutFile = 'build/supabase-app-smoke.json',
    [switch]$AllowExternalWrites,
    [switch]$CreateSmokeUser,
    [switch]$AllowNonSmokeEmail,
    [switch]$AllowOverwriteExistingAppData,
    [switch]$SkipCleanup
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath

function Import-EnvFile {
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
        throw "Env file does not exist: $envPath"
    }

    foreach ($line in Get-Content -LiteralPath $envPath) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) {
            continue
        }
        if ($trimmed -notmatch '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$') {
            throw "Invalid env file line: $line"
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

function Get-OptionalEnv {
    param([Parameter(Mandatory = $true)][string]$Name)
    return [Environment]::GetEnvironmentVariable($Name)
}

function Test-PlaceholderValue {
    param([string]$Value)

    return (
        [string]::IsNullOrWhiteSpace($Value) -or
        $Value -match 'YOUR_|REPLACE_WITH|<your-|your[-_]|project_ref|placeholder|dnasghxxqwibwqnljvxr|(^|[./-])smoke($|[./-])|(^|[./:-])(example|invalid|test|localhost)(\.|/|:|$)|127\.0\.0\.1|\$\([^)]+\)'
    )
}

function Assert-SupabaseUrl {
    param([Parameter(Mandatory = $true)][string]$Value)

    if (Test-PlaceholderValue $Value) {
        throw 'SUPABASE_URL must be a real Supabase Project URL.'
    }
    if ($Value -notmatch '^https://[a-z0-9-]+\.supabase\.co/?$') {
        throw 'SUPABASE_URL must look like https://PROJECT_REF.supabase.co.'
    }
    return $Value.Trim().TrimEnd('/')
}

function Assert-SupabasePublishableKey {
    param([Parameter(Mandatory = $true)][string]$Value)

    if (
        (Test-PlaceholderValue $Value) -or
        $Value -match 'service_role|sb_secret_' -or
        $Value -notmatch '^sb_publishable_[A-Za-z0-9_-]{20,}$'
    ) {
        throw 'SUPABASE_PUBLISHABLE_KEY must be a real Supabase publishable client key, not a server-only key.'
    }
    return $Value.Trim()
}

function Resolve-LocalSecretValue {
    param([Parameter(Mandatory = $true)][string]$PropertyName)

    $secretsPath = Join-Path $repoRoot 'lib/secrets.dart'
    if (-not (Test-Path -LiteralPath $secretsPath)) {
        return ''
    }

    $source = Get-Content -Raw -LiteralPath $secretsPath
    $match = [regex]::Match(
        $source,
        "static const String $([regex]::Escape($PropertyName))\s*=\s*'([^']+)'"
    )
    if (-not $match.Success) {
        return ''
    }
    return $match.Groups[1].Value
}

function Assert-SmokeEmail {
    param([Parameter(Mandatory = $true)][string]$Value)

    $normalized = $Value.Trim()
    if (
        [string]::IsNullOrWhiteSpace($normalized) -or
        $normalized -notmatch '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    ) {
        throw 'FLOWFIT_SMOKE_EMAIL must be a valid email address.'
    }

    $lower = $normalized.ToLowerInvariant()
    $looksDedicated = $lower -match '(^|[+._-])flowfit[-_.]?smoke([+._-]|@)'

    if (-not $AllowNonSmokeEmail -and -not $looksDedicated) {
        throw 'Refusing to write app smoke data for a non-dedicated email. Use an address such as maintainer+flowfit-smoke@example.com or pass -AllowNonSmokeEmail after confirming it is a disposable test account.'
    }

    return $normalized
}

function Assert-RequiredSmokeInput {
    param(
        [string]$Value,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Detail
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "$Name is required. $Detail"
    }

    return $Value
}

function Assert-Password {
    param([Parameter(Mandatory = $true)][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value.Length -lt 8) {
        throw 'FLOWFIT_SMOKE_PASSWORD must be set for an existing confirmed Supabase test user or a first-run disposable smoke user created with -CreateSmokeUser.'
    }
    return $Value
}

function ConvertTo-JsonBody {
    param([Parameter(Mandatory = $true)]$Value)
    return ($Value | ConvertTo-Json -Depth 12 -Compress)
}

function Redact-SensitiveText {
    param([string]$Value)

    if ([string]::IsNullOrEmpty($Value)) {
        return $Value
    }

    $redacted = $Value
    $redacted = $redacted -replace '(?i)("access_token"\s*:\s*")[^"]+(")', '$1<redacted>$2'
    $redacted = $redacted -replace '(?i)("refresh_token"\s*:\s*")[^"]+(")', '$1<redacted>$2'
    $redacted = $redacted -replace '(?i)("apikey"\s*:\s*")[^"]+(")', '$1<redacted>$2'
    $redacted = $redacted -replace '(?i)(Bearer\s+)[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+', '$1<redacted>'
    return $redacted
}

function Invoke-JsonRequest {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][hashtable]$Headers,
        $Body = $null,
        [string]$Operation = ''
    )

    $args = @{
        Method = $Method
        Uri = $Uri
        Headers = $Headers
        ErrorAction = 'Stop'
        SkipHttpErrorCheck = $true
    }
    if ($null -ne $Body) {
        $args.Body = ConvertTo-JsonBody $Body
        $args.ContentType = 'application/json'
    }

    $response = Invoke-WebRequest @args
    $statusCode = [int]$response.StatusCode
    $responseBody = [string]$response.Content
    if ($statusCode -ge 400) {
        $operationPrefix = if ([string]::IsNullOrWhiteSpace($Operation)) { 'Supabase request' } else { $Operation }
        $safeBody = Redact-SensitiveText -Value $responseBody
        if ([string]::IsNullOrWhiteSpace($safeBody)) {
            throw "$operationPrefix failed with HTTP $statusCode."
        }
        throw "$operationPrefix failed with HTTP $($statusCode): $safeBody"
    }

    if ([string]::IsNullOrWhiteSpace($responseBody)) {
        return $null
    }

    return $responseBody | ConvertFrom-Json
}

function Select-FirstRow {
    param($Rows)

    if ($null -eq $Rows) {
        return $null
    }
    if ($Rows -is [System.Array]) {
        if ($Rows.Count -eq 0) {
            return $null
        }
        return $Rows[0]
    }
    return $Rows
}

function Get-RedactedEmail {
    param([Parameter(Mandatory = $true)][string]$Value)

    $parts = $Value.Split('@', 2)
    if ($parts.Count -ne 2) {
        return '<invalid-email>'
    }
    $local = $parts[0]
    $prefix = if ($local.Length -le 2) { $local.Substring(0, 1) } else { $local.Substring(0, 2) }
    return "$prefix***@$($parts[1])"
}

function Get-RestHeaders {
    param(
        [Parameter(Mandatory = $true)][string]$PublishableKey,
        [Parameter(Mandatory = $true)][string]$AccessToken,
        [hashtable]$ExtraHeaders = @{}
    )

    $headers = @{
        apikey = $PublishableKey
        Authorization = "Bearer $AccessToken"
        Accept = 'application/json'
    }
    foreach ($key in $ExtraHeaders.Keys) {
        $headers[$key] = $ExtraHeaders[$key]
    }
    return $headers
}

function Invoke-PasswordGrant {
    param(
        [Parameter(Mandatory = $true)][hashtable]$Headers,
        [Parameter(Mandatory = $true)][string]$Email,
        [Parameter(Mandatory = $true)][string]$Password
    )

    return Invoke-JsonRequest `
        -Method 'POST' `
        -Uri "$script:ResolvedSupabaseUrl/auth/v1/token?grant_type=password" `
        -Headers $Headers `
        -Operation 'auth password grant' `
        -Body @{
            email = $Email
            password = $Password
        }
}

function Invoke-SmokeUserSignup {
    param(
        [Parameter(Mandatory = $true)][hashtable]$Headers,
        [Parameter(Mandatory = $true)][string]$Email,
        [Parameter(Mandatory = $true)][string]$Password
    )

    return Invoke-JsonRequest `
        -Method 'POST' `
        -Uri "$script:ResolvedSupabaseUrl/auth/v1/signup" `
        -Headers $Headers `
        -Operation 'auth smoke user signup' `
        -Body @{
            email = $Email
            password = $Password
            data = @{
                purpose = 'flowfit-live-smoke'
                created_by = 'verify_supabase_app_smoke.ps1'
            }
        }
}

function Invoke-SupabaseRest {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$AccessToken,
        [hashtable]$ExtraHeaders = @{},
        $Body = $null
    )

    $uri = "$script:ResolvedSupabaseUrl/rest/v1/$Path"
    $headers = Get-RestHeaders `
        -PublishableKey $script:ResolvedPublishableKey `
        -AccessToken $AccessToken `
        -ExtraHeaders $ExtraHeaders
    return Invoke-JsonRequest -Method $Method -Uri $uri -Headers $headers -Body $Body -Operation "REST $Method $Path"
}

function Assert-SmokeOwnedExistingRows {
    param(
        [Parameter(Mandatory = $true)][string]$AccessToken,
        [Parameter(Mandatory = $true)][string]$UserId
    )

    if ($AllowOverwriteExistingAppData) {
        return
    }

    $profile = Select-FirstRow (Invoke-SupabaseRest `
        -Method 'GET' `
        -Path "user_profiles?user_id=eq.$UserId&select=nickname,full_name,survey_completed,is_kids_mode" `
        -AccessToken $AccessToken)
    if ($null -ne $profile) {
        $nickname = [string]$profile.nickname
        if ([string]::IsNullOrWhiteSpace($nickname) -or -not $nickname.StartsWith('FlowFitSmoke')) {
            throw 'Existing user_profiles row does not look smoke-owned. Use a dedicated smoke account or pass -AllowOverwriteExistingAppData.'
        }
    }

    $buddy = Select-FirstRow (Invoke-SupabaseRest `
        -Method 'GET' `
        -Path "buddy_profiles?user_id=eq.$UserId&select=name,color" `
        -AccessToken $AccessToken)
    if ($null -ne $buddy) {
        $name = [string]$buddy.name
        if ([string]::IsNullOrWhiteSpace($name) -or -not $name.StartsWith('FlowFitSmoke')) {
            throw 'Existing buddy_profiles row does not look smoke-owned. Use a dedicated smoke account or pass -AllowOverwriteExistingAppData.'
        }
    }
}

function Assert-FieldEquals {
    param(
        [Parameter(Mandatory = $true)]$Actual,
        [Parameter(Mandatory = $true)]$Expected,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if ($Actual -ne $Expected) {
        throw "Expected $Name to be '$Expected', got '$Actual'."
    }
}

function Assert-RowCount {
    param(
        $Rows,
        [Parameter(Mandatory = $true)][int]$Expected,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $actual = if ($null -eq $Rows) {
        0
    } elseif ($Rows -is [System.Array]) {
        $Rows.Count
    } else {
        1
    }

    if ($actual -ne $Expected) {
        throw "Expected $Name to return $Expected row(s), got $actual."
    }
}

Import-EnvFile -Path $EnvFile

if (-not $AllowExternalWrites) {
    throw 'This live smoke signs in and writes temporary rows to Supabase. Re-run with -AllowExternalWrites after choosing a dedicated confirmed smoke test account.'
}

$resolvedUrl = if (-not [string]::IsNullOrWhiteSpace($SupabaseUrl)) {
    $SupabaseUrl
} elseif (-not [string]::IsNullOrWhiteSpace((Get-OptionalEnv 'SUPABASE_URL'))) {
    Get-OptionalEnv 'SUPABASE_URL'
} else {
    Resolve-LocalSecretValue -PropertyName 'url'
}

$resolvedKey = if (-not [string]::IsNullOrWhiteSpace($SupabasePublishableKey)) {
    $SupabasePublishableKey
} elseif (-not [string]::IsNullOrWhiteSpace((Get-OptionalEnv 'SUPABASE_PUBLISHABLE_KEY'))) {
    Get-OptionalEnv 'SUPABASE_PUBLISHABLE_KEY'
} else {
    Resolve-LocalSecretValue -PropertyName 'publishableKey'
}

$resolvedEmail = if (-not [string]::IsNullOrWhiteSpace($Email)) {
    $Email
} elseif (-not [string]::IsNullOrWhiteSpace((Get-OptionalEnv 'FLOWFIT_SMOKE_EMAIL'))) {
    Get-OptionalEnv 'FLOWFIT_SMOKE_EMAIL'
} else {
    Get-OptionalEnv 'FLOWFIT_LIVE_SMOKE_EMAIL'
}

$resolvedPassword = if (-not [string]::IsNullOrWhiteSpace($Password)) {
    $Password
} elseif (-not [string]::IsNullOrWhiteSpace((Get-OptionalEnv 'FLOWFIT_SMOKE_PASSWORD'))) {
    Get-OptionalEnv 'FLOWFIT_SMOKE_PASSWORD'
} else {
    Get-OptionalEnv 'FLOWFIT_LIVE_SMOKE_PASSWORD'
}

$script:ResolvedSupabaseUrl = Assert-SupabaseUrl -Value $resolvedUrl
$script:ResolvedPublishableKey = Assert-SupabasePublishableKey -Value $resolvedKey
$resolvedEmail = Assert-RequiredSmokeInput `
    -Value $resolvedEmail `
    -Name 'FLOWFIT_SMOKE_EMAIL or -Email' `
    -Detail 'Set it to an existing confirmed disposable Supabase test user, for example maintainer+flowfit-smoke@example.com.'
$resolvedPassword = Assert-RequiredSmokeInput `
    -Value $resolvedPassword `
    -Name 'FLOWFIT_SMOKE_PASSWORD or -Password' `
    -Detail 'Set it to the password for the confirmed disposable Supabase smoke user.'
$resolvedEmail = Assert-SmokeEmail -Value $resolvedEmail
$resolvedPassword = Assert-Password -Value $resolvedPassword

$runId = "FlowFitSmoke$((Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss'))$([System.Guid]::NewGuid().ToString('N').Substring(0, 8))"
$buddyName = 'FlowFitSmokeBuddy'
$workoutId = [System.Guid]::NewGuid().ToString()
$heartRateId = [System.Guid]::NewGuid().ToString()
$supportRequestId = [System.Guid]::NewGuid().ToString()
$startedAt = (Get-Date).ToUniversalTime()
$endedAt = $startedAt.AddMinutes(1)
$epochMillis = [int64](([DateTimeOffset]$startedAt).ToUnixTimeMilliseconds())
$checks = New-Object System.Collections.Generic.List[object]
$cleanup = New-Object System.Collections.Generic.List[object]
$accessToken = ''
$userId = ''
$cleanupAttempted = $false

try {
    $authHeaders = @{
        apikey = $script:ResolvedPublishableKey
        Accept = 'application/json'
    }

    try {
        $authResponse = Invoke-PasswordGrant `
            -Headers $authHeaders `
            -Email $resolvedEmail `
            -Password $resolvedPassword
        $checks.Add([pscustomobject]@{ name = 'auth sign-in'; status = 'pass'; detail = 'Confirmed smoke user signed in.' })
    } catch {
        if (-not $CreateSmokeUser) {
            throw
        }

        $signupResponse = Invoke-SmokeUserSignup `
            -Headers $authHeaders `
            -Email $resolvedEmail `
            -Password $resolvedPassword

        $signupAccessToken = [string]$signupResponse.access_token
        $signupUserId = [string]$signupResponse.user.id
        if ([string]::IsNullOrWhiteSpace($signupAccessToken) -or [string]::IsNullOrWhiteSpace($signupUserId)) {
            throw 'Smoke user signup did not return an access token. Supabase email confirmation is probably enabled. Confirm the smoke user email or temporarily disable confirmation, then rerun without -CreateSmokeUser.'
        }

        $authResponse = $signupResponse
        $checks.Add([pscustomobject]@{ name = 'auth smoke user signup'; status = 'pass'; detail = 'Disposable smoke user created through Supabase client signup.' })
    }

    $accessToken = [string]$authResponse.access_token
    $userId = [string]$authResponse.user.id
    if ([string]::IsNullOrWhiteSpace($accessToken) -or [string]::IsNullOrWhiteSpace($userId)) {
        throw 'Supabase sign-in did not return an access token and auth user id. Confirm the smoke user email first.'
    }

    Assert-SmokeOwnedExistingRows -AccessToken $accessToken -UserId $userId
    $checks.Add([pscustomobject]@{ name = 'existing row ownership guard'; status = 'pass'; detail = 'Existing app rows are absent or smoke-owned.' })

    $profileRows = Invoke-SupabaseRest `
        -Method 'POST' `
        -Path 'user_profiles?on_conflict=user_id&select=user_id,nickname,is_kids_mode,survey_completed,wellness_goals,notifications_enabled' `
        -AccessToken $accessToken `
        -ExtraHeaders @{ Prefer = 'resolution=merge-duplicates,return=representation' } `
        -Body @{
            user_id = $userId
            full_name = $runId
            nickname = $runId
            is_kids_mode = $true
            survey_completed = $true
            wellness_goals = @('move_more', 'sleep_better')
            notifications_enabled = $true
        }
    $profile = Select-FirstRow $profileRows
    Assert-FieldEquals -Actual $profile.user_id -Expected $userId -Name 'user_profiles.user_id'
    Assert-FieldEquals -Actual $profile.nickname -Expected $runId -Name 'user_profiles.nickname'
    Assert-FieldEquals -Actual $profile.is_kids_mode -Expected $true -Name 'user_profiles.is_kids_mode'
    Assert-FieldEquals -Actual $profile.survey_completed -Expected $true -Name 'user_profiles.survey_completed'
    $checks.Add([pscustomobject]@{ name = 'profile onboarding upsert'; status = 'pass'; detail = 'user_profiles write/read passed through authenticated RLS.' })

    $buddyRows = Invoke-SupabaseRest `
        -Method 'POST' `
        -Path 'buddy_profiles?on_conflict=user_id&select=user_id,name,color,level,xp,unlocked_colors' `
        -AccessToken $accessToken `
        -ExtraHeaders @{ Prefer = 'resolution=merge-duplicates,return=representation' } `
        -Body @{
            user_id = $userId
            name = $buddyName
            color = 'blue'
            level = 1
            xp = 0
            unlocked_colors = @('blue')
        }
    $buddy = Select-FirstRow $buddyRows
    Assert-FieldEquals -Actual $buddy.user_id -Expected $userId -Name 'buddy_profiles.user_id'
    Assert-FieldEquals -Actual $buddy.name -Expected $buddyName -Name 'buddy_profiles.name'
    Assert-FieldEquals -Actual $buddy.color -Expected 'blue' -Name 'buddy_profiles.color'
    $checks.Add([pscustomobject]@{ name = 'buddy onboarding upsert'; status = 'pass'; detail = 'buddy_profiles write/read passed through authenticated RLS.' })

    $createdWorkoutRows = Invoke-SupabaseRest `
        -Method 'POST' `
        -Path 'workout_sessions?select=id,user_id,workout_type,status,goal_type,current_distance' `
        -AccessToken $accessToken `
        -ExtraHeaders @{ Prefer = 'return=representation' } `
        -Body @{
            id = $workoutId
            user_id = $userId
            workout_type = 'running'
            start_time = $startedAt.ToString('o')
            status = 'active'
            goal_type = 'duration'
            target_duration = 1
            current_distance = 0
        }
    $createdWorkout = Select-FirstRow $createdWorkoutRows
    Assert-FieldEquals -Actual $createdWorkout.id -Expected $workoutId -Name 'workout_sessions.id'
    Assert-FieldEquals -Actual $createdWorkout.status -Expected 'active' -Name 'workout_sessions.status'

    $updatedWorkoutRows = Invoke-SupabaseRest `
        -Method 'PATCH' `
        -Path "workout_sessions?id=eq.$workoutId&select=id,user_id,workout_type,status,duration_seconds,current_distance,calories_burned" `
        -AccessToken $accessToken `
        -ExtraHeaders @{ Prefer = 'return=representation' } `
        -Body @{
            end_time = $endedAt.ToString('o')
            status = 'completed'
            duration_seconds = 60
            current_distance = 0.1
            calories_burned = 12
        }
    $updatedWorkout = Select-FirstRow $updatedWorkoutRows
    Assert-FieldEquals -Actual $updatedWorkout.id -Expected $workoutId -Name 'workout_sessions.updated.id'
    Assert-FieldEquals -Actual $updatedWorkout.status -Expected 'completed' -Name 'workout_sessions.updated.status'
    Assert-FieldEquals -Actual $updatedWorkout.duration_seconds -Expected 60 -Name 'workout_sessions.duration_seconds'

    $listedWorkoutRows = Invoke-SupabaseRest `
        -Method 'GET' `
        -Path "workout_sessions?user_id=eq.$userId&id=eq.$workoutId&select=id,user_id,workout_type,status,duration_seconds,current_distance&order=start_time.desc" `
        -AccessToken $accessToken
    Assert-RowCount -Rows $listedWorkoutRows -Expected 1 -Name 'workout_sessions list before delete'
    $listedWorkout = Select-FirstRow $listedWorkoutRows
    Assert-FieldEquals -Actual $listedWorkout.id -Expected $workoutId -Name 'workout_sessions.listed.id'
    Assert-FieldEquals -Actual $listedWorkout.status -Expected 'completed' -Name 'workout_sessions.listed.status'

    $deletedWorkoutRows = Invoke-SupabaseRest `
        -Method 'DELETE' `
        -Path "workout_sessions?id=eq.$workoutId&select=id" `
        -AccessToken $accessToken `
        -ExtraHeaders @{ Prefer = 'return=representation' }
    Assert-RowCount -Rows $deletedWorkoutRows -Expected 1 -Name 'workout_sessions delete'
    $deletedWorkout = Select-FirstRow $deletedWorkoutRows
    Assert-FieldEquals -Actual $deletedWorkout.id -Expected $workoutId -Name 'workout_sessions.deleted.id'

    $postDeleteWorkoutRows = Invoke-SupabaseRest `
        -Method 'GET' `
        -Path "workout_sessions?id=eq.$workoutId&select=id" `
        -AccessToken $accessToken
    Assert-RowCount -Rows $postDeleteWorkoutRows -Expected 0 -Name 'workout_sessions list after delete'
    $checks.Add([pscustomobject]@{ name = 'workout create update list delete'; status = 'pass'; detail = 'workout_sessions insert/update/list/delete passed through authenticated RLS.' })

    $heartRows = Invoke-SupabaseRest `
        -Method 'POST' `
        -Path 'heart_rate?select=id,user_id,bpm,timestamp,status' `
        -AccessToken $accessToken `
        -ExtraHeaders @{ Prefer = 'return=representation' } `
        -Body @{
            id = $heartRateId
            user_id = $userId
            bpm = 72
            timestamp = $epochMillis
            status = 'smoke'
            ibi_values = @(800)
            raw_data = @{ source = 'verify_supabase_app_smoke.ps1' }
        }
    $heartRate = Select-FirstRow $heartRows
    Assert-FieldEquals -Actual $heartRate.id -Expected $heartRateId -Name 'heart_rate.id'
    Assert-FieldEquals -Actual $heartRate.bpm -Expected 72 -Name 'heart_rate.bpm'
    $checks.Add([pscustomobject]@{ name = 'heart rate insert list'; status = 'pass'; detail = 'heart_rate insert/read passed through authenticated RLS.' })

    $supportRows = Invoke-SupabaseRest `
        -Method 'POST' `
        -Path 'support_requests?select=id,user_id,category,subject,status,app_surface' `
        -AccessToken $accessToken `
        -ExtraHeaders @{ Prefer = 'return=representation' } `
        -Body @{
            id = $supportRequestId
            user_id = $userId
            user_email = $resolvedEmail
            category = 'support'
            subject = 'FlowFit smoke support request'
            message = "Support smoke request for $runId"
            app_surface = 'verify_supabase_app_smoke'
        }
    $supportRequest = Select-FirstRow $supportRows
    Assert-FieldEquals -Actual $supportRequest.id -Expected $supportRequestId -Name 'support_requests.id'
    Assert-FieldEquals -Actual $supportRequest.category -Expected 'support' -Name 'support_requests.category'
    Assert-FieldEquals -Actual $supportRequest.status -Expected 'open' -Name 'support_requests.status'

    $listedSupportRows = Invoke-SupabaseRest `
        -Method 'GET' `
        -Path "support_requests?id=eq.$supportRequestId&user_id=eq.$userId&select=id,user_id,category,subject,status" `
        -AccessToken $accessToken
    Assert-RowCount -Rows $listedSupportRows -Expected 1 -Name 'support_requests list before delete'

    $deletedSupportRows = Invoke-SupabaseRest `
        -Method 'DELETE' `
        -Path "support_requests?id=eq.$supportRequestId&select=id" `
        -AccessToken $accessToken `
        -ExtraHeaders @{ Prefer = 'return=representation' }
    Assert-RowCount -Rows $deletedSupportRows -Expected 1 -Name 'support_requests delete'
    $checks.Add([pscustomobject]@{ name = 'support request create read delete'; status = 'pass'; detail = 'support_requests insert/read/delete passed through authenticated RLS.' })
} finally {
    if (-not [string]::IsNullOrWhiteSpace($accessToken) -and -not [string]::IsNullOrWhiteSpace($userId) -and -not $SkipCleanup) {
        $cleanupAttempted = $true
        foreach ($target in @(
            @{ table = 'support_requests'; filter = "id=eq.$supportRequestId" },
            @{ table = 'heart_rate'; filter = "id=eq.$heartRateId" },
            @{ table = 'workout_sessions'; filter = "id=eq.$workoutId" },
            @{ table = 'buddy_profiles'; filter = "user_id=eq.$userId" },
            @{ table = 'user_profiles'; filter = "user_id=eq.$userId" }
        )) {
            try {
                $null = Invoke-SupabaseRest `
                    -Method 'DELETE' `
                    -Path "$($target.table)?$($target.filter)" `
                    -AccessToken $accessToken `
                    -ExtraHeaders @{ Prefer = 'return=minimal' }
                $cleanup.Add([pscustomobject]@{ table = $target.table; status = 'pass' })
            } catch {
                $cleanup.Add([pscustomobject]@{ table = $target.table; status = 'fail'; detail = $_.ToString() })
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($accessToken)) {
        try {
            $null = Invoke-JsonRequest `
                -Method 'POST' `
                -Uri "$script:ResolvedSupabaseUrl/auth/v1/logout" `
                -Headers (Get-RestHeaders -PublishableKey $script:ResolvedPublishableKey -AccessToken $accessToken) `
                -Operation 'auth sign-out'
            $cleanup.Add([pscustomobject]@{ table = 'auth.sessions'; status = 'pass' })
        } catch {
            $cleanup.Add([pscustomobject]@{ table = 'auth.sessions'; status = 'fail'; detail = $_.ToString() })
        }
    }
}

$failedCleanup = @($cleanup | Where-Object { $_.status -ne 'pass' })
$status = if ($failedCleanup.Count -eq 0) { 'PASS' } else { 'FAIL' }
$summary = [pscustomobject]@{
    status = $status
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    supabaseHost = ([System.Uri]$script:ResolvedSupabaseUrl).Host
    smokeEmail = Get-RedactedEmail -Value $resolvedEmail
    smokeUserId = $userId
    checks = $checks
    cleanupAttempted = $cleanupAttempted
    cleanup = $cleanup
    skippedCleanup = [bool]$SkipCleanup
}

$outPath = if ([System.IO.Path]::IsPathRooted($OutFile)) {
    $OutFile
} else {
    Join-Path $repoRoot $OutFile
}
$outDir = Split-Path -Parent $outPath
if (-not [string]::IsNullOrWhiteSpace($outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}
$summary | ConvertTo-Json -Depth 12 | Set-Content -Encoding UTF8 -LiteralPath $outPath

if ($status -ne 'PASS') {
    throw "Supabase app smoke passed functional checks but cleanup failed. Review $outPath."
}

Write-Host "Supabase app smoke passed: $($checks.Count) checks."
Write-Host "Evidence written: $outPath"
Write-Host 'SUPABASE_APP_SMOKE_OK'
