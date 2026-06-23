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

function Resolve-AdbPath {
    $pathCommand = Get-Command adb -ErrorAction SilentlyContinue
    if ($pathCommand) {
        return $pathCommand.Source
    }

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
    $dump = Invoke-Adb -Arguments @('shell', 'uiautomator', 'dump', $remotePath) -AllowFailure
    $dumpText = $dump.Output -join "`n"
    if (
        $dump.ExitCode -ne 0 -or
        $dumpText -match 'ERROR|could not get idle state|No such file'
    ) {
        throw "uiautomator dump failed for $Name.`n$dumpText"
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

function Wait-ForUiText {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string[]]$RequiredText,
        [string[]]$ForbiddenText = @()
    )

    $deadline = (Get-Date).AddSeconds($WaitTimeoutSeconds)
    $lastXml = ''
    do {
        $lastXml = Save-UiDump -Name $Name
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

    Add-Check -Name "ui.$Name" -Status 'fail' -Detail "Missing text: $($missing -join ', ')"
    throw "Timed out waiting for $Name UI text: $($missing -join ', ')"
}

function Wait-ForUiScreen {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][object[]]$Screens,
        [string[]]$ForbiddenText = @()
    )

    $deadline = (Get-Date).AddSeconds($WaitTimeoutSeconds)
    $lastMissing = @()
    do {
        $xml = Save-UiDump -Name $Name
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

    Add-Check -Name "ui.$Name" -Status 'fail' -Detail "No expected screen matched. Missing: $($lastMissing -join ' | ')"
    throw "Timed out waiting for $Name expected UI screen."
}

function Wait-ForLogcatPattern {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Detail
    )

    $deadline = (Get-Date).AddSeconds($WaitTimeoutSeconds)
    do {
        $logcat = Invoke-Adb -Arguments @('logcat', '-d', '-v', 'time') -AllowFailure
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

    for ($attempt = 0; $attempt -le $MaxScrolls; $attempt += 1) {
        $xml = Save-UiDump -Name "$DumpPrefix-$attempt"
        $bounds = Get-UiTextBounds -Xml $xml -Text $Text -Contains:$Contains
        if ($null -ne $bounds) {
            Invoke-TapBounds -Bounds $bounds -Name $Text
            return
        }

        if ($attempt -lt $MaxScrolls) {
            Invoke-ScrollDown
        }
    }

    Add-Check -Name "tap.$Text" -Status 'fail' -Detail 'Target text was not visible.'
    throw "Could not find tappable UI text: $Text"
}

function Get-InputTapPoint {
    param(
        [Parameter(Mandatory = $true)][string]$Xml,
        [Parameter(Mandatory = $true)][string]$HintText,
        [Parameter(Mandatory = $true)][string]$LabelText
    )

    $hintBounds = Get-UiTextBounds -Xml $Xml -Text $HintText -Contains
    if ($null -ne $hintBounds) {
        return $hintBounds
    }

    $labelBounds = Get-UiTextBounds -Xml $Xml -Text $LabelText
    if ($null -eq $labelBounds) {
        throw "Could not locate input field by hint or label: $HintText"
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
        -Failure "Forbidden setup/auth text visible: $($found -join ', ')" `
        -Detail 'No setup/auth guard text visible.'
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

    Invoke-Adb -Arguments @('install', '-r', '-d', $apk) | Out-Null
    Add-Check -Name 'adb.install' -Status 'pass' -Detail 'Installed debug APK.'

    if (-not $KeepAppData) {
        Invoke-Adb -Arguments @('shell', 'pm', 'clear', $packageName) | Out-Null
        Add-Check -Name 'adb.pmClear.before' -Status 'pass' -Detail 'Cleared package state before live auth smoke.'
    }

    Invoke-Adb -Arguments @('shell', 'input', 'keyevent', 'WAKEUP') -AllowFailure | Out-Null
    Invoke-Adb -Arguments @('shell', 'wm', 'dismiss-keyguard') -AllowFailure | Out-Null
    Invoke-Adb -Arguments @('logcat', '-c') | Out-Null

    $launch = Invoke-Adb -Arguments @('shell', 'am', 'start', '-W', '-n', $mainActivity)
    $launchText = $launch.Output -join "`n"
    Assert-Condition `
        -Condition ($launchText -match 'Status:\s+ok') `
        -Name 'adb.launchStatus' `
        -Failure "Android launch did not report Status: ok.`n$launchText" `
        -Detail 'am start -W returned Status: ok.'

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
        -Pattern '(_HomeScreenState\._subscribeToWatch|Starting to listen for watch data|Listening started successfully)' `
        -Detail 'Home dashboard initialized after survey completion.' | Out-Null
    Save-Screenshot -Name 'dashboard-after-survey'

    Invoke-SmokeBackendDataCleanup -Config $config -Credentials $credentials -Phase 'postRun' | Out-Null

    $logcat = Invoke-Adb -Arguments @('logcat', '-d', '-v', 'time')
    $logPath = Join-Path $artifactRoot 'logcat.txt'
    $logText = $logcat.Output -join "`n"
    Set-Content -LiteralPath $logPath -Value $logText -Encoding UTF8
    Add-Artifact -Name 'logcat' -Path $logPath

    $crashPattern = '(GeneratedPluginRegistrant|GeneratedPluginsRegister|NoClassDefFoundError|FATAL EXCEPTION|Error registering Flutter plugin|AndroidRuntime.*com\.msiazondev\.flowfit|com\.msiazondev\.flowfit.*AndroidRuntime)'
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
