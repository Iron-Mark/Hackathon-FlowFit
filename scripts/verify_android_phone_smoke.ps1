param(
    [string]$Device = '',
    [string]$EnvFile = '',
    [string]$OutFile = 'build/android-phone-smoke-latest.json',
    [string]$TargetPlatform = 'android-x64',
    [string]$ApkPath = '',
    [switch]$SkipBuild,
    [switch]$KeepAppData,
    [int]$WaitTimeoutSeconds = 30
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$packageName = 'com.msiazondev.flowfit'
$mainActivity = "$packageName/.MainActivity"
$artifactRoot = Join-Path $repoRoot 'build/android-phone-smoke'

$script:checks = New-Object System.Collections.Generic.List[object]
$script:artifacts = [ordered]@{}
$script:status = 'running'
$script:errorMessage = ''
$script:adbPath = ''
$script:deviceSerial = ''
$script:deviceInfo = [ordered]@{}
$script:supabaseConfigSource = ''
$script:supabaseProjectHost = ''
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
        throw 'Android phone smoke requires SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY, or ignored lib/secrets.dart. See docs/SUPABASE_RECOVERY_RUNBOOK.md.'
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
        [switch]$AllowFailure
    )

    $output = & $File @Arguments 2>&1 | ForEach-Object { $_.ToString() }
    $exitCode = $LASTEXITCODE
    if (-not $AllowFailure -and $exitCode -ne 0) {
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
        [switch]$AllowFailure
    )

    return Invoke-External `
        -File $script:adbPath `
        -Arguments (@('-s', $script:deviceSerial) + $Arguments) `
        -AllowFailure:$AllowFailure
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

    $remotePath = '/sdcard/flowfit-smoke-window.xml'
    Invoke-Adb -Arguments @('shell', 'uiautomator', 'dump', $remotePath) | Out-Null
    $cat = Invoke-Adb -Arguments @('exec-out', 'cat', $remotePath)
    $xml = $cat.Output -join "`n"
    $localPath = Join-Path $artifactRoot "$Name.xml"
    Set-Content -LiteralPath $localPath -Value $xml -Encoding UTF8
    Add-Artifact -Name "uiDump.$Name" -Path $localPath
    return $xml
}

function Save-Screenshot {
    param([Parameter(Mandatory = $true)][string]$Name)

    $remotePath = "/sdcard/flowfit-smoke-$Name.png"
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
        [Parameter(Mandatory = $true)][string]$Text
    )

    $escaped = [regex]::Escape((ConvertTo-XmlText -Text $Text))
    $pattern = '<node\b(?=[^>]*(?:text|content-desc)="' + $escaped + '")[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'
    $match = [regex]::Match($Xml, $pattern)
    if (-not $match.Success) {
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
        [Parameter(Mandatory = $true)][string[]]$RequiredText
    )

    $deadline = (Get-Date).AddSeconds($WaitTimeoutSeconds)
    $lastXml = ''
    do {
        $lastXml = Save-UiDump -Name $Name
        $missing = @($RequiredText | Where-Object { -not (Test-UiContains -Xml $lastXml -Text $_) })
        if ($missing.Count -eq 0) {
            Add-Check -Name "ui.$Name" -Status 'pass' -Detail ($RequiredText -join ', ')
            return $lastXml
        }
        Start-Sleep -Milliseconds 750
    } while ((Get-Date) -lt $deadline)

    Add-Check -Name "ui.$Name" -Status 'fail' -Detail "Missing text: $($missing -join ', ')"
    throw "Timed out waiting for $Name UI text: $($missing -join ', ')"
}

function Wait-ForUiAnyText {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string[]]$AnyText
    )

    $deadline = (Get-Date).AddSeconds($WaitTimeoutSeconds)
    $lastXml = ''
    do {
        $lastXml = Save-UiDump -Name $Name
        $found = @($AnyText | Where-Object { Test-UiContains -Xml $lastXml -Text $_ })
        if ($found.Count -gt 0) {
            Add-Check -Name "ui.$Name" -Status 'pass' -Detail ($found -join ', ')
            return $lastXml
        }
        Start-Sleep -Milliseconds 750
    } while ((Get-Date) -lt $deadline)

    Add-Check -Name "ui.$Name" -Status 'fail' -Detail "Missing any text: $($AnyText -join ', ')"
    throw "Timed out waiting for any $Name UI text: $($AnyText -join ', ')"
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
        [int]$MaxScrolls = 0,
        [string]$DumpPrefix = 'tap'
    )

    for ($attempt = 0; $attempt -le $MaxScrolls; $attempt += 1) {
        $xml = Save-UiDump -Name "$DumpPrefix-$attempt"
        $bounds = Get-UiTextBounds -Xml $xml -Text $Text
        if ($null -ne $bounds) {
            Invoke-Adb -Arguments @('shell', 'input', 'tap', "$($bounds.centerX)", "$($bounds.centerY)") | Out-Null
            Add-Check -Name "tap.$Text" -Status 'pass' -Detail "Tapped $($bounds.centerX),$($bounds.centerY)"
            Start-Sleep -Milliseconds 900
            return
        }

        if ($attempt -lt $MaxScrolls) {
            Invoke-ScrollDown
        }
    }

    Add-Check -Name "tap.$Text" -Status 'fail' -Detail 'Target text was not visible.'
    throw "Could not find tappable UI text: $Text"
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
        -Failure "Forbidden setup/runtime text visible: $($found -join ', ')" `
        -Detail 'No setup guard text visible.'
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
        checks = @($script:checks.ToArray())
        artifacts = $script:artifacts
    }

    $evidence | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $outPath -Encoding UTF8
    Write-Host "ANDROID_PHONE_SMOKE_EVIDENCE_WRITTEN $outPath"
}

Push-Location $repoRoot
try {
    New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
    Import-EnvFile -Path $EnvFile

    $config = Resolve-SupabaseClientConfig
    $script:supabaseConfigSource = $config.Source
    $script:supabaseProjectHost = ([Uri]$config.Url).Host
    Add-Check -Name 'supabase.clientConfig' -Status 'pass' -Detail "Loaded from $($config.Source); key redacted."

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
        Add-Check -Name 'adb.pmClear' -Status 'pass' -Detail 'Cleared package state before smoke.'
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

    $appPid = Get-AdbShellText -Arguments @('pidof', $packageName)
    Assert-Condition `
        -Condition (-not [string]::IsNullOrWhiteSpace($appPid)) `
        -Name 'android.processRunning' `
        -Failure "$packageName is not running after launch." `
        -Detail "pid $appPid"

    $window = Get-AdbShellText -Arguments @('dumpsys', 'window')
    Assert-Condition `
        -Condition ($window -match [regex]::Escape($packageName)) `
        -Name 'android.windowFocus' `
        -Failure "$packageName is not present in dumpsys window focus/current activity output." `
        -Detail "$packageName present in window output."

    $welcomeXml = Wait-ForUiText -Name 'welcome' -RequiredText @('Find Your Flow', 'Get Started', 'Log In')
    Save-Screenshot -Name 'welcome'
    Assert-UiNotContains `
        -Name 'setupGuard' `
        -Xml $welcomeXml `
        -ForbiddenText @('FlowFit setup is incomplete', 'SUPABASE_URL must', 'SUPABASE_PUBLISHABLE_KEY must')

    Invoke-TapText -Text 'Get Started' -DumpPrefix 'welcome-get-started'
    Wait-ForUiText -Name 'signup-top' -RequiredText @('Create Your Account', 'Full Name', 'Email') | Out-Null

    Invoke-TapText -Text 'Read Terms' -MaxScrolls 4 -DumpPrefix 'signup-read-terms'
    Wait-ForUiAnyText -Name 'terms' -AnyText @('Terms of Service', 'Acceptance of Terms') | Out-Null
    Save-Screenshot -Name 'terms'
    Invoke-Adb -Arguments @('shell', 'input', 'keyevent', 'BACK') | Out-Null
    Start-Sleep -Milliseconds 900

    Invoke-TapText -Text 'Read Policy' -MaxScrolls 4 -DumpPrefix 'signup-read-policy'
    Wait-ForUiAnyText -Name 'privacy' -AnyText @('Privacy Policy', 'FlowFit is built for fitness') | Out-Null
    Save-Screenshot -Name 'privacy'
    Invoke-Adb -Arguments @('shell', 'input', 'keyevent', 'BACK') | Out-Null
    Start-Sleep -Milliseconds 900

    Invoke-TapText -Text 'Log In' -MaxScrolls 4 -DumpPrefix 'signup-login-link'
    Wait-ForUiText -Name 'login' -RequiredText @('Welcome Back!', 'Email', 'Password', 'Forgot password?', 'Log In') | Out-Null
    Save-Screenshot -Name 'login'

    Invoke-TapText -Text 'Log In' -DumpPrefix 'login-empty-submit'
    Wait-ForUiText -Name 'login-empty-validation' -RequiredText @('Please enter your email') | Out-Null

    Invoke-TapText -Text 'Sign Up' -MaxScrolls 2 -DumpPrefix 'login-signup-link'
    Wait-ForUiText -Name 'signup-return' -RequiredText @('Create Your Account') | Out-Null

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
        -Failure "Found $markerCount Android native/plugin crash marker(s) in package launch logcat." `
        -Detail 'No Flutter plugin registration or AndroidRuntime crash markers found.'

    $script:status = 'pass'
} catch {
    $script:status = 'fail'
    $script:errorMessage = $_.Exception.Message
    throw
} finally {
    Write-Evidence
    Pop-Location
}
