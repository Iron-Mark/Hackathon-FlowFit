param(
    [switch]$SkipTests,
    [switch]$SkipBuilds,
    [switch]$IncludeWasmSmoke,
    [switch]$IncludeReleaseSmoke
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$previousGradleEnv = @{
    AllowDebugReleaseSigning = $env:ORG_GRADLE_PROJECT_FLOWFIT_ALLOW_DEBUG_RELEASE_SIGNING
    AndroidApplicationId = $env:ORG_GRADLE_PROJECT_FLOWFIT_ANDROID_APPLICATION_ID
    AuthScheme = $env:ORG_GRADLE_PROJECT_FLOWFIT_AUTH_SCHEME
    DevAuthScheme = $env:ORG_GRADLE_PROJECT_FLOWFIT_DEV_AUTH_SCHEME
    SupportEmail = $env:FLOWFIT_SUPPORT_EMAIL
}

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string[]]$Command
    )

    Write-Host ""
    Write-Host "==> $Label"
    & $Command[0] @($Command[1..($Command.Length - 1)])
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code $LASTEXITCODE"
    }
}

function Assert-WebCompliancePages {
    $pages = @(
        @{
            Path = 'build/web/privacy.html'
            Title = '<title>FlowFit Privacy Policy</title>'
            Link = 'account-deletion.html'
            RequiredTerms = @(
                'support@flowfit.com',
                'account and associated app data',
                'Profile &gt; Settings &gt; Delete Account'
            )
        },
        @{
            Path = 'build/web/account-deletion.html'
            Title = '<title>FlowFit Account Deletion</title>'
            Link = 'privacy.html'
            RequiredTerms = @(
                'mailto:support@flowfit.com',
                'FlowFit account deletion request',
                'associated app data',
                'without reinstalling the app',
                'Profile &gt; Settings &gt; Delete Account'
            )
        }
    )

    $internalTerms = @(
        'Replace this address',
        'backend deletion',
        'maintainer verification',
        'privileged backend',
        'Play Console',
        'App Store Connect'
    )

    Write-Host ""
    Write-Host "==> Web compliance pages"

    foreach ($page in $pages) {
        if (-not (Test-Path $page.Path)) {
            throw "Missing required web compliance page: $($page.Path)"
        }

        $content = Get-Content -Raw $page.Path
        if (-not $content.Contains($page.Title)) {
            throw "Missing expected title in $($page.Path): $($page.Title)"
        }

        if (-not $content.Contains($page.Link)) {
            throw "Missing expected cross-link in $($page.Path): $($page.Link)"
        }

        foreach ($term in $page.RequiredTerms) {
            if (-not $content.Contains($term)) {
                throw "Missing required public compliance wording in $($page.Path): $term"
            }
        }

        foreach ($term in $internalTerms) {
            if ($content.Contains($term)) {
                throw "Public web page $($page.Path) contains internal term: $term"
            }
        }
    }
}

function Assert-ReleaseSourceSafety {
    Write-Host ""
    Write-Host "==> Release source safety"

    $blockedLiterals = @(
        @{
            Path = 'lib/data/repositories/auth_repository.dart'
            Literal = 'emailRedirectTo: ''com.example.flowfit' + '://auth-callback'''
        },
        @{
            Path = 'lib/utils/deep_link_handler.dart'
            Literal = 'return ''com.example.flowfit' + '://auth-callback'''
        }
    )

    foreach ($check in $blockedLiterals) {
        if ((Test-Path $check.Path) -and (Get-Content -Raw $check.Path).Contains($check.Literal)) {
            throw "Release source safety check failed in $($check.Path): $($check.Literal)"
        }
    }

    $mainPath = 'lib/main.dart'
    if (Test-Path $mainPath) {
        $mainSource = Get-Content -Raw $mainPath
        $debugRouteGate = $mainSource.IndexOf('if (kDebugMode) ...{')
        if ($debugRouteGate -lt 0) {
            throw "Release source safety check failed in ${mainPath}: missing debug route gate"
        }

        $productionRouteSource = $mainSource.Substring(0, $debugRouteGate)
        if ($productionRouteSource.Contains("'/trackertest'")) {
            throw "Release source safety check failed in ${mainPath}: /trackertest must remain debug-only"
        }
        if (-not $mainSource.Contains("'/activity-classifier'")) {
            throw "Release source safety check failed in ${mainPath}: missing production activity classifier route"
        }
    }

    $migrationPath = 'supabase/migrations/20260614062844_recreate_flowfit_backend.sql'
    if (
        (Test-Path $migrationPath) -and
        ((Get-Content -Raw $migrationPath) -match '(?i)security\s+definer')
    ) {
        throw "Release source safety check failed in ${migrationPath}: security definer"
    }
}

function Remove-IgnoredGeneratedAndroidRegistrant {
    $generatedRegistrant = Join-Path $repoRoot 'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java'
    if (Test-Path $generatedRegistrant) {
        Remove-Item -LiteralPath $generatedRegistrant -Force
    }
}

Push-Location $repoRoot
try {
    $releaseReadinessAuditScript = Join-Path $repoRoot 'scripts/release_readiness_audit.ps1'
    Invoke-CheckedCommand 'Release readiness audit, advisory mode' @('pwsh', '-NoProfile', '-File', $releaseReadinessAuditScript)

    Invoke-CheckedCommand 'Flutter dependencies' @('flutter', 'pub', 'get')
    Assert-ReleaseSourceSafety
    Invoke-CheckedCommand 'Dart analyzer machine output' @('dart', 'analyze', '--format=machine')
    Invoke-CheckedCommand 'Flutter analyzer' @('flutter', 'analyze')

    if (-not $SkipTests) {
        Invoke-CheckedCommand 'Flutter tests' @('flutter', 'test', '--reporter', 'compact')
    }

    if (-not $SkipBuilds) {
        Invoke-CheckedCommand 'Flutter web JavaScript release smoke build, not for store upload' @(
            'flutter',
            'build',
            'web',
            '--release',
            '--no-pub',
            '--dart-define=FLOWFIT_SUPPORT_EMAIL=support@flowfit.com',
            '--dart-define=SUPABASE_URL=https://abcdefghijklmnopqrst.supabase.co',
            '--dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_abcdefghijklmnopqrstuvwxyz123456'
        )
        Assert-WebCompliancePages
        if ($IncludeWasmSmoke) {
            Invoke-CheckedCommand 'Flutter web Wasm release smoke build, not the default store target' @(
                'flutter',
                'build',
                'web',
                '--wasm',
                '--no-pub',
                '--dart-define=FLOWFIT_SUPPORT_EMAIL=support@flowfit.com',
                '--dart-define=SUPABASE_URL=https://abcdefghijklmnopqrst.supabase.co',
                '--dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_abcdefghijklmnopqrstuvwxyz123456'
            )
            Assert-WebCompliancePages
        }
        Remove-IgnoredGeneratedAndroidRegistrant
        Invoke-CheckedCommand 'Android debug APK build' @('flutter', 'build', 'apk', '--debug', '--no-pub')
        Remove-IgnoredGeneratedAndroidRegistrant
        Invoke-CheckedCommand 'Wear OS debug APK build' @('flutter', 'build', 'apk', '--debug', '-t', 'lib/main_wear.dart', '--no-pub')
    }

    if ($IncludeReleaseSmoke) {
        $env:ORG_GRADLE_PROJECT_FLOWFIT_ALLOW_DEBUG_RELEASE_SIGNING = 'true'
        if ([string]::IsNullOrWhiteSpace($env:ORG_GRADLE_PROJECT_FLOWFIT_ANDROID_APPLICATION_ID)) {
            $env:ORG_GRADLE_PROJECT_FLOWFIT_ANDROID_APPLICATION_ID = 'com.flowfit.smoke'
        }
        if ([string]::IsNullOrWhiteSpace($env:ORG_GRADLE_PROJECT_FLOWFIT_AUTH_SCHEME)) {
            $env:ORG_GRADLE_PROJECT_FLOWFIT_AUTH_SCHEME = $env:ORG_GRADLE_PROJECT_FLOWFIT_ANDROID_APPLICATION_ID
        }
        if ([string]::IsNullOrWhiteSpace($env:FLOWFIT_SUPPORT_EMAIL)) {
            $env:FLOWFIT_SUPPORT_EMAIL = 'support@flowfit.com'
        }

        Remove-IgnoredGeneratedAndroidRegistrant
        Invoke-CheckedCommand 'Android release App Bundle smoke build, not for store upload' @(
            'flutter',
            'build',
            'appbundle',
            '--release',
            '--no-pub',
            "--dart-define=FLOWFIT_AUTH_SCHEME=$($env:ORG_GRADLE_PROJECT_FLOWFIT_AUTH_SCHEME)",
            "--dart-define=FLOWFIT_SUPPORT_EMAIL=$($env:FLOWFIT_SUPPORT_EMAIL)",
            '--dart-define=SUPABASE_URL=https://abcdefghijklmnopqrst.supabase.co',
            '--dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_abcdefghijklmnopqrstuvwxyz123456'
        )
    }

    Write-Host ""
    Write-Host "FlowFit release preflight finished."
}
finally {
    if ($null -eq $previousGradleEnv.AllowDebugReleaseSigning) {
        Remove-Item Env:\ORG_GRADLE_PROJECT_FLOWFIT_ALLOW_DEBUG_RELEASE_SIGNING -ErrorAction SilentlyContinue
    } else {
        $env:ORG_GRADLE_PROJECT_FLOWFIT_ALLOW_DEBUG_RELEASE_SIGNING = $previousGradleEnv.AllowDebugReleaseSigning
    }
    if ($null -eq $previousGradleEnv.AndroidApplicationId) {
        Remove-Item Env:\ORG_GRADLE_PROJECT_FLOWFIT_ANDROID_APPLICATION_ID -ErrorAction SilentlyContinue
    } else {
        $env:ORG_GRADLE_PROJECT_FLOWFIT_ANDROID_APPLICATION_ID = $previousGradleEnv.AndroidApplicationId
    }
    if ($null -eq $previousGradleEnv.AuthScheme) {
        Remove-Item Env:\ORG_GRADLE_PROJECT_FLOWFIT_AUTH_SCHEME -ErrorAction SilentlyContinue
    } else {
        $env:ORG_GRADLE_PROJECT_FLOWFIT_AUTH_SCHEME = $previousGradleEnv.AuthScheme
    }
    if ($null -eq $previousGradleEnv.DevAuthScheme) {
        Remove-Item Env:\ORG_GRADLE_PROJECT_FLOWFIT_DEV_AUTH_SCHEME -ErrorAction SilentlyContinue
    } else {
        $env:ORG_GRADLE_PROJECT_FLOWFIT_DEV_AUTH_SCHEME = $previousGradleEnv.DevAuthScheme
    }
    if ($null -eq $previousGradleEnv.SupportEmail) {
        Remove-Item Env:\FLOWFIT_SUPPORT_EMAIL -ErrorAction SilentlyContinue
    } else {
        $env:FLOWFIT_SUPPORT_EMAIL = $previousGradleEnv.SupportEmail
    }

    Pop-Location
}
