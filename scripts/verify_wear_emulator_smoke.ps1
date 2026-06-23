param(
    [string]$Device = '',
    [string]$OutFile = 'build/wear-emulator-smoke-latest.json',
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
$artifactRoot = Join-Path $repoRoot 'build/wear-emulator-smoke'

$script:checks = New-Object System.Collections.Generic.List[object]
$script:artifacts = [ordered]@{}
$script:status = 'running'
$script:errorMessage = ''
$script:adbPath = ''
$script:deviceSerial = ''
$script:deviceInfo = [ordered]@{}
$script:screenSize = [ordered]@{ width = 454; height = 454 }

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

function Invoke-ExternalWithTimeout {
    param(
        [Parameter(Mandatory = $true)][string]$File,
        [string[]]$Arguments = @(),
        [int]$TimeoutSeconds = 15
    )

    $stdoutPath = [System.IO.Path]::GetTempFileName()
    $stderrPath = [System.IO.Path]::GetTempFileName()
    try {
        $process = Start-Process `
            -FilePath $File `
            -ArgumentList $Arguments `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath `
            -PassThru `
            -WindowStyle Hidden

        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            return [pscustomobject]@{
                ExitCode = 124
                Output = @("Command timed out after $TimeoutSeconds seconds.")
            }
        }

        $output = @()
        if (Test-Path -LiteralPath $stdoutPath) {
            $output += Get-Content -LiteralPath $stdoutPath -ErrorAction SilentlyContinue
        }
        if (Test-Path -LiteralPath $stderrPath) {
            $output += Get-Content -LiteralPath $stderrPath -ErrorAction SilentlyContinue
        }

        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            Output = @($output | ForEach-Object { $_.ToString() })
        }
    } finally {
        Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
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
        throw 'No connected Android Wear emulator or device is visible in adb devices.'
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
        if ([System.IO.Path]::IsPathRooted($ApkPath)) {
            return $ApkPath
        }
        return Join-Path $repoRoot $ApkPath
    }

    $abiName = switch ($Platform) {
        'android-x64' { 'x86_64' }
        'android-arm64' { 'arm64-v8a' }
        'android-arm' { 'armeabi-v7a' }
        default { throw "Unsupported target platform for split APK smoke: $Platform" }
    }

    return Join-Path $repoRoot "build/app/outputs/flutter-apk/app-$abiName-debug.apk"
}

function Grant-AppPermission {
    param([Parameter(Mandatory = $true)][string]$Permission)

    $grant = Invoke-Adb -Arguments @('shell', 'pm', 'grant', $packageName, $Permission) -AllowFailure
    if ($grant.ExitCode -eq 0) {
        Add-Check -Name "adb.permission.$Permission" -Status 'pass' -Detail 'Granted before Wear smoke.'
    } else {
        Add-Check -Name "adb.permission.$Permission" -Status 'warn' -Detail (($grant.Output -join "`n").Trim())
    }
}

function Save-UiDump {
    param([Parameter(Mandatory = $true)][string]$Name)

    $remotePath = '/sdcard/flowfit-wear-smoke-window.xml'
    Invoke-Adb -Arguments @('shell', 'rm', '-f', $remotePath) -AllowFailure | Out-Null
    $dump = Invoke-ExternalWithTimeout `
        -File $script:adbPath `
        -Arguments @('-s', $script:deviceSerial, 'shell', 'uiautomator', 'dump', $remotePath) `
        -TimeoutSeconds 15
    $localPath = Join-Path $artifactRoot "$Name.xml"

    if ($dump.ExitCode -ne 0) {
        $dumpMessage = "uiautomator dump failed with exit code $($dump.ExitCode).`n$($dump.Output -join "`n")"
        Set-Content -LiteralPath $localPath -Value $dumpMessage -Encoding UTF8
        Add-Artifact -Name "uiDump.$Name" -Path $localPath
        return $dumpMessage
    }

    $cat = Invoke-Adb -Arguments @('exec-out', 'cat', $remotePath) -AllowFailure
    if ($cat.ExitCode -ne 0) {
        $catMessage = "uiautomator dump failed: remote dump file was not readable.`n$($cat.Output -join "`n")"
        Set-Content -LiteralPath $localPath -Value $catMessage -Encoding UTF8
        Add-Artifact -Name "uiDump.$Name" -Path $localPath
        return $catMessage
    }

    $xml = $cat.Output -join "`n"
    Set-Content -LiteralPath $localPath -Value $xml -Encoding UTF8
    Add-Artifact -Name "uiDump.$Name" -Path $localPath
    return $xml
}

function Save-Screenshot {
    param([Parameter(Mandatory = $true)][string]$Name)

    $remotePath = "/sdcard/flowfit-wear-smoke-$Name.png"
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

function Wait-ForUiText {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string[]]$RequiredText,
        [int]$TimeoutSeconds = $WaitTimeoutSeconds
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
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

function Wait-ForUiTextOrLogText {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string[]]$RequiredText,
        [Parameter(Mandatory = $true)][string[]]$RequiredLogText,
        [int]$TimeoutSeconds = $WaitTimeoutSeconds
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $missing = @()
    $missingLog = @()
    $lastXml = ''
    do {
        $lastXml = Save-UiDump -Name $Name
        $missing = @($RequiredText | Where-Object { -not (Test-UiContains -Xml $lastXml -Text $_) })
        if ($missing.Count -eq 0) {
            Add-Check -Name "ui.$Name" -Status 'pass' -Detail ($RequiredText -join ', ')
            return $lastXml
        }

        $logText = Save-Logcat -Name "$Name-logcat-snapshot"
        $missingLog = @($RequiredLogText | Where-Object { -not $logText.Contains($_) })
        if ($missingLog.Count -eq 0) {
            Add-Check `
                -Name "uiOrLog.$Name" `
                -Status 'pass' `
                -Detail "Log markers found after UI dump fallback: $($RequiredLogText -join ', ')"
            return $lastXml
        }

        Start-Sleep -Milliseconds 750
    } while ((Get-Date) -lt $deadline)

    Add-Check `
        -Name "uiOrLog.$Name" `
        -Status 'fail' `
        -Detail "Missing UI text: $($missing -join ', '); missing log text: $($missingLog -join ', ')"
    throw "Timed out waiting for $Name UI text or log markers."
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
        centerX = [math]::Floor(($left + $right) / 2)
        centerY = [math]::Floor(($top + $bottom) / 2)
    }
}

function Invoke-TapText {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [string]$DumpPrefix = 'tap'
    )

    $xml = Save-UiDump -Name "$DumpPrefix-0"
    $bounds = Get-UiTextBounds -Xml $xml -Text $Text
    if ($null -eq $bounds) {
        Add-Check -Name "tap.$Text" -Status 'fail' -Detail 'Target text was not visible.'
        throw "Could not find tappable UI text: $Text"
    }

    Invoke-Adb -Arguments @('shell', 'input', 'tap', "$($bounds.centerX)", "$($bounds.centerY)") | Out-Null
    Add-Check -Name "tap.$Text" -Status 'pass' -Detail "Tapped $($bounds.centerX),$($bounds.centerY)"
    Start-Sleep -Milliseconds 900
}

function Invoke-TapTextOrCoordinates {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [string]$DumpPrefix = 'tap',
        [int]$FallbackX = [math]::Floor($script:screenSize.width / 2),
        [int]$FallbackY = [math]::Floor($script:screenSize.height * 0.85)
    )

    $xml = Save-UiDump -Name "$DumpPrefix-0"
    $bounds = Get-UiTextBounds -Xml $xml -Text $Text
    if ($null -ne $bounds) {
        Invoke-Adb -Arguments @('shell', 'input', 'tap', "$($bounds.centerX)", "$($bounds.centerY)") | Out-Null
        Add-Check -Name "tap.$Text" -Status 'pass' -Detail "Tapped $($bounds.centerX),$($bounds.centerY)"
        Start-Sleep -Milliseconds 900
        return
    }

    Invoke-Adb -Arguments @('shell', 'input', 'tap', "$FallbackX", "$FallbackY") | Out-Null
    Add-Check `
        -Name "tap.$Text" `
        -Status 'pass' `
        -Detail "UI text not visible; tapped fallback primary button center $FallbackX,$FallbackY"
    Start-Sleep -Milliseconds 900
}

function Save-Logcat {
    param([string]$Name = 'logcat')

    $logcat = Invoke-ExternalWithTimeout `
        -File $script:adbPath `
        -Arguments @('-s', $script:deviceSerial, 'logcat', '-d', '-v', 'time') `
        -TimeoutSeconds 15
    $logPath = Join-Path $artifactRoot "$Name.txt"
    $logText = $logcat.Output -join "`n"
    if ($logcat.ExitCode -eq 124) {
        $logText = "logcat capture timed out after 15 seconds.`n$logText"
    }
    Set-Content -LiteralPath $logPath -Value $logText -Encoding UTF8
    Add-Artifact -Name $Name -Path $logPath
    return (Get-Content -LiteralPath $logPath -Raw)
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
        checks = @($script:checks.ToArray())
        artifacts = $script:artifacts
    }

    $evidence | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $outPath -Encoding UTF8
    Write-Host "WEAR_EMULATOR_SMOKE_EVIDENCE_WRITTEN $outPath"
}

Push-Location $repoRoot
try {
    New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null

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
            'lib/main_wear.dart'
        )
        Invoke-External -File 'flutter' -Arguments $flutterArgs | Out-Null
        Add-Check -Name 'flutter.buildWearApk' -Status 'pass' -Detail "Built lib/main_wear.dart for $TargetPlatform."
    }

    Assert-Condition `
        -Condition (Test-Path -LiteralPath $apk) `
        -Name 'apk.exists' `
        -Failure "Expected Wear APK does not exist: $apk" `
        -Detail $apk

    Invoke-Adb -Arguments @('install', '-r', '-d', $apk) | Out-Null
    Add-Check -Name 'adb.install' -Status 'pass' -Detail 'Installed Wear debug APK.'

    if (-not $KeepAppData) {
        Invoke-Adb -Arguments @('shell', 'pm', 'clear', $packageName) | Out-Null
        Add-Check -Name 'adb.pmClear' -Status 'pass' -Detail 'Cleared package state before Wear smoke.'
    }

    foreach ($permission in @(
        'android.permission.BODY_SENSORS',
        'android.permission.ACTIVITY_RECOGNITION',
        'android.permission.health.READ_HEART_RATE',
        'android.permission.POST_NOTIFICATIONS'
    )) {
        Grant-AppPermission -Permission $permission
    }

    Invoke-Adb -Arguments @('shell', 'input', 'keyevent', 'WAKEUP') -AllowFailure | Out-Null
    Invoke-Adb -Arguments @('shell', 'wm', 'dismiss-keyguard') -AllowFailure | Out-Null
    Invoke-Adb -Arguments @('logcat', '-c') | Out-Null

    $launch = Invoke-Adb -Arguments @('shell', 'am', 'start', '-W', '-n', $mainActivity)
    $launchText = $launch.Output -join "`n"
    Assert-Condition `
        -Condition ($launchText -match 'Status:\s+ok') `
        -Name 'adb.launchStatus' `
        -Failure "Wear launch did not report Status: ok.`n$launchText" `
        -Detail 'am start -W returned Status: ok.'

    Start-Sleep -Seconds 3

    $appPid = Get-AdbShellText -Arguments @('pidof', $packageName)
    Assert-Condition `
        -Condition (-not [string]::IsNullOrWhiteSpace($appPid)) `
        -Name 'android.processRunning' `
        -Failure "$packageName is not running after Wear launch." `
        -Detail "pid $appPid"

    $dashboardXml = Wait-ForUiText -Name 'wear-dashboard' -RequiredText @('FlowFit', 'Heart Rate')
    Save-Screenshot -Name 'wear-dashboard'
    Assert-Condition `
        -Condition (-not (Test-UiContains -Xml $dashboardXml -Text 'Find Your Flow')) `
        -Name 'uiAbsent.phoneWelcome' `
        -Failure 'Phone welcome UI appeared instead of Wear dashboard.' `
        -Detail 'Wear entrypoint rendered instead of phone onboarding UI.'

    Invoke-TapText -Text 'Heart Rate' -DumpPrefix 'wear-heart-rate-button'
    Wait-ForUiText -Name 'wear-heart-rate-ready' -RequiredText @('BPM', 'Start') | Out-Null
    Save-Screenshot -Name 'wear-heart-rate-ready'
    Wait-ForUiText -Name 'wear-health-service-unavailable' -RequiredText @('Samsung Health service unavailable') -TimeoutSeconds 75 | Out-Null

    Invoke-TapTextOrCoordinates -Text 'Start' -DumpPrefix 'wear-heart-rate-start'
    Wait-ForUiTextOrLogText `
        -Name 'wear-heart-rate-simulated' `
        -RequiredText @('Simulated', 'Sim', 'Stop') `
        -RequiredLogText @('FLOWFIT_WEAR_SIMULATED_FALLBACK_STARTED') `
        -TimeoutSeconds 75 | Out-Null
    Save-Screenshot -Name 'wear-heart-rate-simulated'

    Invoke-TapTextOrCoordinates -Text 'Stop' -DumpPrefix 'wear-heart-rate-stop'
    Wait-ForUiTextOrLogText `
        -Name 'wear-heart-rate-stopped' `
        -RequiredText @('Stopped', 'Start') `
        -RequiredLogText @('FLOWFIT_WEAR_SIMULATED_FALLBACK_STOPPED') | Out-Null
    Save-Screenshot -Name 'wear-heart-rate-stopped'

    $logText = Save-Logcat
    $escapedPackageName = [regex]::Escape($packageName)
    $crashPattern = "(AndroidRuntime.*Process:\s+$escapedPackageName\b|AndroidRuntime.*$escapedPackageName|$escapedPackageName.*AndroidRuntime|GeneratedPluginRegistrant|GeneratedPluginsRegister|NoClassDefFoundError|Error registering Flutter plugin)"
    $markerCount = ([regex]::Matches($logText, $crashPattern)).Count
    Assert-Condition `
        -Condition ($markerCount -eq 0) `
        -Name 'android.logcatCrashMarkers' `
        -Failure "Found $markerCount Android native/plugin crash marker(s) in Wear launch logcat." `
        -Detail 'No Flutter plugin registration or AndroidRuntime crash markers found.'

    $script:status = 'pass'
} catch {
    $script:status = 'fail'
    $script:errorMessage = $_.Exception.Message
    try {
        Save-Logcat -Name 'logcat-failure' | Out-Null
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
