param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,
    [string]$SupportEmail = '',
    [int]$TimeoutSeconds = 20,
    [string]$OutFile = '',
    [switch]$AllowInsecureLocalhost
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PASS', 'FAIL')]
        [string]$Level,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Detail
    )

    $script:results.Add([pscustomobject]@{
        level = $Level
        name = $Name
        detail = $Detail
    })

    Write-Host "[$Level] $Name - $Detail"
}

function Add-Pass {
    param([string]$Name, [string]$Detail)
    Add-Result -Level 'PASS' -Name $Name -Detail $Detail
}

function Add-Fail {
    param([string]$Name, [string]$Detail)
    Add-Result -Level 'FAIL' -Name $Name -Detail $Detail
}

function Assert-TextContains {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CheckName,
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [Parameter(Mandatory = $true)]
        [string[]]$Terms
    )

    foreach ($term in $Terms) {
        if (-not $Content.Contains($term)) {
            Add-Fail $CheckName "Missing required text: $term"
            return $false
        }
    }

    Add-Pass $CheckName 'Required text is present.'
    return $true
}

function Assert-TextExcludes {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CheckName,
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [Parameter(Mandatory = $true)]
        [string[]]$Terms
    )

    foreach ($term in $Terms) {
        if ($Content.Contains($term)) {
            Add-Fail $CheckName "Found internal/non-public text: $term"
            return $false
        }
    }

    Add-Pass $CheckName 'No internal release-maintainer terms were found.'
    return $true
}

function Resolve-DeploymentUri {
    param([Parameter(Mandatory = $true)][string]$Value)

    $trimmed = $Value.Trim().TrimEnd('/')
    $uri = $null
    if (-not [System.Uri]::TryCreate($trimmed, [System.UriKind]::Absolute, [ref]$uri)) {
        throw "BaseUrl must be an absolute HTTP(S) URL."
    }

    $isLocalHttp = (
        $AllowInsecureLocalhost -and
        $uri.Scheme -eq 'http' -and
        @('localhost', '127.0.0.1', '::1').Contains($uri.Host)
    )

    if ($uri.Scheme -ne 'https' -and -not $isLocalHttp) {
        throw 'BaseUrl must use HTTPS. Use -AllowInsecureLocalhost only for localhost smoke tests.'
    }

    return $uri
}

function Join-DeploymentPath {
    param(
        [Parameter(Mandatory = $true)]
        [System.Uri]$Root,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [System.Uri]::new($Root.AbsoluteUri.TrimEnd('/') + $Path)
}

function Invoke-WebCheck {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [System.Uri]$Uri
    )

    try {
        $response = Invoke-WebRequest -Uri $Uri -Method Get -TimeoutSec $TimeoutSeconds
        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 300) {
            Add-Pass "$Name HTTP" "$($response.StatusCode) $Uri"
            return [string]$response.Content
        }

        Add-Fail "$Name HTTP" "$($response.StatusCode) $Uri"
        return ''
    } catch {
        Add-Fail "$Name HTTP" "$Uri failed: $($_.Exception.Message)"
        return ''
    }
}

if ([string]::IsNullOrWhiteSpace($SupportEmail)) {
    $SupportEmail = [Environment]::GetEnvironmentVariable('FLOWFIT_SUPPORT_EMAIL')
}
if ([string]::IsNullOrWhiteSpace($SupportEmail)) {
    $SupportEmail = 'support@flowfit.com'
}

if ($SupportEmail -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
    throw 'SupportEmail must be a valid-looking email address.'
}

$rootUri = Resolve-DeploymentUri -Value $BaseUrl
$internalTerms = @(
    'Replace this address',
    'backend deletion',
    'maintainer verification',
    'privileged backend',
    'Play Console',
    'App Store Connect'
)

Write-Host "==> FlowFit web deployment verification"
Write-Host "BaseUrl: $($rootUri.AbsoluteUri.TrimEnd('/'))"

$index = Invoke-WebCheck -Name 'App shell' -Uri (Join-DeploymentPath -Root $rootUri -Path '/')
if (-not [string]::IsNullOrWhiteSpace($index)) {
    [void](Assert-TextContains -CheckName 'App shell content' -Content $index -Terms @('flutter_bootstrap.js', 'manifest.json'))
}

$flutterBootstrap = Invoke-WebCheck -Name 'Flutter bootstrap' -Uri (Join-DeploymentPath -Root $rootUri -Path '/flutter_bootstrap.js')
if (-not [string]::IsNullOrWhiteSpace($flutterBootstrap)) {
    [void](Assert-TextContains -CheckName 'Flutter bootstrap content' -Content $flutterBootstrap -Terms @('main.dart.js'))
}

$compiledApp = Invoke-WebCheck -Name 'Compiled Flutter app' -Uri (Join-DeploymentPath -Root $rootUri -Path '/main.dart.js')
if (-not [string]::IsNullOrWhiteSpace($compiledApp)) {
    [void](Assert-TextContains -CheckName 'Compiled Flutter app content' -Content $compiledApp -Terms @('main'))
}

$manifest = Invoke-WebCheck -Name 'Web manifest' -Uri (Join-DeploymentPath -Root $rootUri -Path '/manifest.json')
if (-not [string]::IsNullOrWhiteSpace($manifest)) {
    [void](Assert-TextContains -CheckName 'Web manifest content' -Content $manifest -Terms @('"name": "FlowFit"', '"short_name": "FlowFit"'))
}

$privacy = Invoke-WebCheck -Name 'Privacy page' -Uri (Join-DeploymentPath -Root $rootUri -Path '/privacy.html')
if (-not [string]::IsNullOrWhiteSpace($privacy)) {
    [void](Assert-TextContains -CheckName 'Privacy page content' -Content $privacy -Terms @(
        'FlowFit Privacy Policy',
        $SupportEmail,
        'account-deletion.html',
        'account and associated app data'
    ))
    [void](Assert-TextExcludes -CheckName 'Privacy page public wording' -Content $privacy -Terms $internalTerms)
}

$deletion = Invoke-WebCheck -Name 'Account deletion page' -Uri (Join-DeploymentPath -Root $rootUri -Path '/account-deletion.html')
if (-not [string]::IsNullOrWhiteSpace($deletion)) {
    [void](Assert-TextContains -CheckName 'Account deletion page content' -Content $deletion -Terms @(
        'FlowFit Account Deletion',
        "mailto:$SupportEmail",
        'privacy.html',
        'FlowFit account deletion request',
        'associated app data',
        'without reinstalling the app',
        'Profile &gt; Settings &gt; Delete Account'
    ))
    [void](Assert-TextExcludes -CheckName 'Account deletion page public wording' -Content $deletion -Terms $internalTerms)
}

$summary = [pscustomobject]@{
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    baseUrl = $rootUri.AbsoluteUri.TrimEnd('/')
    supportEmail = $SupportEmail
    summary = [pscustomobject]@{
        pass = @($results | Where-Object { $_.level -eq 'PASS' }).Count
        fail = @($results | Where-Object { $_.level -eq 'FAIL' }).Count
    }
    results = @($results.ToArray())
}

if (-not [string]::IsNullOrWhiteSpace($OutFile)) {
    $outDirectory = Split-Path -Parent $OutFile
    if (-not [string]::IsNullOrWhiteSpace($outDirectory) -and -not (Test-Path $outDirectory)) {
        New-Item -ItemType Directory -Path $outDirectory | Out-Null
    }
    $summary | ConvertTo-Json -Depth 5 | Set-Content -Path $OutFile
    Write-Host "Deployment verification evidence written: $OutFile"
}

if ($summary.summary.fail -gt 0) {
    throw "FlowFit web deployment verification failed with $($summary.summary.fail) failing check(s)."
}

Write-Host "FlowFit web deployment verification passed: $($summary.summary.pass) checks."
