param(
    [string]$KeyPropertiesPath = 'android/key.properties',
    [string]$OutFile = '.env.release.android-signing.generated'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Resolve-RepoPath {
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

function Read-PropertiesFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    $properties = @{}
    $lineNumber = 0
    foreach ($line in Get-Content -LiteralPath $Path) {
        $lineNumber += 1
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) {
            continue
        }

        if ($line -match '\\\s*$') {
            throw "Unsupported Java properties continuation at line $lineNumber. Use plain key=value lines before exporting."
        }
        if ($line -match '\\') {
            throw "Unsupported Java properties escaping at line $lineNumber. Use plain key=value lines before exporting."
        }
        if ($line -notmatch '^([^=\s:#]+)=(.*)$') {
            throw "Unsupported key.properties syntax at line $lineNumber. Use plain key=value lines with no spaces around the separator."
        }

        $key = $matches[1]
        $value = $matches[2]
        if ($value -ne $value.Trim()) {
            throw "Unsupported whitespace-sensitive value at line $lineNumber. Use plain key=value lines without leading or trailing value spaces."
        }
        if ($properties.ContainsKey($key)) {
            throw "Duplicate key.properties entry: $key"
        }

        $properties[$key] = $value
    }

    return $properties
}

function Assert-GitIgnoredOutput {
    param([Parameter(Mandatory = $true)][string]$Path)

    $relativePath = [System.IO.Path]::GetRelativePath($repoRoot, $Path).Replace('\', '/')
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($null -eq $git) {
        throw 'git is required to verify that the Android signing env handoff output is ignored.'
    }

    & $git.Source -C $repoRoot check-ignore -q -- $relativePath
    if ($LASTEXITCODE -ne 0) {
        throw "OutFile must be gitignored before signing secrets can be written: $relativePath"
    }
}

function Assert-SecretValue {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [AllowNull()][string]$Value
    )

    if (
        [string]::IsNullOrWhiteSpace($Value) -or
        $Value -match 'REPLACE_WITH|YOUR_|<your-|placeholder'
    ) {
        throw "$Name is missing or placeholder-shaped in key.properties."
    }
}

Push-Location $repoRoot
try {
    $keyPropertiesFullPath = Resolve-RepoPath -Path $KeyPropertiesPath -Name 'KeyPropertiesPath'
    $outFullPath = Resolve-RepoPath -Path $OutFile -Name 'OutFile'

    if (-not (Test-Path -LiteralPath $keyPropertiesFullPath)) {
        throw "Missing key.properties file: $KeyPropertiesPath"
    }
    if (Test-Path -LiteralPath $outFullPath) {
        throw "Android signing env handoff already exists and will not be overwritten: $OutFile"
    }
    Assert-GitIgnoredOutput -Path $outFullPath

    $properties = Read-PropertiesFile -Path $keyPropertiesFullPath
    foreach ($field in @('storeFile', 'storePassword', 'keyAlias', 'keyPassword')) {
        Assert-SecretValue -Name $field -Value $properties[$field]
    }

    $keyPropertiesDir = Split-Path -Parent $keyPropertiesFullPath
    $storeFile = [string]$properties['storeFile']
    $keystoreFullPath = if ([System.IO.Path]::IsPathRooted($storeFile)) {
        [System.IO.Path]::GetFullPath($storeFile)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $keyPropertiesDir $storeFile))
    }

    $relativeKeystorePath = [System.IO.Path]::GetRelativePath($repoRoot, $keystoreFullPath)
    if ($relativeKeystorePath.StartsWith('..') -or [System.IO.Path]::IsPathRooted($relativeKeystorePath)) {
        throw "storeFile must stay inside the repository: $storeFile"
    }
    if (-not (Test-Path -LiteralPath $keystoreFullPath)) {
        throw "Missing upload keystore referenced by key.properties: $storeFile"
    }

    $outParent = Split-Path -Parent $outFullPath
    if (-not [string]::IsNullOrWhiteSpace($outParent)) {
        New-Item -ItemType Directory -Force -Path $outParent | Out-Null
    }

    $keystoreBase64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($keystoreFullPath))
    $envFileContent = @(
        '# FlowFit Android upload signing secrets. Keep this file private.',
        '# Generated from an existing local android/key.properties and upload keystore.',
        '# Use configure_github_release_variables.ps1 for public release variables only; GitHub signing values must be repository secrets.',
        "FLOWFIT_ANDROID_KEYSTORE_BASE64=$keystoreBase64",
        "FLOWFIT_ANDROID_KEYSTORE_PASSWORD=$($properties['storePassword'])",
        "FLOWFIT_ANDROID_KEY_ALIAS=$($properties['keyAlias'])",
        "FLOWFIT_ANDROID_KEY_PASSWORD=$($properties['keyPassword'])",
        ("FLOWFIT_ANDROID_KEYSTORE_FILE_NAME={0}" -f [System.IO.Path]::GetFileName($keystoreFullPath))
    ) -join [Environment]::NewLine
    Set-Content -LiteralPath $outFullPath -Value $envFileContent -NoNewline

    Write-Host "Android signing env handoff exported: $([System.IO.Path]::GetRelativePath($repoRoot, $outFullPath))"
    Write-Host 'Secret values were written only to the ignored handoff file and were not printed.'
    Write-Host 'Copy the values into private GitHub repository secrets only after backing up the upload key material.'
    Write-Host 'ANDROID_SIGNING_ENV_EXPORTED'
} finally {
    Pop-Location
}
