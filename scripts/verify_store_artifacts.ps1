param(
    [string]$ManifestPath = 'build/store-release-artifacts.json',
    [string]$OutFile = 'build/store-release-artifact-verification.json',
    [switch]$Strict,
    [string[]]$RequireArtifact = @(),
    [string]$RequireWebBackend = '',
    [switch]$RequireStrictAudit,
    [switch]$AllowDirtyManifest,
    [switch]$RequireCurrentCommit
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PASS', 'WARN', 'FAIL')]
        [string]$Level,
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Detail,
        [bool]$StrictFailure = $true
    )

    $effectiveLevel = $Level
    if ($Strict -and $Level -eq 'WARN' -and $StrictFailure) {
        $effectiveLevel = 'FAIL'
    }

    $script:results.Add([pscustomobject]@{
        level = $effectiveLevel
        name = $Name
        detail = $Detail
    })
}

function Add-Pass {
    param([string]$Name, [string]$Detail)
    Add-Result -Level 'PASS' -Name $Name -Detail $Detail
}

function Add-Warn {
    param([string]$Name, [string]$Detail, [bool]$StrictFailure = $true)
    Add-Result -Level 'WARN' -Name $Name -Detail $Detail -StrictFailure $StrictFailure
}

function Add-Fail {
    param([string]$Name, [string]$Detail)
    Add-Result -Level 'FAIL' -Name $Name -Detail $Detail
}

function Resolve-RepoContainedPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $candidate = if ([System.IO.Path]::IsPathRooted($Path)) {
        [System.IO.Path]::GetFullPath($Path)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
    }

    $relative = [System.IO.Path]::GetRelativePath($repoRoot, $candidate)
    if ($relative.StartsWith('..') -or [System.IO.Path]::IsPathRooted($relative)) {
        throw "Path must stay inside the repository: $Path"
    }

    return [pscustomobject]@{
        FullPath = $candidate
        RelativePath = $relative.Replace('\', '/')
    }
}

function Get-DirectoryDigest {
    param([Parameter(Mandatory = $true)][string]$Path)

    $files = @(Get-ChildItem -Path $Path -Recurse -File | Sort-Object FullName)
    $totalBytes = [int64]0
    $digestInput = New-Object System.Text.StringBuilder

    foreach ($file in $files) {
        $totalBytes += $file.Length
        $relativePath = [System.IO.Path]::GetRelativePath($Path, $file.FullName).Replace('\', '/')
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash.ToLowerInvariant()
        [void]$digestInput.AppendLine("$relativePath|$($file.Length)|$hash")
    }

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($digestInput.ToString())
        $digest = [System.BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }

    return [pscustomobject]@{
        sha256 = $digest
        sizeBytes = $totalBytes
        fileCount = $files.Count
    }
}

function Get-ArtifactEvidence {
    param(
        [Parameter(Mandatory = $true)][string]$Kind,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $resolved = Resolve-RepoContainedPath -Path $Path
    if (-not (Test-Path -LiteralPath $resolved.FullPath)) {
        return [pscustomobject]@{
            exists = $false
            path = $resolved.RelativePath
        }
    }

    $item = Get-Item -LiteralPath $resolved.FullPath
    if ($Kind -eq 'directory') {
        if (-not $item.PSIsContainer) {
            throw "Artifact kind is directory but path is not a directory: $Path"
        }
        $digest = Get-DirectoryDigest -Path $item.FullName
        return [pscustomobject]@{
            exists = $true
            path = $resolved.RelativePath
            kind = 'directory'
            sha256 = $digest.sha256
            sizeBytes = $digest.sizeBytes
            fileCount = $digest.fileCount
        }
    }

    if ($Kind -ne 'file') {
        throw "Artifact kind must be file or directory: $Kind"
    }
    if ($item.PSIsContainer) {
        throw "Artifact kind is file but path is a directory: $Path"
    }

    return [pscustomobject]@{
        exists = $true
        path = $resolved.RelativePath
        kind = 'file'
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $item.FullName).Hash.ToLowerInvariant()
        sizeBytes = $item.Length
        fileCount = 1
    }
}

function Test-Artifact {
    param([Parameter(Mandatory = $true)]$Artifact)

    $name = [string]$Artifact.name
    $kind = [string]$Artifact.kind
    $path = [string]$Artifact.path
    $expectedHash = [string]$Artifact.sha256
    $expectedBytes = [int64]$Artifact.sizeBytes
    $expectedFileCount = [int64]$Artifact.fileCount

    if ([string]::IsNullOrWhiteSpace($name)) {
        Add-Fail 'Artifact manifest entry' 'An artifact entry is missing name.'
        return
    }
    if ([string]::IsNullOrWhiteSpace($path)) {
        Add-Fail "Artifact: $name" 'Artifact entry is missing path.'
        return
    }
    if ($expectedHash -notmatch '^[a-f0-9]{64}$') {
        Add-Fail "Artifact: $name" 'Artifact entry is missing a lowercase SHA-256 digest.'
        return
    }

    try {
        $actual = Get-ArtifactEvidence -Kind $kind -Path $path
    } catch {
        Add-Fail "Artifact: $name" $_.Exception.Message
        return
    }

    if (-not $actual.exists) {
        Add-Fail "Artifact: $name" "Artifact path does not exist: $($actual.path)"
        return
    }

    $failures = @()
    if ($actual.sha256 -ne $expectedHash) {
        $failures += 'sha256'
    }
    if ($actual.sizeBytes -ne $expectedBytes) {
        $failures += 'sizeBytes'
    }
    if ($actual.fileCount -ne $expectedFileCount) {
        $failures += 'fileCount'
    }

    if ($failures.Count -gt 0) {
        Add-Fail "Artifact: $name" "Artifact evidence mismatch for $($failures -join ', '): $($actual.path)"
    } else {
        Add-Pass "Artifact: $name" "Verified $kind artifact $($actual.path)."
    }
}

function Invoke-Git {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        return ''
    }

    try {
        $output = & git @Arguments 2>$null
        if ($LASTEXITCODE -ne 0) {
            return ''
        }
        return ($output | Out-String).Trim()
    } catch {
        return ''
    }
}

Push-Location $repoRoot
try {
    $resolvedManifest = Resolve-RepoContainedPath -Path $ManifestPath
    if (-not (Test-Path -LiteralPath $resolvedManifest.FullPath)) {
        Add-Fail 'Store release artifact manifest' "Missing artifact manifest: $($resolvedManifest.RelativePath)"
        $manifest = $null
    } else {
        try {
            $manifest = Get-Content -Raw -LiteralPath $resolvedManifest.FullPath | ConvertFrom-Json
            Add-Pass 'Store release artifact manifest' "Parsed $($resolvedManifest.RelativePath)."
        } catch {
            Add-Fail 'Store release artifact manifest' "Unable to parse manifest JSON: $($_.Exception.Message)"
            $manifest = $null
        }
    }

    if ($null -ne $manifest) {
        $target = [string]$manifest.target
        if (@('Android', 'iOS', 'Web', 'All').Contains($target)) {
            Add-Pass 'Release target' "Manifest target is $target."
        } else {
            Add-Fail 'Release target' "Manifest target is missing or invalid: $target"
        }

        $artifacts = @($manifest.artifacts)
        if ($artifacts.Count -gt 0) {
            Add-Pass 'Artifact list' "Manifest lists $($artifacts.Count) artifact(s)."
        } else {
            Add-Fail 'Artifact list' 'Manifest does not list any artifacts.'
        }

        $artifactNames = @($artifacts | ForEach-Object { [string]$_.name })
        foreach ($required in $RequireArtifact) {
            if ($artifactNames.Contains($required)) {
                Add-Pass 'Required artifact' "Manifest includes $required."
            } else {
                Add-Fail 'Required artifact' "Manifest does not include required artifact: $required"
            }
        }

        foreach ($artifact in $artifacts) {
            Test-Artifact -Artifact $artifact
        }

        $releaseInputs = $manifest.releaseInputs
        if ($null -eq $releaseInputs) {
            Add-Fail 'Release inputs' 'Manifest is missing releaseInputs.'
        } else {
            $supportEmail = [string]$releaseInputs.supportEmail
            $publicWebBaseUrl = [string]$releaseInputs.publicWebBaseUrl
            if (
                [string]::IsNullOrWhiteSpace($supportEmail) -or
                $supportEmail.Trim().ToLowerInvariant() -eq 'support@flowfit.com' -or
                $supportEmail -match 'YOUR_|REPLACE_WITH|<your-|example\.|invalid\.|\.test$|localhost'
            ) {
                Add-Fail 'Release input: support email' 'Manifest support email is missing, reserved, or placeholder-shaped.'
            } else {
                Add-Pass 'Release input: support email' 'Manifest support email is release-shaped.'
            }

            if ([string]::IsNullOrWhiteSpace($publicWebBaseUrl) -or $publicWebBaseUrl -notmatch '^https://') {
                Add-Fail 'Release input: public web URL' 'Manifest public web URL must be a deployed HTTPS URL.'
            } else {
                Add-Pass 'Release input: public web URL' 'Manifest public web URL is HTTPS.'
            }

            if (-not [string]::IsNullOrWhiteSpace($RequireWebBackend)) {
                $actualBackend = [string]$releaseInputs.webBuildBackend
                if ($actualBackend -eq $RequireWebBackend) {
                    Add-Pass 'Release input: web backend' "Manifest web backend is $actualBackend."
                } else {
                    Add-Fail 'Release input: web backend' "Manifest web backend is $actualBackend, expected $RequireWebBackend."
                }
            }
        }

        $git = $manifest.git
        if ($null -eq $git) {
            Add-Fail 'Git evidence' 'Manifest is missing git evidence.'
        } else {
            $manifestCommit = [string]$git.commit
            if ($manifestCommit -match '^[a-f0-9]{40}$') {
                Add-Pass 'Git evidence' "Manifest records commit $($manifestCommit.Substring(0, 7))."
            } else {
                Add-Fail 'Git evidence' 'Manifest commit is missing or not a full SHA.'
            }

            if ([bool]$git.dirty -and -not $AllowDirtyManifest) {
                Add-Fail 'Git cleanliness' 'Manifest was generated from a dirty working tree.'
            } elseif ([bool]$git.dirty) {
                Add-Warn 'Git cleanliness' 'Manifest was generated from a dirty working tree with AllowDirtyManifest accepted.' -StrictFailure $false
            } else {
                Add-Pass 'Git cleanliness' 'Manifest was generated from a clean working tree.'
            }

            if ($RequireCurrentCommit) {
                $currentCommit = Invoke-Git -Arguments @('rev-parse', 'HEAD')
                if ([string]::IsNullOrWhiteSpace($currentCommit)) {
                    Add-Fail 'Current commit match' 'Unable to read current git commit.'
                } elseif ($currentCommit -eq $manifestCommit) {
                    Add-Pass 'Current commit match' 'Manifest commit matches HEAD.'
                } else {
                    Add-Fail 'Current commit match' "Manifest commit $manifestCommit does not match HEAD $currentCommit."
                }
            }
        }

        $strictAudit = $manifest.strictAudit
        if ($RequireStrictAudit) {
            if ($null -eq $strictAudit -or -not [bool]$strictAudit.ran) {
                Add-Fail 'Strict audit evidence' 'Manifest does not record a strict release readiness audit.'
            } elseif ($null -eq $strictAudit.summary) {
                Add-Fail 'Strict audit evidence' 'Manifest strict audit evidence is missing summary.'
            } elseif ([int]$strictAudit.summary.fail -eq 0) {
                Add-Pass 'Strict audit evidence' 'Manifest records a strict audit with zero failures.'
            } else {
                Add-Fail 'Strict audit evidence' "Manifest strict audit has $($strictAudit.summary.fail) failure(s)."
            }
        } elseif ($null -ne $strictAudit -and [bool]$strictAudit.ran) {
            Add-Pass 'Strict audit evidence' 'Manifest includes strict audit evidence.'
        } else {
            Add-Warn 'Strict audit evidence' 'Manifest does not include strict audit evidence; use -RequireStrictAudit for store handoff.' -StrictFailure $false
        }
    }

    $summary = [pscustomobject]@{
        pass = @($results | Where-Object { $_.level -eq 'PASS' }).Count
        warn = @($results | Where-Object { $_.level -eq 'WARN' }).Count
        fail = @($results | Where-Object { $_.level -eq 'FAIL' }).Count
    }

    $evidence = [pscustomobject]@{
        generatedAt = (Get-Date).ToUniversalTime().ToString('o')
        strict = [bool]$Strict
        manifestPath = if ($null -ne $resolvedManifest) { $resolvedManifest.RelativePath } else { $ManifestPath }
        requiredArtifacts = @($RequireArtifact)
        requireWebBackend = $RequireWebBackend
        requireStrictAudit = [bool]$RequireStrictAudit
        requireCurrentCommit = [bool]$RequireCurrentCommit
        summary = $summary
        results = @($results.ToArray())
    }

    $resolvedOut = Resolve-RepoContainedPath -Path $OutFile
    $parent = Split-Path -Parent $resolvedOut.FullPath
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    $evidence | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $resolvedOut.FullPath -Encoding utf8NoBOM

    Write-Host "Store artifact verification written: $($resolvedOut.RelativePath)"
    Write-Host "Audit summary: $($summary.pass) pass, $($summary.warn) warn, $($summary.fail) fail."
    Write-Host 'STORE_ARTIFACT_VERIFICATION_WRITTEN'

    if ($summary.fail -gt 0) {
        exit 1
    }
    if ($summary.warn -gt 0) {
        exit 2
    }
} finally {
    Pop-Location
}
