param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,
    [string]$SupportEmail = '',
    [int]$TimeoutSeconds = 20,
    [string]$OutFile = '',
    [switch]$AllowInsecureLocalhost,
    [string]$CompareBuildWebPath = ''
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

function Assert-SupportEmail {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $normalized = $Value.Trim()
    if (
        [string]::IsNullOrWhiteSpace($normalized) -or
        $normalized -notmatch '^[A-Za-z0-9._+-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$' -or
        $normalized -match '["''<>?&/%\x00-\x1F\x7F]'
    ) {
        throw "$Name must be a valid support email address. Use a plain mailbox like support@flowfit.com."
    }
}

function Get-Sha256HexFromText {
    param([Parameter(Mandatory = $true)][string]$Content)

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $hashBytes = [System.Security.Cryptography.SHA256]::HashData($bytes)
    return [System.BitConverter]::ToString($hashBytes).Replace('-', '').ToLowerInvariant()
}

function Get-Sha256HexFromFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Normalize-FlutterBootstrapForComparison {
    param([Parameter(Mandatory = $true)][string]$Content)

    $serviceWorkerVersionPattern = "serviceWorkerVersion\s*:\s*['`"][^'`"]*['`"]"
    return [regex]::Replace(
        $Content,
        $serviceWorkerVersionPattern,
        'serviceWorkerVersion:"[generated]"'
    )
}

function Resolve-CompareBuildWebPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ''
    }

    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
    if ($null -eq $resolved) {
        Add-Fail 'Local web artifact comparison' "CompareBuildWebPath does not exist: $Path"
        return ''
    }

    $indexPath = Join-Path $resolved.ProviderPath 'index.html'
    if (-not (Test-Path -LiteralPath $indexPath)) {
        Add-Fail 'Local web artifact comparison' "CompareBuildWebPath is not a Flutter web build directory: $Path"
        return ''
    }

    Add-Pass 'Local web artifact comparison' "Comparing deployed app assets with $($resolved.ProviderPath)."
    return $resolved.ProviderPath
}

function Assert-DeployedAssetMatchesLocal {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$RemoteContent,
        [AllowEmptyString()]
        [string]$LocalBuildWebPath,
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    if ([string]::IsNullOrWhiteSpace($LocalBuildWebPath)) {
        return
    }

    $localPath = Join-Path $LocalBuildWebPath $RelativePath
    if (-not (Test-Path -LiteralPath $localPath)) {
        Add-Fail "$Name deployed asset freshness" "Local comparison asset is missing: $localPath"
        return
    }

    $comparisonDetail = ''
    if ($RelativePath -eq 'flutter_bootstrap.js') {
        $localContent = Get-Content -LiteralPath $localPath -Raw
        $remoteHash = Get-Sha256HexFromText -Content (Normalize-FlutterBootstrapForComparison -Content $RemoteContent)
        $localHash = Get-Sha256HexFromText -Content (Normalize-FlutterBootstrapForComparison -Content $localContent)
        $comparisonDetail = ' after normalizing generated serviceWorkerVersion'
    } else {
        $remoteHash = Get-Sha256HexFromText -Content $RemoteContent
        $localHash = Get-Sha256HexFromFile -Path $localPath
    }

    if ($remoteHash -ne $localHash) {
        Add-Fail "$Name deployed asset freshness" "Deployed $RelativePath hash $remoteHash does not match local build hash $localHash$comparisonDetail."
        return
    }

    Add-Pass "$Name deployed asset freshness" "Deployed $RelativePath matches the local build hash $localHash$comparisonDetail."
}

function Resolve-IndexBaseUri {
    param(
        [Parameter(Mandatory = $true)]
        [System.Uri]$Root,
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $indexUri = Join-DeploymentPath -Root $Root -Path '/'
    $baseMatch = [regex]::Match(
        $Content,
        '<base\s+[^>]*href\s*=\s*["''](?<href>[^"'']+)["'']',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )

    if (-not $baseMatch.Success) {
        Add-Fail 'Flutter base href' 'Deployed index.html is missing a <base href> tag.'
        return $indexUri
    }

    $baseHref = $baseMatch.Groups['href'].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($baseHref)) {
        Add-Fail 'Flutter base href' 'Deployed index.html has an empty <base href>.'
        return $indexUri
    }

    $resolvedBaseUri = [System.Uri]::new($indexUri, $baseHref)
    if ($resolvedBaseUri.AbsoluteUri.TrimEnd('/') -ne $indexUri.AbsoluteUri.TrimEnd('/')) {
        Add-Fail 'Flutter base href' "Base href '$baseHref' resolves assets under $($resolvedBaseUri.AbsoluteUri.TrimEnd('/')), but deployment root is $($indexUri.AbsoluteUri.TrimEnd('/'))."
    } else {
        Add-Pass 'Flutter base href' "Base href '$baseHref' resolves assets under the deployment root."
    }

    return $resolvedBaseUri
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

Assert-SupportEmail -Name 'SupportEmail' -Value $SupportEmail

$rootUri = Resolve-DeploymentUri -Value $BaseUrl
$compareBuildWebRoot = Resolve-CompareBuildWebPath -Path $CompareBuildWebPath
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
$assetBaseUri = Join-DeploymentPath -Root $rootUri -Path '/'
if (-not [string]::IsNullOrWhiteSpace($index)) {
    [void](Assert-TextContains -CheckName 'App shell content' -Content $index -Terms @('flutter_bootstrap.js', 'manifest.json'))
    $assetBaseUri = Resolve-IndexBaseUri -Root $rootUri -Content $index
}

$flutterBootstrap = Invoke-WebCheck -Name 'Flutter bootstrap' -Uri ([System.Uri]::new($assetBaseUri, 'flutter_bootstrap.js'))
if (-not [string]::IsNullOrWhiteSpace($flutterBootstrap)) {
    [void](Assert-TextContains -CheckName 'Flutter bootstrap content' -Content $flutterBootstrap -Terms @('main.dart.js'))
    Assert-DeployedAssetMatchesLocal -Name 'Flutter bootstrap' -RemoteContent $flutterBootstrap -LocalBuildWebPath $compareBuildWebRoot -RelativePath 'flutter_bootstrap.js'
}

$compiledApp = Invoke-WebCheck -Name 'Compiled Flutter app' -Uri ([System.Uri]::new($assetBaseUri, 'main.dart.js'))
if (-not [string]::IsNullOrWhiteSpace($compiledApp)) {
    [void](Assert-TextContains -CheckName 'Compiled Flutter app content' -Content $compiledApp -Terms @('main'))
    Assert-DeployedAssetMatchesLocal -Name 'Compiled Flutter app' -RemoteContent $compiledApp -LocalBuildWebPath $compareBuildWebRoot -RelativePath 'main.dart.js'
}

$manifest = Invoke-WebCheck -Name 'Web manifest' -Uri ([System.Uri]::new($assetBaseUri, 'manifest.json'))
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
    compareBuildWebPath = $compareBuildWebRoot
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
