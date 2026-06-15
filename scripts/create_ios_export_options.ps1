param(
    [string]$OutFile = 'ios/ExportOptions.plist',
    [string]$BundleIdentifier = '',
    [Parameter(Mandatory = $true)]
    [string]$TeamId,
    [ValidateSet('manual', 'automatic')]
    [string]$SigningStyle = 'manual',
    [string]$ProvisioningProfileName = '',
    [ValidateSet('app-store-connect', 'app-store', 'ad-hoc', 'development', 'enterprise')]
    [string]$Method = 'app-store-connect',
    [ValidateSet('export', 'upload')]
    [string]$Destination = 'export',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Resolve-RepoOutputPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "$Name must not be empty."
    }

    $fullPath = if ([System.IO.Path]::IsPathRooted($Path)) {
        [System.IO.Path]::GetFullPath($Path)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
    }

    $relativePath = [System.IO.Path]::GetRelativePath($repoRoot, $fullPath)
    if ($relativePath.StartsWith('..') -or [System.IO.Path]::IsPathRooted($relativePath)) {
        throw "$Name must stay inside the repository: $Path"
    }

    return $fullPath
}

function Ensure-ParentDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)

    $parent = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
}

function Read-Properties {
    param([string]$Path)

    $properties = @{}
    if (-not (Test-Path -LiteralPath $Path)) {
        return $properties
    }

    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^\s*$' -or $line -match '^\s*(#|//)') {
            continue
        }
        if ($line -match '^\s*([^=]+?)\s*=\s*(.*)\s*$') {
            $properties[$matches[1].Trim()] = $matches[2].Trim()
        }
    }

    return $properties
}

function Resolve-XcconfigValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value,
        [Parameter(Mandatory = $true)]
        [hashtable]$Properties
    )

    $resolved = $Value
    foreach ($key in $Properties.Keys) {
        $placeholder = '$(' + [string]$key + ')'
        $resolved = $resolved.Replace($placeholder, $Properties[$key])
    }

    return $resolved.Trim()
}

function Get-ConfiguredBundleIdentifier {
    $configPath = Join-Path $repoRoot 'ios/Flutter/FlowFit.xcconfig'
    if (-not (Test-Path -LiteralPath $configPath)) {
        throw 'Missing ios/Flutter/FlowFit.xcconfig. Pass -BundleIdentifier explicitly or restore the tracked iOS config.'
    }

    $properties = Read-Properties -Path $configPath
    if (-not $properties.ContainsKey('FLOWFIT_IOS_BUNDLE_IDENTIFIER')) {
        throw 'ios/Flutter/FlowFit.xcconfig is missing FLOWFIT_IOS_BUNDLE_IDENTIFIER.'
    }

    return Resolve-XcconfigValue -Value $properties['FLOWFIT_IOS_BUNDLE_IDENTIFIER'] -Properties $properties
}

function Assert-SingleLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -match "[\r\n]") {
        throw "$Name must be a non-empty single-line value."
    }
}

function Assert-ProductionBundleIdentifier {
    param([Parameter(Mandatory = $true)][string]$Value)

    if (
        [string]::IsNullOrWhiteSpace($Value) -or
        $Value -notmatch '^[A-Za-z0-9][A-Za-z0-9.-]*\.[A-Za-z0-9.-]+$' -or
        $Value -match '(^|\.)(example|invalid|test|local)(\.|$)' -or
        $Value -match 'com\.example|com\.yourcompany|com\.flowfit\.smoke|YOUR_|REPLACE_WITH|<your-'
    ) {
        throw "BundleIdentifier must be production-shaped and owned by the selected Apple Developer team: $Value"
    }
}

function Assert-TeamId {
    param([Parameter(Mandatory = $true)][string]$Value)

    if ($Value -notmatch '^[A-Z0-9]{10}$' -or $Value -match 'YOUR_|REPLACE_WITH|TEAMID') {
        throw 'TeamId must be the 10-character Apple Developer Team ID, for example ABCDE12345.'
    }
}

function ConvertTo-PlistString {
    param([Parameter(Mandatory = $true)][string]$Value)
    return [System.Security.SecurityElement]::Escape($Value)
}

Push-Location $repoRoot
try {
    if ([string]::IsNullOrWhiteSpace($BundleIdentifier)) {
        $BundleIdentifier = Get-ConfiguredBundleIdentifier
    }

    $BundleIdentifier = $BundleIdentifier.Trim()
    $TeamId = $TeamId.Trim().ToUpperInvariant()
    Assert-ProductionBundleIdentifier -Value $BundleIdentifier
    Assert-TeamId -Value $TeamId

    if ($SigningStyle -eq 'manual') {
        Assert-SingleLine -Name 'ProvisioningProfileName' -Value $ProvisioningProfileName
        if ($ProvisioningProfileName -match 'YOUR_|REPLACE_WITH|<your-') {
            throw 'ProvisioningProfileName must be the real Apple provisioning profile name, not a placeholder.'
        }
    }

    $outPath = Resolve-RepoOutputPath -Path $OutFile -Name 'OutFile'
    if ((Test-Path -LiteralPath $outPath) -and -not $Force) {
        throw "Export options plist already exists and will not be overwritten without -Force: $OutFile"
    }

    Ensure-ParentDirectory -Path $outPath

    $methodXml = ConvertTo-PlistString $Method
    $destinationXml = ConvertTo-PlistString $Destination
    $teamIdXml = ConvertTo-PlistString $TeamId
    $signingStyleXml = ConvertTo-PlistString $SigningStyle
    $bundleIdXml = ConvertTo-PlistString $BundleIdentifier

    $profileXml = ''
    if ($SigningStyle -eq 'manual') {
        $provisioningProfileNameXml = ConvertTo-PlistString $ProvisioningProfileName.Trim()
        $profileXml = @"
	<key>provisioningProfiles</key>
	<dict>
		<key>$bundleIdXml</key>
		<string>$provisioningProfileNameXml</string>
	</dict>
"@
    }

    $plist = @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>destination</key>
	<string>$destinationXml</string>
	<key>manageAppVersionAndBuildNumber</key>
	<false/>
	<key>method</key>
	<string>$methodXml</string>
$profileXml
	<key>signingCertificate</key>
	<string>Apple Distribution</string>
	<key>signingStyle</key>
	<string>$signingStyleXml</string>
	<key>stripSwiftSymbols</key>
	<true/>
	<key>teamID</key>
	<string>$teamIdXml</string>
	<key>uploadSymbols</key>
	<true/>
</dict>
</plist>
"@

    Set-Content -LiteralPath $outPath -Value $plist -Encoding utf8NoBOM

    $relativePath = [System.IO.Path]::GetRelativePath($repoRoot, $outPath).Replace('\', '/')
    Write-Host "iOS export options plist written: $relativePath"
    Write-Host "Bundle identifier: $BundleIdentifier"
    Write-Host "Signing style: $SigningStyle"
    Write-Host "Team ID: $TeamId"
    if ($SigningStyle -eq 'manual') {
        Write-Host 'Provisioning profile name was written to the ignored plist and was not printed.'
    }
    Write-Host "Set FLOWFIT_IOS_EXPORT_OPTIONS_PLIST=$relativePath on the macOS release host before running scripts/store_release_build.ps1 -Target iOS."
    Write-Host 'IOS_EXPORT_OPTIONS_PLIST_WRITTEN'
} finally {
    Pop-Location
}
