param(
    [string]$KeystorePath = 'android/upload-keystore.jks',
    [string]$KeyPropertiesPath = 'android/key.properties',
    [string]$EnvFile = '.env.release.android-signing',
    [string]$Alias = 'upload',
    [string]$DistinguishedName = 'CN=FlowFit Upload, OU=Release, O=OldStLabs, L=Manila, S=Metro Manila, C=PH',
    [int]$ValidityDays = 10000,
    [switch]$SkipEnvFile
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

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

function New-RandomPassword {
    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    } finally {
        $rng.Dispose()
    }

    return [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

function Assert-NewOutputFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (Test-Path -LiteralPath $Path) {
        throw "$Name already exists and will not be overwritten: $Path"
    }
}

function Ensure-ParentDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)

    $parent = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
}

Push-Location $repoRoot
try {
    if ($Alias -match "[\r\n]" -or [string]::IsNullOrWhiteSpace($Alias)) {
        throw 'Alias must be a non-empty single-line value.'
    }
    if ($DistinguishedName -match "[\r\n]" -or [string]::IsNullOrWhiteSpace($DistinguishedName)) {
        throw 'DistinguishedName must be a non-empty single-line value.'
    }
    if ($ValidityDays -lt 365) {
        throw 'ValidityDays must be at least 365.'
    }

    $keytool = Get-Command keytool -ErrorAction SilentlyContinue
    if ($null -eq $keytool) {
        throw 'keytool is required. Install a JDK or run this from a Flutter/Android build machine with Java available.'
    }

    $keystoreFullPath = Resolve-RepoOutputPath -Path $KeystorePath -Name 'KeystorePath'
    $keyPropertiesFullPath = Resolve-RepoOutputPath -Path $KeyPropertiesPath -Name 'KeyPropertiesPath'
    $envFileFullPath = if ($SkipEnvFile) {
        ''
    } else {
        Resolve-RepoOutputPath -Path $EnvFile -Name 'EnvFile'
    }

    Assert-NewOutputFile -Path $keystoreFullPath -Name 'Keystore'
    Assert-NewOutputFile -Path $keyPropertiesFullPath -Name 'key.properties'
    if (-not $SkipEnvFile) {
        Assert-NewOutputFile -Path $envFileFullPath -Name 'Android signing env file'
    }

    Ensure-ParentDirectory -Path $keystoreFullPath
    Ensure-ParentDirectory -Path $keyPropertiesFullPath
    if (-not $SkipEnvFile) {
        Ensure-ParentDirectory -Path $envFileFullPath
    }

    $storePassword = New-RandomPassword
    $keyPassword = New-RandomPassword
    $generatedFiles = New-Object System.Collections.Generic.List[string]

    try {
        $keytoolOutput = & $keytool.Source @(
            '-genkeypair',
            '-keystore', $keystoreFullPath,
            '-alias', $Alias,
            '-keyalg', 'RSA',
            '-keysize', '2048',
            '-storetype', 'JKS',
            '-validity', [string]$ValidityDays,
            '-storepass', $storePassword,
            '-keypass', $keyPassword,
            '-dname', $DistinguishedName
        ) 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "keytool failed to create the upload keystore: $($keytoolOutput -join "`n")"
        }
        $generatedFiles.Add($keystoreFullPath)

        $androidDir = [System.IO.Path]::GetFullPath((Join-Path $repoRoot 'android'))
        $storeFileForProperties = [System.IO.Path]::GetRelativePath($androidDir, $keystoreFullPath).Replace('\', '/')
        $keyPropertiesContent = @(
            "storePassword=$storePassword",
            "keyPassword=$keyPassword",
            "keyAlias=$Alias",
            "storeFile=$storeFileForProperties"
        ) -join [Environment]::NewLine
        Set-Content -LiteralPath $keyPropertiesFullPath -Value $keyPropertiesContent -NoNewline
        $generatedFiles.Add($keyPropertiesFullPath)

        if (-not $SkipEnvFile) {
            $keystoreBase64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($keystoreFullPath))
            $envFileContent = @(
                '# FlowFit Android upload signing secrets. Keep this file private.',
                '# Use configure_github_release_variables.ps1 for public release variables only; GitHub signing values must be repository secrets.',
                "FLOWFIT_ANDROID_KEYSTORE_BASE64=$keystoreBase64",
                "FLOWFIT_ANDROID_KEYSTORE_PASSWORD=$storePassword",
                "FLOWFIT_ANDROID_KEY_ALIAS=$Alias",
                "FLOWFIT_ANDROID_KEY_PASSWORD=$keyPassword",
                ("FLOWFIT_ANDROID_KEYSTORE_FILE_NAME={0}" -f [System.IO.Path]::GetFileName($keystoreFullPath))
            ) -join [Environment]::NewLine
            Set-Content -LiteralPath $envFileFullPath -Value $envFileContent -NoNewline
            $generatedFiles.Add($envFileFullPath)
        }

        Write-Host "Android upload keystore created: $([System.IO.Path]::GetRelativePath($repoRoot, $keystoreFullPath))"
        Write-Host "Android key properties written: $([System.IO.Path]::GetRelativePath($repoRoot, $keyPropertiesFullPath))"
        if (-not $SkipEnvFile) {
            Write-Host "Android signing env handoff written: $([System.IO.Path]::GetRelativePath($repoRoot, $envFileFullPath))"
        }
        Write-Host 'Secret values were written only to ignored local files and were not printed.'
        Write-Host 'Back up these files in a private password manager before uploading a Play Store artifact.'
        Write-Host 'ANDROID_UPLOAD_KEYSTORE_CREATED'
    } catch {
        foreach ($path in @($generatedFiles.ToArray())) {
            if (Test-Path -LiteralPath $path) {
                Remove-Item -LiteralPath $path -Force
            }
        }
        throw
    }
} finally {
    Pop-Location
}
