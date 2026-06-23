param(
    [string]$Device = '',
    [string]$EnvFile = '',
    [string]$Email = '',
    [string]$Password = '',
    [string]$OutFile = 'build/android-live-auth-smoke-latest.json',
    [string]$TargetPlatform = 'android-x64',
    [string]$ApkPath = '',
    [switch]$SkipBuild,
    [switch]$KeepAppData,
    [int]$WaitTimeoutSeconds = 45
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$packageName = 'com.msiazondev.flowfit'
$mainActivity = "$packageName/.MainActivity"
$artifactRoot = Join-Path $repoRoot 'build/android-live-auth-smoke'

$script:checks = New-Object System.Collections.Generic.List[object]
$script:artifacts = [ordered]@{}
$script:status = 'running'
$script:errorMessage = ''
$script:adbPath = ''
$script:deviceSerial = ''
$script:deviceInfo = [ordered]@{}
$script:supabaseConfigSource = ''
$script:supabaseProjectHost = ''
$script:smokeEmail = ''
$script:screenSize = [ordered]@{ width = 1080; height = 1920 }

function Add-Check {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Status,
        [string]$Detail = ''
    )

    $script:checks.Add([pscustomobject]@{
        name = $Name
        status = $Status
        detail = $Detail
    }) | Out-Null
}

function Add-Artifact {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $script:artifacts[$Name] = (Resolve-Path -LiteralPath $Path).Path
}

function Assert-Condition {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Failure,
        [string]$Detail = ''
    )

    if ($Condition) {
        Add-Check -Name $Name -Status 'pass' -Detail $Detail
        return
    }

    Add-Check -Name $Name -Status 'fail' -Detail $Failure
    throw $Failure
}

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

function Assert-SupabasePublishableKey {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Value
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
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$PublishableKey
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
    $envUrl = Get-OptionalEnv 'SUPABASE_URL'
    $envKey = Get-OptionalEnv 'SUPABASE_PUBLISHABLE_KEY'
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
        throw 'Android live auth smoke requires SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY, or ignored lib/secrets.dart.'
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
    if ($lower -notmatch '(^|[+._-])flowfit[-_.]?smoke([+._-]|@)') {
        throw 'Refusing live Android auth against a non-dedicated email. Use FLOWFIT_SMOKE_EMAIL for a disposable FlowFit smoke account.'
    }

    return $normalized
}

function Assert-Password {
    param([Parameter(Mandatory = $true)][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value.Length -lt 8) {
        throw 'FLOWFIT_SMOKE_PASSWORD must be set for the confirmed disposable Supabase smoke user.'
    }
    return $Value
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

function Resolve-SmokeCredentials {
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

    $resolvedEmail = Assert-SmokeEmail -Value $resolvedEmail
    $resolvedPassword = Assert-Password -Value $resolvedPassword

    return [pscustomobject]@{
        Email = $resolvedEmail
        Password = $resolvedPassword
        RedactedEmail = Get-RedactedEmail -Value $resolvedEmail
    }
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
        [Parameter(Mandatory = $true)]$Config,
        [Parameter(Mandatory = $true)]$Credentials,
        [Parameter(Mandatory = $true)][string]$Operation
    )

    return Invoke-JsonRequest `
        -Method 'POST' `
        -Uri "$($Config.Url.TrimEnd('/'))/auth/v1/token?grant_type=password" `
        -Headers @{
            apikey = $Config.PublishableKey
            Accept = 'application/json'
        } `
        -Operation $Operation `
        -Body @{
            email = $Credentials.Email
            password = $Credentials.Password
        }
}

function Invoke-SupabaseRest {
    param(
        [Parameter(Mandatory = $true)]$Config,
        [Parameter(Mandatory = $true)][string]$AccessToken,
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Path,
        [hashtable]$ExtraHeaders = @{},
        $Body = $null,
        [string]$Operation = ''
    )

    $operationName = if ([string]::IsNullOrWhiteSpace($Operation)) {
        "REST $Method $Path"
    } else {
        $Operation
    }

    return Invoke-JsonRequest `
        -Method $Method `
        -Uri "$($Config.Url.TrimEnd('/'))/rest/v1/$Path" `
        -Headers (Get-RestHeaders `
            -PublishableKey $Config.PublishableKey `
            -AccessToken $AccessToken `
            -ExtraHeaders $ExtraHeaders) `
        -Body $Body `
        -Operation $operationName
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

function Invoke-SmokeRestSignOut {
    param(
        [Parameter(Mandatory = $true)]$Config,
        [Parameter(Mandatory = $true)][string]$AccessToken,
        [Parameter(Mandatory = $true)][string]$Operation
    )

    Invoke-JsonRequest `
        -Method 'POST' `
        -Uri "$($Config.Url.TrimEnd('/'))/auth/v1/logout" `
        -Headers (Get-RestHeaders `
            -PublishableKey $Config.PublishableKey `
            -AccessToken $AccessToken) `
        -Operation $Operation | Out-Null
}

function Invoke-SmokeBackendDataCleanup {
    param(
        [Parameter(Mandatory = $true)]$Config,
        [Parameter(Mandatory = $true)]$Credentials,
        [Parameter(Mandatory = $true)][string]$Phase
    )

    $accessToken = ''
    try {
        $authResponse = Invoke-PasswordGrant `
            -Config $Config `
            -Credentials $Credentials `
            -Operation "$Phase smoke cleanup auth"
        $accessToken = [string]$authResponse.access_token
        $userId = [string]$authResponse.user.id
        if ([string]::IsNullOrWhiteSpace($accessToken) -or [string]::IsNullOrWhiteSpace($userId)) {
            throw "$Phase smoke cleanup auth did not return an access token and user id."
        }

        foreach ($target in @(
            @{ table = 'heart_rate'; filter = "user_id=eq.$userId" },
            @{ table = 'workout_sessions'; filter = "user_id=eq.$userId" },
            @{ table = 'buddy_profiles'; filter = "user_id=eq.$userId" },
            @{ table = 'user_profiles'; filter = "user_id=eq.$userId" }
        )) {
            Invoke-SupabaseRest `
                -Config $Config `
                -AccessToken $accessToken `
                -Method 'DELETE' `
                -Path "$($target.table)?$($target.filter)" `
                -ExtraHeaders @{ Prefer = 'return=minimal' } `
                -Operation "$Phase smoke cleanup $($target.table)" | Out-Null
        }

        Add-Check -Name "supabase.$Phase.cleanupRows" -Status 'pass' -Detail 'Cleaned app-owned smoke rows with authenticated RLS.'
        return $userId
    } finally {
        if (-not [string]::IsNullOrWhiteSpace($accessToken)) {
            Invoke-SmokeRestSignOut `
                -Config $Config `
                -AccessToken $accessToken `
                -Operation "$Phase smoke cleanup sign-out"
        }
    }
}

function Assert-SmokeProfileCompleted {
    param(
        [Parameter(Mandatory = $true)]$Config,
        [Parameter(Mandatory = $true)]$Credentials
    )

    $accessToken = ''
    try {
        $authResponse = Invoke-PasswordGrant `
            -Config $Config `
            -Credentials $Credentials `
            -Operation 'post-onboarding profile verification auth'
        $accessToken = [string]$authResponse.access_token
        $userId = [string]$authResponse.user.id
        if ([string]::IsNullOrWhiteSpace($accessToken) -or [string]::IsNullOrWhiteSpace($userId)) {
            throw 'Profile verification auth did not return an access token and user id.'
        }

        $profile = Select-FirstRow (Invoke-SupabaseRest `
            -Config $Config `
            -AccessToken $accessToken `
            -Method 'GET' `
            -Path "user_profiles?user_id=eq.$userId&select=user_id,gender,height,weight,activity_level,survey_completed,daily_calorie_target,daily_steps_target,daily_active_minutes_target,daily_water_target" `
            -Operation 'post-onboarding profile verification read')

        if ($null -eq $profile) {
            throw 'Completed survey did not create a user_profiles row.'
        }
        if ($profile.user_id -ne $userId -or $profile.survey_completed -ne $true) {
            throw 'Completed survey profile row did not match the authenticated user or was not marked complete.'
        }
        if (
            [string]$profile.gender -ne 'male' -or
            [double]$profile.height -le 0 -or
            [double]$profile.weight -le 0 -or
            [string]$profile.activity_level -ne 'sedentary' -or
            [int]$profile.daily_steps_target -le 0 -or
            [int]$profile.daily_active_minutes_target -le 0 -or
            [double]$profile.daily_water_target -le 0
        ) {
            throw 'Completed survey profile row is missing expected survey fields.'
        }

        Add-Check -Name 'supabase.profileCompleted' -Status 'pass' -Detail 'Completed survey profile row exists and is marked complete.'
    } finally {
        if (-not [string]::IsNullOrWhiteSpace($accessToken)) {
            Invoke-SmokeRestSignOut `
                -Config $Config `
                -AccessToken $accessToken `
                -Operation 'post-onboarding profile verification sign-out'
        }
    }
}

function Assert-SmokeBuddyCompleted {
    param(
        [Parameter(Mandatory = $true)]$Config,
        [Parameter(Mandatory = $true)]$Credentials,
        [Parameter(Mandatory = $true)][string]$ExpectedName,
        [Parameter(Mandatory = $true)][string]$ExpectedColor,
        [Parameter(Mandatory = $true)][string]$ExpectedNickname,
        [Parameter(Mandatory = $true)][int]$ExpectedAge,
        [Parameter(Mandatory = $true)][string]$ExpectedGoal,
        [Parameter(Mandatory = $true)][bool]$ExpectedNotificationsEnabled
    )

    $accessToken = ''
    try {
        $authResponse = Invoke-PasswordGrant `
            -Config $Config `
            -Credentials $Credentials `
            -Operation 'post-buddy verification auth'
        $accessToken = [string]$authResponse.access_token
        $userId = [string]$authResponse.user.id
        if ([string]::IsNullOrWhiteSpace($accessToken) -or [string]::IsNullOrWhiteSpace($userId)) {
            throw 'Buddy verification auth did not return an access token and user id.'
        }

        $buddy = Select-FirstRow (Invoke-SupabaseRest `
            -Config $Config `
            -AccessToken $accessToken `
            -Method 'GET' `
            -Path "buddy_profiles?user_id=eq.$userId&select=user_id,name,color,level,xp,unlocked_colors" `
            -Operation 'post-buddy verification buddy read')

        if ($null -eq $buddy) {
            throw 'Completed Buddy onboarding did not create a buddy_profiles row.'
        }
        $unlockedColors = @($buddy.unlocked_colors)
        if (
            $buddy.user_id -ne $userId -or
            [string]$buddy.name -ne $ExpectedName -or
            [string]$buddy.color -ne $ExpectedColor -or
            [int]$buddy.level -ne 1 -or
            [int]$buddy.xp -ne 0 -or
            ($unlockedColors -notcontains $ExpectedColor)
        ) {
            throw 'Completed Buddy profile row did not match expected live-smoke values.'
        }

        $profile = Select-FirstRow (Invoke-SupabaseRest `
            -Config $Config `
            -AccessToken $accessToken `
            -Method 'GET' `
            -Path "user_profiles?user_id=eq.$userId&select=user_id,nickname,age,is_kids_mode,wellness_goals,notifications_enabled,survey_completed" `
            -Operation 'post-buddy verification profile read')

        if ($null -eq $profile) {
            throw 'Completed Buddy onboarding did not leave a user_profiles row.'
        }
        $wellnessGoals = @($profile.wellness_goals)
        if (
            $profile.user_id -ne $userId -or
            [string]$profile.nickname -ne $ExpectedNickname -or
            [int]$profile.age -ne $ExpectedAge -or
            $profile.is_kids_mode -ne $true -or
            $profile.survey_completed -ne $true -or
            $profile.notifications_enabled -ne $ExpectedNotificationsEnabled -or
            ($wellnessGoals -notcontains $ExpectedGoal)
        ) {
            throw 'Completed Buddy user profile fields did not match expected live-smoke values.'
        }

        Add-Check -Name 'supabase.buddyCompleted' -Status 'pass' -Detail 'Buddy profile row and Buddy user profile fields passed through authenticated RLS.'
    } finally {
        if (-not [string]::IsNullOrWhiteSpace($accessToken)) {
            Invoke-SmokeRestSignOut `
                -Config $Config `
                -AccessToken $accessToken `
                -Operation 'post-buddy verification sign-out'
        }
    }
}

function Resolve-AdbPath {
    foreach ($rootName in @('ANDROID_HOME', 'ANDROID_SDK_ROOT', 'LOCALAPPDATA')) {
        $rootValue = [Environment]::GetEnvironmentVariable($rootName)
        if ([string]::IsNullOrWhiteSpace($rootValue)) {
            continue
        }

        $candidate = if ($rootName -eq 'LOCALAPPDATA') {
            Join-Path $rootValue 'Android/Sdk/platform-tools/adb.exe'
        } else {
            Join-Path $rootValue 'platform-tools/adb.exe'
        }
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $pathCommand = Get-Command adb -ErrorAction SilentlyContinue
    if ($pathCommand) {
        return $pathCommand.Source
    }

    throw 'adb was not found on PATH or under ANDROID_HOME / ANDROID_SDK_ROOT / LOCALAPPDATA Android SDK paths.'
}

function Invoke-External {
    param(
        [Parameter(Mandatory = $true)][string]$File,
        [string[]]$Arguments = @(),
        [switch]$AllowFailure,
        [switch]$Sensitive
    )

    $output = & $File @Arguments 2>&1 | ForEach-Object { $_.ToString() }
    $exitCode = $LASTEXITCODE
    if (-not $AllowFailure -and $exitCode -ne 0) {
        if ($Sensitive) {
            throw "$File sensitive command failed with exit code $exitCode."
        }
        throw "$File $($Arguments -join ' ') failed with exit code $exitCode.`n$($output -join "`n")"
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($output)
    }
}

function Invoke-ExternalWithTimeout {
    param(
        [Parameter(Mandatory = $true)][string]$File,
        [string[]]$Arguments = @(),
        [int]$TimeoutSeconds = 10
    )

    $tempId = [guid]::NewGuid().ToString('N')
    $stdoutPath = Join-Path ([System.IO.Path]::GetTempPath()) "flowfit-$tempId.stdout.log"
    $stderrPath = Join-Path ([System.IO.Path]::GetTempPath()) "flowfit-$tempId.stderr.log"
    try {
        $process = Start-Process `
            -FilePath $File `
            -ArgumentList $Arguments `
            -PassThru `
            -WindowStyle Hidden `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath

        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            try {
                $process.Kill($true)
            } catch {
                # Best effort: callers use this only for optional diagnostics.
            }
            return [pscustomobject]@{
                ExitCode = 124
                TimedOut = $true
                Output = @("Command timed out after $TimeoutSeconds seconds.")
            }
        }

        $output = @()
        if (Test-Path -LiteralPath $stdoutPath) {
            $output += @(Get-Content -LiteralPath $stdoutPath -ErrorAction SilentlyContinue)
        }
        if (Test-Path -LiteralPath $stderrPath) {
            $output += @(Get-Content -LiteralPath $stderrPath -ErrorAction SilentlyContinue)
        }

        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            TimedOut = $false
            Output = @($output)
        }
    } catch {
        return [pscustomobject]@{
            ExitCode = 1
            TimedOut = $false
            Output = @($_.Exception.Message)
        }
    } finally {
        try {
            if (Test-Path -LiteralPath $stdoutPath) {
                Remove-Item -LiteralPath $stdoutPath -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path -LiteralPath $stderrPath) {
                Remove-Item -LiteralPath $stderrPath -Force -ErrorAction SilentlyContinue
            }
        } catch {
            # Best effort cleanup only.
        }
    }
}

function Invoke-Adb {
    param(
        [string[]]$Arguments,
        [switch]$AllowFailure,
        [switch]$Sensitive
    )

    return Invoke-External `
        -File $script:adbPath `
        -Arguments (@('-s', $script:deviceSerial) + $Arguments) `
        -AllowFailure:$AllowFailure `
        -Sensitive:$Sensitive
}

function Invoke-AdbWithTimeout {
    param(
        [string[]]$Arguments,
        [int]$TimeoutSeconds = 10
    )

    return Invoke-ExternalWithTimeout `
        -File $script:adbPath `
        -Arguments (@('-s', $script:deviceSerial) + $Arguments) `
        -TimeoutSeconds $TimeoutSeconds
}

function Resolve-DeviceSerial {
    param([string]$RequestedDevice)

    if (-not [string]::IsNullOrWhiteSpace($RequestedDevice)) {
        return $RequestedDevice.Trim()
    }

    $devices = Invoke-External -File $script:adbPath -Arguments @('devices')
    $connected = @(
        $devices.Output |
            Where-Object { $_ -match '^(\S+)\s+device$' } |
            ForEach-Object { $matches[1] }
    )

    if ($connected.Count -eq 0) {
        throw 'No connected Android device or emulator is visible in adb devices.'
    }
    if ($connected.Count -gt 1) {
        throw "Multiple Android devices are connected. Pass -Device explicitly. Devices: $($connected -join ', ')"
    }

    return $connected[0]
}

function Get-AdbShellText {
    param([string[]]$Arguments)

    $result = Invoke-Adb -Arguments (@('shell') + $Arguments)
    return (($result.Output -join "`n").Trim())
}

function Wait-ForAndroidRuntimeReady {
    $deadline = (Get-Date).AddSeconds([Math]::Max($WaitTimeoutSeconds, 90))
    $lastError = ''

    do {
        $services = Invoke-Adb -Arguments @('shell', 'service', 'list') -AllowFailure
        $screen = Invoke-Adb -Arguments @('shell', 'wm', 'size') -AllowFailure
        $serviceText = $services.Output -join "`n"
        $screenText = $screen.Output -join "`n"

        if (
            $services.ExitCode -eq 0 -and
            $screen.ExitCode -eq 0 -and
            $serviceText -match '\bactivity:' -and
            $serviceText -match '\bpackage:' -and
            $serviceText -match '\bwindow:' -and
            $screenText -match 'Physical size:\s*\d+x\d+'
        ) {
            Add-Check -Name 'adb.runtimeReady' -Status 'pass' -Detail 'Android activity, package, and window services are ready.'
            return
        }

        $lastError = "serviceExit=$($services.ExitCode); wmExit=$($screen.ExitCode); wm=$screenText"
        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)

    Add-Check -Name 'adb.runtimeReady' -Status 'fail' -Detail $lastError
    throw "Android runtime services were not ready before timeout. $lastError"
}

function Install-ApkWithRetry {
    param([Parameter(Mandatory = $true)][string]$Path)

    $lastOutput = ''
    foreach ($attempt in 1..3) {
        Wait-ForAndroidRuntimeReady
        $install = Invoke-Adb `
            -Arguments @('install', '--no-streaming', '-r', '-d', $Path) `
            -AllowFailure
        $lastOutput = $install.Output -join "`n"

        if ($install.ExitCode -eq 0) {
            Add-Check `
                -Name 'adb.install' `
                -Status 'pass' `
                -Detail "Installed debug APK on attempt $attempt."
            return
        }

        Add-Check `
            -Name "adb.install.retry$attempt" `
            -Status 'warn' `
            -Detail "APK install attempt $attempt failed with exit code $($install.ExitCode)."
        Start-Sleep -Seconds (2 * $attempt)
    }

    throw "$script:adbPath -s $script:deviceSerial install --no-streaming -r -d $Path failed after 3 attempts.`n$lastOutput"
}

function Start-AppWithRetry {
    $lastOutput = ''
    foreach ($attempt in 1..3) {
        Wait-ForAndroidRuntimeReady
        $launch = Invoke-Adb `
            -Arguments @(
                'shell',
                'am',
                'start',
                '-W',
                '-a',
                'android.intent.action.MAIN',
                '-c',
                'android.intent.category.LAUNCHER',
                '-n',
                $mainActivity
            ) `
            -AllowFailure
        $lastOutput = $launch.Output -join "`n"

        if ($launch.ExitCode -eq 0 -and $lastOutput -match 'Status:\s+ok') {
            Add-Check -Name 'adb.launchStatus' -Status 'pass' -Detail "am start -W returned Status: ok on attempt $attempt."
            return
        }

        Add-Check `
            -Name "adb.launch.retry$attempt" `
            -Status 'warn' `
            -Detail "App launch attempt $attempt failed with exit code $($launch.ExitCode)."
        Start-Sleep -Seconds (2 * $attempt)
    }

    throw "Android launch did not report Status: ok after 3 attempts.`n$lastOutput"
}

function Update-DeviceInfo {
    $model = Get-AdbShellText -Arguments @('getprop', 'ro.product.model')
    $androidRelease = Get-AdbShellText -Arguments @('getprop', 'ro.build.version.release')
    $androidSdk = Get-AdbShellText -Arguments @('getprop', 'ro.build.version.sdk')
    $screen = Get-AdbShellText -Arguments @('wm', 'size')

    if ($screen -match 'Physical size:\s*(\d+)x(\d+)') {
        $script:screenSize.width = [int]$matches[1]
        $script:screenSize.height = [int]$matches[2]
    }

    $script:deviceInfo = [ordered]@{
        serial = $script:deviceSerial
        model = $model
        androidRelease = $androidRelease
        androidSdk = $androidSdk
        screen = $script:screenSize
    }
}

function Resolve-ApkPath {
    param([string]$Platform)

    if (-not [string]::IsNullOrWhiteSpace($ApkPath)) {
        $path = if ([System.IO.Path]::IsPathRooted($ApkPath)) {
            $ApkPath
        } else {
            Join-Path $repoRoot $ApkPath
        }
        return $path
    }

    $abiName = switch ($Platform) {
        'android-x64' { 'x86_64' }
        'android-arm64' { 'arm64-v8a' }
        'android-arm' { 'armeabi-v7a' }
        default { throw "Unsupported target platform for split APK smoke: $Platform" }
    }

    return Join-Path $repoRoot "build/app/outputs/flutter-apk/app-$abiName-debug.apk"
}

function Save-UiDump {
    param([Parameter(Mandatory = $true)][string]$Name)

    $remotePath = '/sdcard/flowfit-live-auth-window.xml'
    Invoke-Adb -Arguments @('shell', 'rm', '-f', $remotePath) -AllowFailure | Out-Null
    $dumpAttempts = @(
        @('shell', 'uiautomator', 'dump', $remotePath),
        @('shell', 'uiautomator', 'dump', '--compressed', $remotePath)
    )
    $dumpSucceeded = $false
    $lastDumpText = ''
    foreach ($dumpArguments in $dumpAttempts) {
        $dump = Invoke-Adb -Arguments $dumpArguments -AllowFailure
        $dumpText = $dump.Output -join "`n"
        if (
            $dump.ExitCode -eq 0 -and
            $dumpText -notmatch 'ERROR|could not get idle state|No such file'
        ) {
            $dumpSucceeded = $true
            break
        }
        $lastDumpText = $dumpText
        Start-Sleep -Milliseconds 300
    }
    if (-not $dumpSucceeded) {
        throw "uiautomator dump failed for $Name.`n$lastDumpText"
    }

    $cat = Invoke-Adb -Arguments @('exec-out', 'cat', $remotePath) -AllowFailure
    $xml = $cat.Output -join "`n"
    if (
        $cat.ExitCode -ne 0 -or
        $xml -notmatch '<hierarchy\b' -or
        $xml -match '^cat: .*No such file'
    ) {
        throw "uiautomator dump file was not readable for $Name."
    }
    if (
        -not [string]::IsNullOrWhiteSpace($packageName) -and
        $xml -notmatch ('package="' + [regex]::Escape($packageName) + '"')
    ) {
        $packageMatch = [regex]::Match($xml, 'package="([^"]+)"')
        $actualPackage = if ($packageMatch.Success) { $packageMatch.Groups[1].Value } else { 'unknown' }
        throw "uiautomator dump for $Name came from unexpected package $actualPackage; expected $packageName."
    }

    $localPath = Join-Path $artifactRoot "$Name.xml"
    Set-Content -LiteralPath $localPath -Value $xml -Encoding UTF8
    Add-Artifact -Name "uiDump.$Name" -Path $localPath
    return $xml
}

function Save-Screenshot {
    param([Parameter(Mandatory = $true)][string]$Name)

    $remotePath = "/sdcard/flowfit-live-auth-$Name.png"
    $localPath = Join-Path $artifactRoot "$Name.png"
    Invoke-Adb -Arguments @('shell', 'screencap', '-p', $remotePath) | Out-Null
    Invoke-Adb -Arguments @('pull', $remotePath, $localPath) | Out-Null
    Invoke-Adb -Arguments @('shell', 'rm', '-f', $remotePath) -AllowFailure | Out-Null
    Add-Artifact -Name "screenshot.$Name" -Path $localPath
}

function Save-Logcat {
    param([string]$Name = 'logcat')

    if ([string]::IsNullOrWhiteSpace($script:adbPath) -or [string]::IsNullOrWhiteSpace($script:deviceSerial)) {
        return
    }

    $logcat = Invoke-AdbWithTimeout -Arguments @('logcat', '-d', '-t', '4000', '-v', 'time') -TimeoutSeconds 10
    if ($logcat.ExitCode -ne 0 -and -not $logcat.TimedOut) {
        return
    }

    $logPath = Join-Path $artifactRoot "$Name.txt"
    $logText = if ($logcat.TimedOut) {
        "logcat capture timed out after 10 seconds.`n$($logcat.Output -join "`n")"
    } else {
        $logcat.Output -join "`n"
    }
    $logText = $logText `
        -replace 'sb_publishable_[A-Za-z0-9_\-.]+', 'sb_publishable_[REDACTED]' `
        -replace 'postgresql://[^\s]+', 'postgresql://[REDACTED]' `
        -replace '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}', '[EMAIL_REDACTED]'
    Set-Content -LiteralPath $logPath -Value $logText -Encoding UTF8
    Add-Artifact -Name $Name -Path $logPath
}

function ConvertTo-XmlText {
    param([Parameter(Mandatory = $true)][string]$Text)

    return [System.Security.SecurityElement]::Escape($Text)
}

function Test-UiContains {
    param(
        [Parameter(Mandatory = $true)][string]$Xml,
        [Parameter(Mandatory = $true)][string]$Text
    )

    return $Xml.Contains($Text) -or $Xml.Contains((ConvertTo-XmlText -Text $Text))
}

function Get-UiTextBounds {
    param(
        [Parameter(Mandatory = $true)][string]$Xml,
        [Parameter(Mandatory = $true)][string]$Text,
        [switch]$Contains
    )

    $candidates = @($Text, (ConvertTo-XmlText -Text $Text)) | Select-Object -Unique
    $match = $null
    foreach ($candidate in $candidates) {
        $escaped = [regex]::Escape($candidate)
        $textPattern = if ($Contains) {
            '[^"]*' + $escaped + '[^"]*'
        } else {
            $escaped
        }
        $pattern = '<node\b(?=[^>]*(?:text|content-desc)="' + $textPattern + '")(?=[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]")[^>]*>'
        $match = [regex]::Match($Xml, $pattern)
        if ($match.Success) {
            break
        }
    }
    if ($null -eq $match -or -not $match.Success) {
        return $null
    }

    $left = [int]$match.Groups[1].Value
    $top = [int]$match.Groups[2].Value
    $right = [int]$match.Groups[3].Value
    $bottom = [int]$match.Groups[4].Value

    return [pscustomobject]@{
        left = $left
        top = $top
        right = $right
        bottom = $bottom
        centerX = [math]::Floor(($left + $right) / 2)
        centerY = [math]::Floor(($top + $bottom) / 2)
    }
}

function Get-ClosestUiTextBounds {
    param(
        [Parameter(Mandatory = $true)][string]$Xml,
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][int]$TargetY
    )

    $escaped = [regex]::Escape($Text)
    $pattern = '<node\b(?=[^>]*(?:text|content-desc)="' + $escaped + '")(?=[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]")[^>]*>'
    $matches = [regex]::Matches($Xml, $pattern)
    if ($matches.Count -eq 0) {
        return $null
    }

    $bounds = @(
        foreach ($match in $matches) {
            $left = [int]$match.Groups[1].Value
            $top = [int]$match.Groups[2].Value
            $right = [int]$match.Groups[3].Value
            $bottom = [int]$match.Groups[4].Value
            $centerY = [math]::Floor(($top + $bottom) / 2)
            [pscustomobject]@{
                left = $left
                top = $top
                right = $right
                bottom = $bottom
                centerX = [math]::Floor(($left + $right) / 2)
                centerY = $centerY
                distance = [math]::Abs($centerY - $TargetY)
            }
        }
    )

    return $bounds | Sort-Object distance | Select-Object -First 1
}

function Wait-ForUiText {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string[]]$RequiredText,
        [string[]]$ForbiddenText = @()
    )

    $deadline = (Get-Date).AddSeconds($WaitTimeoutSeconds)
    $lastXml = ''
    $lastDumpError = ''
    do {
        try {
            $lastXml = Save-UiDump -Name $Name
        } catch {
            $lastDumpError = $_.Exception.Message
            Start-Sleep -Milliseconds 750
            continue
        }
        $missing = @($RequiredText | Where-Object { -not (Test-UiContains -Xml $lastXml -Text $_) })
        $forbidden = @($ForbiddenText | Where-Object { Test-UiContains -Xml $lastXml -Text $_ })
        if ($missing.Count -eq 0 -and $forbidden.Count -eq 0) {
            Add-Check -Name "ui.$Name" -Status 'pass' -Detail ($RequiredText -join ', ')
            return $lastXml
        }
        if ($forbidden.Count -gt 0) {
            Add-Check -Name "ui.$Name" -Status 'fail' -Detail "Forbidden text visible: $($forbidden -join ', ')"
            throw "Forbidden auth/runtime text visible on $Name screen."
        }
        Start-Sleep -Milliseconds 750
    } while ((Get-Date) -lt $deadline)

    $detail = if (-not [string]::IsNullOrWhiteSpace($lastDumpError)) {
        "Missing text: $($missing -join ', '); last dump error: $lastDumpError"
    } else {
        "Missing text: $($missing -join ', ')"
    }
    Add-Check -Name "ui.$Name" -Status 'fail' -Detail $detail
    throw "Timed out waiting for $Name UI text: $detail"
}

function Wait-ForUiTextWithDumpRetry {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string[]]$RequiredText,
        [string[]]$ForbiddenText = @()
    )

    $deadline = (Get-Date).AddSeconds($WaitTimeoutSeconds)
    $missing = @()
    $lastDumpError = ''
    do {
        try {
            $xml = Save-UiDump -Name $Name
        } catch {
            $lastDumpError = $_.Exception.Message
            Start-Sleep -Milliseconds 750
            continue
        }

        $missing = @($RequiredText | Where-Object { -not (Test-UiContains -Xml $xml -Text $_) })
        $forbidden = @($ForbiddenText | Where-Object { Test-UiContains -Xml $xml -Text $_ })
        if ($missing.Count -eq 0 -and $forbidden.Count -eq 0) {
            Add-Check -Name "ui.$Name" -Status 'pass' -Detail ($RequiredText -join ', ')
            return $xml
        }
        if ($forbidden.Count -gt 0) {
            Add-Check -Name "ui.$Name" -Status 'fail' -Detail "Forbidden text visible: $($forbidden -join ', ')"
            throw "Forbidden auth/runtime text visible on $Name screen."
        }
        Start-Sleep -Milliseconds 750
    } while ((Get-Date) -lt $deadline)

    $detail = if (-not [string]::IsNullOrWhiteSpace($lastDumpError)) {
        "Missing text: $($missing -join ', '); last dump error: $lastDumpError"
    } else {
        "Missing text: $($missing -join ', ')"
    }
    Add-Check -Name "ui.$Name" -Status 'fail' -Detail $detail
    throw "Timed out waiting for $Name UI text: $detail"
}

function Wait-ForUiScreen {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][object[]]$Screens,
        [string[]]$ForbiddenText = @()
    )

    $deadline = (Get-Date).AddSeconds($WaitTimeoutSeconds)
    $lastMissing = @()
    $lastDumpError = ''
    do {
        try {
            $xml = Save-UiDump -Name $Name
        } catch {
            $lastDumpError = $_.Exception.Message
            Start-Sleep -Milliseconds 750
            continue
        }
        $forbidden = @($ForbiddenText | Where-Object { Test-UiContains -Xml $xml -Text $_ })
        if ($forbidden.Count -gt 0) {
            Add-Check -Name "ui.$Name" -Status 'fail' -Detail "Forbidden text visible: $($forbidden -join ', ')"
            throw "Forbidden auth/runtime text visible on $Name screen."
        }

        foreach ($screen in $Screens) {
            $required = @($screen.RequiredText)
            $missing = @($required | Where-Object { -not (Test-UiContains -Xml $xml -Text $_) })
            if ($missing.Count -eq 0) {
                Add-Check -Name "ui.$Name" -Status 'pass' -Detail "Matched $($screen.Name): $($required -join ', ')"
                return [pscustomobject]@{
                    Name = $screen.Name
                    Xml = $xml
                }
            }
            $lastMissing = @($lastMissing + "$($screen.Name): $($missing -join ', ')")
        }

        Start-Sleep -Milliseconds 750
    } while ((Get-Date) -lt $deadline)

    $detail = if (-not [string]::IsNullOrWhiteSpace($lastDumpError)) {
        "No expected screen matched. Missing: $($lastMissing -join ' | '); last dump error: $lastDumpError"
    } else {
        "No expected screen matched. Missing: $($lastMissing -join ' | ')"
    }
    Add-Check -Name "ui.$Name" -Status 'fail' -Detail $detail
    throw "Timed out waiting for $Name expected UI screen. $detail"
}

function Wait-ForLogcatPattern {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Detail
    )

    $deadline = (Get-Date).AddSeconds($WaitTimeoutSeconds)
    do {
        $logcat = Invoke-AdbWithTimeout -Arguments @('logcat', '-d', '-t', '8000', '-v', 'time') -TimeoutSeconds 10
        $logText = $logcat.Output -join "`n"
        if ($logcat.ExitCode -eq 0 -and $logText -match $Pattern) {
            Add-Check -Name $Name -Status 'pass' -Detail $Detail
            return $logText
        }
        Start-Sleep -Milliseconds 1000
    } while ((Get-Date) -lt $deadline)

    Add-Check -Name $Name -Status 'fail' -Detail 'Expected Android logcat marker was not observed.'
    throw "Timed out waiting for $Name logcat marker."
}

function Invoke-TapBounds {
    param(
        [Parameter(Mandatory = $true)]$Bounds,
        [Parameter(Mandatory = $true)][string]$Name
    )

    Invoke-Adb -Arguments @('shell', 'input', 'tap', "$($Bounds.centerX)", "$($Bounds.centerY)") | Out-Null
    Add-Check -Name "tap.$Name" -Status 'pass' -Detail "Tapped $($Bounds.centerX),$($Bounds.centerY)"
    Start-Sleep -Milliseconds 800
}

function Invoke-TapScreenFraction {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][double]$XFraction,
        [Parameter(Mandatory = $true)][double]$YFraction
    )

    $x = [math]::Floor($script:screenSize.width * $XFraction)
    $y = [math]::Floor($script:screenSize.height * $YFraction)
    Invoke-Adb -Arguments @('shell', 'input', 'tap', "$x", "$y") | Out-Null
    Add-Check -Name "tap.$Name" -Status 'pass' -Detail "Tapped $Name at $x,$y."
    Start-Sleep -Milliseconds 900
}

function Invoke-TextEntryAtScreenFraction {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][double]$XFraction,
        [Parameter(Mandatory = $true)][double]$YFraction,
        [Parameter(Mandatory = $true)][string]$Value
    )

    Invoke-TapScreenFraction `
        -Name "$Name field" `
        -XFraction $XFraction `
        -YFraction $YFraction

    $adbText = ConvertTo-AdbInputText -Text $Value
    if ($null -eq $adbText) {
        Add-Check -Name "input.$Name" -Status 'fail' -Detail 'Value contains characters unsupported by adb input text.'
        throw "Could not enter $Name with adb input text."
    }

    Invoke-Adb -Arguments @('shell', 'input', 'text', $adbText) | Out-Null
    Add-Check -Name "input.$Name" -Status 'pass' -Detail "Entered $Name."
    Start-Sleep -Milliseconds 650
}

function Invoke-TapDashboardTab {
    param(
        [Parameter(Mandatory = $true)][int]$Index,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $tabCount = 5
    $x = [math]::Floor($script:screenSize.width * (($Index + 0.5) / $tabCount))
    $y = [math]::Floor($script:screenSize.height * 0.93)
    Invoke-Adb -Arguments @('shell', 'input', 'tap', "$x", "$y") | Out-Null
    Add-Check -Name "tap.dashboardTab.$Label" -Status 'pass' -Detail "Tapped dashboard tab $Label at $x,$y."
    Start-Sleep -Milliseconds 900
}

function Invoke-ScrollDown {
    $x = [math]::Floor($script:screenSize.width / 2)
    $startY = [math]::Floor($script:screenSize.height * 0.78)
    $endY = [math]::Floor($script:screenSize.height * 0.28)
    Invoke-Adb -Arguments @('shell', 'input', 'swipe', "$x", "$startY", "$x", "$endY", '350') | Out-Null
    Start-Sleep -Milliseconds 650
}

function Invoke-TapText {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [string]$DumpPrefix = 'tap',
        [switch]$Contains,
        [int]$MaxScrolls = 0
    )

    $deadline = (Get-Date).AddSeconds($WaitTimeoutSeconds)
    $scrollsPerformed = 0
    $attempt = 0
    $lastDumpError = ''
    do {
        try {
            $xml = Save-UiDump -Name "$DumpPrefix-$attempt"
        } catch {
            $lastDumpError = $_.Exception.Message
            $attempt += 1
            Start-Sleep -Milliseconds 750
            continue
        }
        $bounds = Get-UiTextBounds -Xml $xml -Text $Text -Contains:$Contains
        if ($null -ne $bounds) {
            Invoke-TapBounds -Bounds $bounds -Name $Text
            return
        }

        if ($scrollsPerformed -lt $MaxScrolls) {
            Invoke-ScrollDown
            $scrollsPerformed += 1
        } else {
            Start-Sleep -Milliseconds 750
        }
        $attempt += 1
    } while ((Get-Date) -lt $deadline)

    $detail = if (-not [string]::IsNullOrWhiteSpace($lastDumpError)) {
        "Target text was not visible; last dump error: $lastDumpError"
    } else {
        'Target text was not visible.'
    }
    Add-Check -Name "tap.$Text" -Status 'fail' -Detail $detail
    throw "Could not find tappable UI text: $Text"
}

function Invoke-DashboardTabSmoke {
    $tabs = @(
        [pscustomobject]@{
            Index = 1
            Label = 'Health'
            Name = 'dashboard-tab-health'
            RequiredText = @('Daily Log', 'Food Intake', 'Add Food')
            RenderLogPattern = ''
        },
        [pscustomobject]@{
            Index = 2
            Label = 'Track'
            Name = 'dashboard-tab-track'
            RequiredText = @('Time to Move!', 'AI Workout', 'Take a Walk', 'Log a Run')
            RenderLogPattern = ''
        },
        [pscustomobject]@{
            Index = 3
            Label = 'Progress'
            Name = 'dashboard-tab-progress'
            RequiredText = @('Progress & Insights', 'Weekly Activity', 'Sleep Quality')
            RenderLogPattern = ''
        },
        [pscustomobject]@{
            Index = 4
            Label = 'Profile'
            Name = 'dashboard-tab-profile'
            RequiredText = @()
            RenderLogPattern = 'KidsProfileScreen: profile content rendered'
        }
    )

    foreach ($tab in $tabs) {
        Invoke-TapDashboardTab -Index $tab.Index -Label $tab.Label
        Wait-ForLogcatPattern `
            -Name "$($tab.Name)-selected" `
            -Pattern "FlowFitDashboard: selected tab $($tab.Label) \($($tab.Index)\)" `
            -Detail "Dashboard tab $($tab.Label) selection reached Flutter." | Out-Null
        if ($tab.RequiredText.Count -gt 0) {
            Wait-ForUiTextWithDumpRetry `
                -Name $tab.Name `
                -RequiredText $tab.RequiredText `
                -ForbiddenText @('FlowFit setup is incomplete', 'Could not check onboarding status') | Out-Null
        }
        if (-not [string]::IsNullOrWhiteSpace($tab.RenderLogPattern)) {
            Wait-ForLogcatPattern `
                -Name "$($tab.Name)-rendered" `
                -Pattern $tab.RenderLogPattern `
                -Detail "Dashboard tab $($tab.Label) rendered its content widget." | Out-Null
        }
        Save-Screenshot -Name $tab.Name
    }
}

function Invoke-HealthFoodLiveSmoke {
    $foodName = 'LiveSnack'
    $foodCalories = '123'

    Invoke-TapDashboardTab -Index 1 -Label 'Health'
    Wait-ForUiText `
        -Name 'health-food-before' `
        -RequiredText @('Daily Log', 'Food Intake', 'Add Food') `
        -ForbiddenText @('FlowFit setup is incomplete', 'Could not check onboarding status') | Out-Null
    Save-Screenshot -Name 'health-food-before'

    Invoke-TapText -Text 'Add Food' -DumpPrefix 'health-add-food'
    $dialogXml = Wait-ForUiText `
        -Name 'health-add-food-dialog' `
        -RequiredText @('Add Food', 'Cancel', 'Add') `
        -ForbiddenText @('FlowFit setup is incomplete')

    $foodNameBounds = Get-InputTapPoint -Xml $dialogXml -HintText 'e.g., Banana' -LabelText 'Food Name' -FieldIndex 0
    Invoke-TextEntry -Bounds $foodNameBounds -Value $foodName -Name 'health food name'
    Invoke-HideKeyboard

    $dialogAfterNameXml = Wait-ForUiText `
        -Name 'health-add-food-dialog-after-name' `
        -RequiredText @('Add Food', 'Cancel', 'Add') `
        -ForbiddenText @('FlowFit setup is incomplete')
    $caloriesBounds = Get-InputTapPoint -Xml $dialogAfterNameXml -HintText 'e.g., 105' -LabelText 'Calories' -FieldIndex 1
    Invoke-TextEntry -Bounds $caloriesBounds -Value $foodCalories -Name 'health food calories'
    Invoke-HideKeyboard
    Invoke-TapText -Text 'Add' -DumpPrefix 'health-add-food-submit'

    $addedXml = Wait-ForUiText `
        -Name 'health-food-added' `
        -RequiredText @($foodName, "$foodCalories kcal") `
        -ForbiddenText @('FlowFit setup is incomplete')
    Save-Screenshot -Name 'health-food-added'

    $foodBounds = Get-UiTextBounds -Xml $addedXml -Text $foodName
    if ($null -eq $foodBounds) {
        Add-Check -Name 'ui.health-food-added-row' -Status 'fail' -Detail 'Could not locate added food row bounds.'
        throw 'Could not locate added food row bounds.'
    }
    $foodActionBounds = Get-ClosestUiTextBounds -Xml $addedXml -Text 'Food actions' -TargetY $foodBounds.centerY
    if ($null -eq $foodActionBounds) {
        Add-Check -Name 'ui.health-food-actions-row' -Status 'fail' -Detail 'Could not locate added food row action button.'
        throw 'Could not locate added food row action button.'
    }
    Invoke-TapBounds -Bounds $foodActionBounds -Name 'Food actions for LiveSnack'
    Wait-ForUiText `
        -Name 'health-food-actions-menu' `
        -RequiredText @('Remove') `
        -ForbiddenText @('FlowFit setup is incomplete') | Out-Null
    Invoke-TapText -Text 'Remove' -DumpPrefix 'health-food-remove'
    Start-Sleep -Milliseconds 700
    $afterRemoveXml = Wait-ForUiText `
        -Name 'health-food-after-remove' `
        -RequiredText @('Daily Log', 'Food Intake', 'Add Food') `
        -ForbiddenText @('FlowFit setup is incomplete', 'Could not check onboarding status', $foodName, "$foodCalories kcal")
    Assert-UiNotContains `
        -Name 'health-food-after-remove' `
        -Xml $afterRemoveXml `
        -ForbiddenText @($foodName, "$foodCalories kcal")
    Save-Screenshot -Name 'health-food-after-remove'
}

function Invoke-TrackRouteLiveSmoke {
    Invoke-TapDashboardTab -Index 2 -Label 'Track'
    Wait-ForUiText `
        -Name 'track-before-route-actions' `
        -RequiredText @('Time to Move!', 'AI Workout', 'Take a Walk', 'Log a Run') `
        -ForbiddenText @('FlowFit setup is incomplete', 'Could not check onboarding status') | Out-Null
    Save-Screenshot -Name 'track-before-route-actions'

    Invoke-TapText -Text 'AI Workout' -DumpPrefix 'track-ai-workout' -Contains
    Wait-ForUiText `
        -Name 'track-ai-workout-opened' `
        -RequiredText @('Activity AI Classifier', 'Galaxy Watch') `
        -ForbiddenText @('FlowFit setup is incomplete') | Out-Null
    Save-Screenshot -Name 'track-ai-workout-opened'
    Invoke-Adb -Arguments @('shell', 'input', 'keyevent', 'BACK') -AllowFailure | Out-Null
    Wait-ForUiText `
        -Name 'track-after-ai-back' `
        -RequiredText @('Time to Move!', 'AI Workout', 'Take a Walk', 'Log a Run') `
        -ForbiddenText @('FlowFit setup is incomplete') | Out-Null

    Invoke-TapText -Text 'Take a Walk' -DumpPrefix 'track-take-walk' -Contains
    Wait-ForUiText `
        -Name 'track-walking-options-opened' `
        -RequiredText @('Choose Walking Mode', 'Free Walk', 'Start Free Walk', 'Create Mission') `
        -ForbiddenText @('FlowFit setup is incomplete') | Out-Null
    Save-Screenshot -Name 'track-walking-options-opened'
    Invoke-Adb -Arguments @('shell', 'input', 'keyevent', 'BACK') -AllowFailure | Out-Null
    Wait-ForUiText `
        -Name 'track-after-walk-back' `
        -RequiredText @('Time to Move!', 'AI Workout', 'Take a Walk', 'Log a Run') `
        -ForbiddenText @('FlowFit setup is incomplete') | Out-Null

    Invoke-TapText -Text 'Log a Run' -DumpPrefix 'track-log-run' -Contains
    Wait-ForUiText `
        -Name 'track-running-setup-opened' `
        -RequiredText @('Running Setup', 'Set Your Goal', 'Start Running') `
        -ForbiddenText @('FlowFit setup is incomplete') | Out-Null
    Save-Screenshot -Name 'track-running-setup-opened'
    Invoke-Adb -Arguments @('shell', 'input', 'keyevent', 'BACK') -AllowFailure | Out-Null
    Wait-ForUiText `
        -Name 'track-after-run-back' `
        -RequiredText @('Time to Move!', 'AI Workout', 'Take a Walk', 'Log a Run') `
        -ForbiddenText @('FlowFit setup is incomplete') | Out-Null
}

function Invoke-BuddyOnboardingSmoke {
    $buddyName = 'FlowFitSmokeBuddy'
    $nickname = 'SmokeKid'
    $selectedColor = 'purple'
    $selectedGoal = 'active'
    $selectedAge = 10

    Invoke-TapDashboardTab -Index 4 -Label 'Profile'
    Wait-ForLogcatPattern `
        -Name 'buddy-profile-before-onboarding-rendered' `
        -Pattern 'KidsProfileScreen: profile content rendered' `
        -Detail 'Profile tab rendered before Buddy setup entry.' | Out-Null
    Save-Screenshot -Name 'buddy-profile-before-onboarding'
    Invoke-TapScreenFraction `
        -Name 'Finish Buddy Setup' `
        -XFraction 0.5 `
        -YFraction 0.54

    Wait-ForLogcatPattern `
        -Name 'buddy-welcome-rendered' `
        -Pattern 'BuddyWelcomeScreen: rendered' `
        -Detail 'Buddy welcome screen rendered after Profile setup entry.' | Out-Null
    Save-Screenshot -Name 'buddy-welcome'
    Invoke-TapScreenFraction `
        -Name "buddy welcome LET'S GO" `
        -XFraction 0.5 `
        -YFraction 0.88

    Wait-ForLogcatPattern `
        -Name 'buddy-intro-rendered' `
        -Pattern 'BuddyIntroScreen: rendered' `
        -Detail 'Buddy intro screen rendered.' | Out-Null
    Save-Screenshot -Name 'buddy-intro'
    Invoke-TextEntryAtScreenFraction `
        -Name 'buddy friend name' `
        -XFraction 0.5 `
        -YFraction 0.74 `
        -Value $nickname
    Invoke-HideKeyboard
    Wait-ForLogcatPattern `
        -Name 'buddy-intro-name-entered' `
        -Pattern 'BuddyIntroScreen: rendered nameEmpty=false' `
        -Detail 'Buddy intro accepted the smoke child name.' | Out-Null
    Invoke-TapScreenFraction `
        -Name 'buddy intro NEXT' `
        -XFraction 0.5 `
        -YFraction 0.88

    Wait-ForLogcatPattern `
        -Name 'buddy-hatch-rendered' `
        -Pattern 'BuddyHatchScreen: rendered' `
        -Detail 'Buddy hatch screen rendered.' | Out-Null
    Save-Screenshot -Name 'buddy-hatch'

    Wait-ForLogcatPattern `
        -Name 'buddy-color-selection-rendered' `
        -Pattern 'BuddyColorSelectionScreen: rendered' `
        -Detail 'Buddy color selection screen rendered.' | Out-Null
    Save-Screenshot -Name 'buddy-color-selection'
    Invoke-TapScreenFraction `
        -Name 'purple color egg' `
        -XFraction 0.31 `
        -YFraction 0.77
    Wait-ForLogcatPattern `
        -Name 'buddy-color-purple-selected' `
        -Pattern 'BuddyColorSelectionScreen: rendered selectedColor=purple' `
        -Detail 'Buddy color selection accepted the purple smoke color.' | Out-Null
    Invoke-TapScreenFraction `
        -Name 'Hatch egg' `
        -XFraction 0.5 `
        -YFraction 0.88

    Wait-ForLogcatPattern `
        -Name 'buddy-naming-rendered' `
        -Pattern 'BuddyNamingScreen: rendered selectedColor=purple' `
        -Detail 'Buddy naming screen rendered with the selected smoke color.' | Out-Null
    Save-Screenshot -Name 'buddy-naming'
    Invoke-TextEntryAtScreenFraction `
        -Name 'buddy name' `
        -XFraction 0.5 `
        -YFraction 0.51 `
        -Value $buddyName
    Invoke-HideKeyboard
    Invoke-TapScreenFraction `
        -Name "buddy naming THAT'S PERFECT" `
        -XFraction 0.5 `
        -YFraction 0.88

    Wait-ForLogcatPattern `
        -Name 'buddy-profile-setup-rendered' `
        -Pattern "BuddyProfileSetupScreen: rendered buddy=$buddyName" `
        -Detail 'Buddy profile setup screen rendered with the smoke Buddy name.' | Out-Null
    Save-Screenshot -Name 'buddy-profile-setup'
    Invoke-TextEntryAtScreenFraction `
        -Name 'buddy profile nickname' `
        -XFraction 0.5 `
        -YFraction 0.55 `
        -Value $nickname
    Invoke-HideKeyboard
    Invoke-TapScreenFraction `
        -Name 'buddy profile age 10' `
        -XFraction 0.67 `
        -YFraction 0.66
    Invoke-TapScreenFraction `
        -Name 'buddy profile CONTINUE' `
        -XFraction 0.74 `
        -YFraction 0.88

    Wait-ForLogcatPattern `
        -Name 'buddy-goal-selection-rendered' `
        -Pattern 'GoalSelectionScreen: rendered' `
        -Detail 'Buddy goal selection screen rendered.' | Out-Null
    Save-Screenshot -Name 'buddy-goal-selection'
    Invoke-TapScreenFraction `
        -Name 'Be more active goal' `
        -XFraction 0.5 `
        -YFraction 0.61
    Wait-ForLogcatPattern `
        -Name 'buddy-goal-active-selected' `
        -Pattern 'GoalSelectionScreen: rendered selectedGoals=.*active' `
        -Detail 'Buddy goal selection accepted the active smoke goal.' | Out-Null
    Invoke-TapScreenFraction `
        -Name 'buddy goal NEXT' `
        -XFraction 0.5 `
        -YFraction 0.88

    Wait-ForLogcatPattern `
        -Name 'buddy-notification-permission-rendered' `
        -Pattern "NotificationPermissionScreen: rendered buddy=$buddyName" `
        -Detail 'Buddy notification permission screen rendered.' | Out-Null
    Save-Screenshot -Name 'buddy-notification-permission'
    Invoke-TapScreenFraction `
        -Name 'buddy notification Maybe later' `
        -XFraction 0.5 `
        -YFraction 0.88

    Wait-ForLogcatPattern `
        -Name 'buddy-ready-rendered' `
        -Pattern "BuddyReadyScreen: rendered buddy=$buddyName" `
        -Detail 'Buddy ready screen rendered.' | Out-Null
    Save-Screenshot -Name 'buddy-ready'
    Invoke-TapScreenFraction `
        -Name 'buddy ready START ADVENTURE' `
        -XFraction 0.5 `
        -YFraction 0.88

    Wait-ForLogcatPattern `
        -Name 'buddy-ready-save-completed' `
        -Pattern 'BuddyReadyScreen: onboarding saved' `
        -Detail 'Buddy onboarding save completed before dashboard navigation.' | Out-Null
    Wait-ForLogcatPattern `
        -Name 'dashboard-after-buddy-rendered' `
        -Pattern '(?s)BuddyReadyScreen: onboarding saved.*FlowFitDashboard: rendered tab 0' `
        -Detail 'Dashboard rendered after Buddy onboarding completion.' | Out-Null
    Save-Screenshot -Name 'dashboard-after-buddy'

    Invoke-TapDashboardTab -Index 4 -Label 'Profile'
    Wait-ForLogcatPattern `
        -Name 'dashboard-tab-profile-after-buddy-selected' `
        -Pattern 'FlowFitDashboard: selected tab Profile \(4\)' `
        -Detail 'Dashboard Profile tab selection after Buddy completion reached Flutter.' | Out-Null
    Wait-ForLogcatPattern `
        -Name 'dashboard-tab-profile-after-buddy-rendered' `
        -Pattern "KidsProfileScreen: profile content rendered buddy=$buddyName real=true" `
        -Detail 'Profile tab rendered the completed Buddy profile after onboarding.' | Out-Null
    Save-Screenshot -Name 'dashboard-tab-profile-after-buddy'

    return [pscustomobject]@{
        BuddyName = $buddyName
        Nickname = $nickname
        Age = $selectedAge
        Color = $selectedColor
        Goal = $selectedGoal
        NotificationsEnabled = $false
    }
}

function Get-InputTapPoint {
    param(
        [Parameter(Mandatory = $true)][string]$Xml,
        [Parameter(Mandatory = $true)][string]$HintText,
        [Parameter(Mandatory = $true)][string]$LabelText,
        [int]$FieldIndex = -1
    )

    $hintBounds = Get-UiTextBounds -Xml $Xml -Text $HintText -Contains
    if ($null -ne $hintBounds) {
        return $hintBounds
    }

    $labelBounds = Get-UiTextBounds -Xml $Xml -Text $LabelText
    if ($null -eq $labelBounds) {
        if ($FieldIndex -ge 0) {
            $fieldMatches = [regex]::Matches(
                $Xml,
                '<node\b(?=[^>]*class="android\.widget\.EditText")(?=[^>]*clickable="true")(?=[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]")[^>]*>'
            )
            if ($fieldMatches.Count -gt $FieldIndex) {
                $fieldMatch = $fieldMatches[$FieldIndex]
                $left = [int]$fieldMatch.Groups[1].Value
                $top = [int]$fieldMatch.Groups[2].Value
                $right = [int]$fieldMatch.Groups[3].Value
                $bottom = [int]$fieldMatch.Groups[4].Value
                return [pscustomobject]@{
                    left = $left
                    top = $top
                    right = $right
                    bottom = $bottom
                    centerX = [math]::Floor(($left + $right) / 2)
                    centerY = [math]::Floor(($top + $bottom) / 2)
                }
            }
        }

        throw "Could not locate input field by hint, label, or edit-field index: $HintText"
    }

    return [pscustomobject]@{
        left = 0
        top = $labelBounds.bottom
        right = $script:screenSize.width
        bottom = [math]::Min($script:screenSize.height, $labelBounds.bottom + 92)
        centerX = [math]::Floor($script:screenSize.width / 2)
        centerY = [math]::Min($script:screenSize.height - 24, $labelBounds.bottom + 46)
    }
}

function ConvertTo-AdbInputText {
    param([Parameter(Mandatory = $true)][string]$Text)

    if ($Text -notmatch '^[A-Za-z0-9@._+!-]+$') {
        return $null
    }

    return $Text.Replace(' ', '%s')
}

function Invoke-SensitiveTextEntry {
    param(
        [Parameter(Mandatory = $true)]$Bounds,
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][string]$Name
    )

    Invoke-TapBounds -Bounds $Bounds -Name "$Name field"
    $clipboard = Invoke-Adb `
        -Arguments @('shell', 'cmd', 'clipboard', 'set', 'flowfit-smoke', $Value) `
        -AllowFailure `
        -Sensitive
    $clipboardOutput = $clipboard.Output -join "`n"
    $clipboardSupported = $clipboard.ExitCode -eq 0 -and
        $clipboardOutput -notmatch 'No shell command implementation|Unknown command|Exception'
    if ($clipboardSupported) {
        Invoke-Adb -Arguments @('shell', 'input', 'keyevent', '279') -AllowFailure -Sensitive | Out-Null
        Start-Sleep -Milliseconds 650
        Add-Check -Name "input.$Name" -Status 'pass' -Detail 'Entered using Android clipboard paste; value redacted.'
        return
    }

    $adbText = ConvertTo-AdbInputText -Text $Value
    if ($null -eq $adbText) {
        Add-Check -Name "input.$Name" -Status 'fail' -Detail 'Credential contains characters unsupported by adb input text fallback.'
        throw "Could not enter $Name without exposing it. Use an ADB-safe smoke credential containing letters, numbers, @, dot, underscore, plus, hyphen, or exclamation mark."
    }

    Invoke-Adb -Arguments @('shell', 'input', 'text', $adbText) -Sensitive | Out-Null
    Add-Check -Name "input.$Name" -Status 'pass' -Detail 'Entered using adb input text; value redacted.'
    Start-Sleep -Milliseconds 650
}

function Invoke-TextEntry {
    param(
        [Parameter(Mandatory = $true)]$Bounds,
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][string]$Name
    )

    Invoke-TapBounds -Bounds $Bounds -Name "$Name field"
    $clipboard = Invoke-Adb `
        -Arguments @('shell', 'cmd', 'clipboard', 'set', 'flowfit-smoke', $Value) `
        -AllowFailure `
        -Sensitive
    $clipboardOutput = $clipboard.Output -join "`n"
    $clipboardSupported = $clipboard.ExitCode -eq 0 -and
        $clipboardOutput -notmatch 'No shell command implementation|Unknown command|Exception'
    if ($clipboardSupported) {
        Invoke-Adb -Arguments @('shell', 'input', 'keyevent', '279') -AllowFailure -Sensitive | Out-Null
        Start-Sleep -Milliseconds 650
        Add-Check -Name "input.$Name" -Status 'pass' -Detail "Entered $Name using Android clipboard paste."
        return
    }

    $adbText = ConvertTo-AdbInputText -Text $Value
    if ($null -eq $adbText) {
        Add-Check -Name "input.$Name" -Status 'fail' -Detail 'Value contains characters unsupported by adb input text.'
        throw "Could not enter $Name with adb input text."
    }

    Invoke-Adb -Arguments @('shell', 'input', 'text', $adbText) | Out-Null
    Add-Check -Name "input.$Name" -Status 'pass' -Detail "Entered $Name."
    Start-Sleep -Milliseconds 650
}

function Invoke-HideKeyboard {
    Invoke-Adb -Arguments @('shell', 'input', 'keyevent', 'BACK') -AllowFailure | Out-Null
    Start-Sleep -Milliseconds 650
}

function Assert-UiNotContains {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Xml,
        [Parameter(Mandatory = $true)][string[]]$ForbiddenText
    )

    $found = @($ForbiddenText | Where-Object { Test-UiContains -Xml $Xml -Text $_ })
    Assert-Condition `
        -Condition ($found.Count -eq 0) `
        -Name "uiAbsent.$Name" `
        -Failure "Forbidden UI text visible: $($found -join ', ')" `
        -Detail 'Forbidden UI text was absent.'
}

function Write-Evidence {
    $outPath = if ([System.IO.Path]::IsPathRooted($OutFile)) {
        $OutFile
    } else {
        Join-Path $repoRoot $OutFile
    }
    $outDir = Split-Path -Parent $outPath
    if (-not [string]::IsNullOrWhiteSpace($outDir)) {
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    }

    $evidence = [ordered]@{
        schemaVersion = 1
        generatedAt = (Get-Date).ToUniversalTime().ToString('o')
        status = $script:status
        error = $script:errorMessage
        packageName = $packageName
        mainActivity = $mainActivity
        targetPlatform = $TargetPlatform
        device = $script:deviceInfo
        supabaseConfigSource = $script:supabaseConfigSource
        supabaseProjectHost = $script:supabaseProjectHost
        smokeEmail = $script:smokeEmail
        checks = @($script:checks.ToArray())
        artifacts = $script:artifacts
    }

    $evidence | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $outPath -Encoding UTF8
    Write-Host "ANDROID_LIVE_AUTH_SMOKE_EVIDENCE_WRITTEN $outPath"
}

Push-Location $repoRoot
try {
    New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
    Import-EnvFile -Path $EnvFile

    $config = Resolve-SupabaseClientConfig
    $script:supabaseConfigSource = $config.Source
    $script:supabaseProjectHost = ([Uri]$config.Url).Host
    Add-Check -Name 'supabase.clientConfig' -Status 'pass' -Detail "Loaded from $($config.Source); key redacted."

    $credentials = Resolve-SmokeCredentials
    $script:smokeEmail = $credentials.RedactedEmail
    Add-Check -Name 'supabase.smokeCredentials' -Status 'pass' -Detail "Loaded dedicated smoke account $($credentials.RedactedEmail); password redacted."
    Invoke-SmokeBackendDataCleanup -Config $config -Credentials $credentials -Phase 'preRun' | Out-Null

    $script:adbPath = Resolve-AdbPath
    $script:deviceSerial = Resolve-DeviceSerial -RequestedDevice $Device
    Wait-ForAndroidRuntimeReady
    Update-DeviceInfo
    Add-Check -Name 'adb.device' -Status 'pass' -Detail "$($script:deviceInfo.model) Android $($script:deviceInfo.androidRelease)"

    $apk = Resolve-ApkPath -Platform $TargetPlatform
    if (-not $SkipBuild) {
        $flutterArgs = @(
            'build',
            'apk',
            '--debug',
            '--target-platform',
            $TargetPlatform,
            '--split-per-abi',
            '--no-pub',
            '-t',
            'lib/main.dart',
            "--dart-define=SUPABASE_URL=$($config.Url)",
            "--dart-define=SUPABASE_PUBLISHABLE_KEY=$($config.PublishableKey)",
            "--dart-define=FLOWFIT_AUTH_SCHEME=$packageName"
        )
        Invoke-External -File 'flutter' -Arguments $flutterArgs | Out-Null
        Add-Check -Name 'flutter.buildAndroidPhoneApk' -Status 'pass' -Detail "Built $TargetPlatform debug APK."
    }

    Assert-Condition `
        -Condition (Test-Path -LiteralPath $apk) `
        -Name 'apk.exists' `
        -Failure "Expected APK does not exist: $apk" `
        -Detail $apk

    Install-ApkWithRetry -Path $apk

    if (-not $KeepAppData) {
        Invoke-Adb -Arguments @('shell', 'pm', 'clear', $packageName) | Out-Null
        Add-Check -Name 'adb.pmClear.before' -Status 'pass' -Detail 'Cleared package state before live auth smoke.'
    }

    Invoke-Adb -Arguments @('shell', 'input', 'keyevent', 'WAKEUP') -AllowFailure | Out-Null
    Invoke-Adb -Arguments @('shell', 'wm', 'dismiss-keyguard') -AllowFailure | Out-Null
    Invoke-Adb -Arguments @('logcat', '-c') | Out-Null

    Start-AppWithRetry

    Start-Sleep -Seconds 3

    $welcomeXml = Wait-ForUiText `
        -Name 'welcome' `
        -RequiredText @('Find Your Flow', 'Get Started', 'Log In') `
        -ForbiddenText @('FlowFit setup is incomplete', 'SUPABASE_URL must', 'SUPABASE_PUBLISHABLE_KEY must')
    Save-Screenshot -Name 'welcome'
    Assert-UiNotContains `
        -Name 'setupGuard' `
        -Xml $welcomeXml `
        -ForbiddenText @('FlowFit setup is incomplete', 'SUPABASE_URL must', 'SUPABASE_PUBLISHABLE_KEY must')

    Invoke-TapText -Text 'Log In' -DumpPrefix 'welcome-login'
    $loginXml = Wait-ForUiText `
        -Name 'login-before-credentials' `
        -RequiredText @('Welcome Back!', 'Email', 'Password', 'Forgot password?', 'Log In') `
        -ForbiddenText @('Invalid login credentials', 'Could not check onboarding status')
    Save-Screenshot -Name 'login-before-credentials'

    $emailBounds = Get-InputTapPoint -Xml $loginXml -HintText 'Enter your email' -LabelText 'Email'
    $passwordBounds = Get-InputTapPoint -Xml $loginXml -HintText 'Enter your password' -LabelText 'Password'
    $loginButtonBounds = Get-UiTextBounds -Xml $loginXml -Text 'Log In'
    if ($null -eq $loginButtonBounds) {
        throw 'Could not locate login submit button before credential entry.'
    }

    Invoke-SensitiveTextEntry -Bounds $emailBounds -Value $credentials.Email -Name 'email'
    Invoke-SensitiveTextEntry -Bounds $passwordBounds -Value $credentials.Password -Name 'password'
    Invoke-TapBounds -Bounds $loginButtonBounds -Name 'Log In submit'

    $postAuth = Wait-ForUiScreen `
        -Name 'post-auth-onboarding-entry' `
        -Screens @(
            [pscustomobject]@{
                Name = 'age-gate'
                RequiredText = @('Welcome to FlowFit!', "I'm 13 or older", "I'm 7-12 years old")
            },
            [pscustomobject]@{
                Name = 'survey-intro'
                RequiredText = @('Quick Setup', "Let's Personalize")
            }
        ) `
        -ForbiddenText @('Invalid login credentials', 'Email not confirmed', 'Could not check onboarding status', 'FlowFit setup is incomplete')

    if ($postAuth.Name -eq 'age-gate') {
        Save-Screenshot -Name 'post-auth-age-gate'
        Invoke-TapText -Text "I'm 13 or older" -DumpPrefix 'age-gate-13-plus' -Contains
        Wait-ForUiText `
            -Name 'survey-intro' `
            -RequiredText @('Quick Setup', "Let's Personalize") `
            -ForbiddenText @('Could not check onboarding status', 'FlowFit setup is incomplete') | Out-Null
        Save-Screenshot -Name 'survey-intro'
    } else {
        Save-Screenshot -Name 'post-auth-survey-intro'
    }

    Invoke-TapText -Text "Let's Personalize" -DumpPrefix 'survey-intro-personalize'
    $basicInfoXml = Wait-ForUiText `
        -Name 'survey-basic-info' `
        -RequiredText @('Tell us about yourself', 'Gender', 'Age', 'Continue') `
        -ForbiddenText @('Could not check onboarding status', 'FlowFit setup is incomplete')
    Save-Screenshot -Name 'survey-basic-info'

    Invoke-TapText -Text 'Male' -DumpPrefix 'survey-basic-info-male'
    Invoke-TapText -Text 'Continue' -DumpPrefix 'survey-basic-info-continue' -MaxScrolls 1

    $measurementsXml = Wait-ForUiText `
        -Name 'survey-measurements' `
        -RequiredText @('Your measurements', 'Height', 'Weight', 'Continue') `
        -ForbiddenText @('Error:', 'FlowFit setup is incomplete')
    Save-Screenshot -Name 'survey-measurements'

    $heightBounds = Get-InputTapPoint -Xml $measurementsXml -HintText 'Enter height' -LabelText 'Height'
    $weightBounds = Get-InputTapPoint -Xml $measurementsXml -HintText 'Enter weight' -LabelText 'Weight'
    Invoke-TextEntry -Bounds $heightBounds -Value '170' -Name 'height'
    Invoke-TextEntry -Bounds $weightBounds -Value '70' -Name 'weight'
    Invoke-HideKeyboard
    Invoke-TapText -Text 'Continue' -DumpPrefix 'survey-measurements-continue' -MaxScrolls 2

    Wait-ForUiText `
        -Name 'survey-activity-goals' `
        -RequiredText @('Activity & Goals', 'Current Activity Level', 'Sedentary', 'Primary Fitness Goal') `
        -ForbiddenText @('Please select your activity level', 'Please select at least one fitness goal', 'FlowFit setup is incomplete') | Out-Null
    Save-Screenshot -Name 'survey-activity-goals'

    Invoke-TapText -Text 'Sedentary' -DumpPrefix 'survey-activity-sedentary' -Contains
    Invoke-TapText -Text 'Lose Weight' -DumpPrefix 'survey-goal-lose-weight' -Contains -MaxScrolls 4
    Invoke-TapText -Text 'Continue' -DumpPrefix 'survey-activity-continue' -MaxScrolls 4

    Wait-ForUiText `
        -Name 'survey-daily-targets' `
        -RequiredText @('Your Daily Targets', 'Personalized Goals', 'Calorie Target') `
        -ForbiddenText @('Failed to save profile', 'FlowFit setup is incomplete') | Out-Null
    Save-Screenshot -Name 'survey-daily-targets'

    Invoke-TapText -Text 'Complete & Start App' -DumpPrefix 'survey-complete' -Contains -MaxScrolls 8
    Start-Sleep -Seconds 2
    Assert-SmokeProfileCompleted -Config $config -Credentials $credentials
    Wait-ForLogcatPattern `
        -Name 'dashboard-after-survey' `
        -Pattern '(FlowFitDashboard: rendered tab 0|_HomeScreenState\._subscribeToWatch|Starting to listen for watch data|Listening started successfully)' `
        -Detail 'Home dashboard initialized after survey completion.' | Out-Null
    Save-Screenshot -Name 'dashboard-after-survey'
    Invoke-DashboardTabSmoke
    Invoke-HealthFoodLiveSmoke
    Invoke-TrackRouteLiveSmoke
    $buddySmoke = Invoke-BuddyOnboardingSmoke
    Assert-SmokeBuddyCompleted `
        -Config $config `
        -Credentials $credentials `
        -ExpectedName $buddySmoke.BuddyName `
        -ExpectedColor $buddySmoke.Color `
        -ExpectedNickname $buddySmoke.Nickname `
        -ExpectedAge $buddySmoke.Age `
        -ExpectedGoal $buddySmoke.Goal `
        -ExpectedNotificationsEnabled $buddySmoke.NotificationsEnabled

    Invoke-SmokeBackendDataCleanup -Config $config -Credentials $credentials -Phase 'postRun' | Out-Null

    Save-Logcat
    $logPath = Join-Path $artifactRoot 'logcat.txt'
    $logText = if (Test-Path -LiteralPath $logPath) {
        Get-Content -LiteralPath $logPath -Raw
    } else {
        ''
    }

    $escapedPackageName = [regex]::Escape($packageName)
    $appCrashPattern = "(AndroidRuntime.*Process:\s+$escapedPackageName\b|AndroidRuntime.*$escapedPackageName|$escapedPackageName.*AndroidRuntime|GeneratedPluginRegistrant|GeneratedPluginsRegister|NoClassDefFoundError|Error registering Flutter plugin)"
    $ignoredUiAutomatorCrashPattern = '(?s)FATAL EXCEPTION: main.*?com\.android\.commands\.uiautomator\.Launcher'
    $ignoredUiAutomatorCrashCount = ([regex]::Matches($logText, $ignoredUiAutomatorCrashPattern)).Count
    if ($ignoredUiAutomatorCrashCount -gt 0) {
        Add-Check `
            -Name 'android.uiautomatorCrashMarkersIgnored' `
            -Status 'pass' `
            -Detail "Ignored $ignoredUiAutomatorCrashCount uiautomator dump crash marker(s) caused by the Android automation-service registration race."
    }
    $crashPattern = $appCrashPattern
    $markerCount = ([regex]::Matches($logText, $crashPattern)).Count
    Assert-Condition `
        -Condition ($markerCount -eq 0) `
        -Name 'android.logcatCrashMarkers' `
        -Failure "Found $markerCount Android native/plugin crash marker(s) in package launch/auth logcat." `
        -Detail 'No Flutter plugin registration or AndroidRuntime crash markers found.'

    if (-not $KeepAppData) {
        Invoke-Adb -Arguments @('shell', 'pm', 'clear', $packageName) | Out-Null
        Add-Check -Name 'adb.pmClear.after' -Status 'pass' -Detail 'Cleared package state after live auth smoke.'
    }

    $script:status = 'pass'
} catch {
    $script:status = 'fail'
    $script:errorMessage = $_.Exception.Message
    try {
        Save-Logcat -Name 'logcat-failure'
    } catch {
        # Preserve the original failure; logcat capture is best effort.
    }
    throw
} finally {
    try {
        if (-not [string]::IsNullOrWhiteSpace($script:adbPath) -and -not [string]::IsNullOrWhiteSpace($script:deviceSerial)) {
            Invoke-Adb -Arguments @('shell', 'am', 'force-stop', $packageName) -AllowFailure | Out-Null
        }
    } finally {
        Write-Evidence
        Pop-Location
    }
}
