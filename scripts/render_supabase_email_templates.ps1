param(
    [string]$SupportEmail = '',
    [string]$EnvFile = '',
    [string]$OutDir = 'build/supabase-email-templates',
    [switch]$SupportEmailVerified
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$replacementToken = 'REPLACE_WITH_FLOWFIT_SUPPORT_EMAIL'
$reservedSupportEmail = 'support@flowfit.com'

function Import-ReleaseEnvFile {
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
        throw "Release env file does not exist: $envPath"
    }

    foreach ($line in Get-Content -LiteralPath $envPath) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) {
            continue
        }
        if ($trimmed -notmatch '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$') {
            throw "Invalid release env file line: $line"
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
        $normalized -match '["''<>?&/%\x00-\x1F\x7F]' -or
        $normalized -match 'YOUR_|REPLACE_WITH|<your-|example\.|invalid\.|\.test$|localhost'
    ) {
        throw "$Name must be a real plain support mailbox."
    }

    if ($normalized.ToLowerInvariant() -eq $script:reservedSupportEmail) {
        throw "$Name must be a verified deliverable support/privacy inbox. $script:reservedSupportEmail is the reserved source replacement token."
    }

    return $normalized
}

function Assert-VerifiedSupportEmail {
    $verified = $SupportEmailVerified -or (
        [Environment]::GetEnvironmentVariable('FLOWFIT_SUPPORT_EMAIL_VERIFIED') -eq 'true'
    )

    if (-not $verified) {
        throw 'FLOWFIT_SUPPORT_EMAIL_VERIFIED=true or -SupportEmailVerified is required after confirming the configured support inbox can receive external mail.'
    }
}

function Resolve-RepoOutputDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)

    $resolved = if ([System.IO.Path]::IsPathRooted($Path)) {
        [System.IO.Path]::GetFullPath($Path)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
    }

    $relative = [System.IO.Path]::GetRelativePath($repoRoot, $resolved)
    if ($relative.StartsWith('..') -or [System.IO.Path]::IsPathRooted($relative)) {
        throw "OutDir must stay inside the repository: $Path"
    }
    if (
        $relative -eq 'build' -or
        -not $relative.StartsWith("build$([System.IO.Path]::DirectorySeparatorChar)")
    ) {
        throw "OutDir must be a generated directory under build/: $Path"
    }

    return $resolved
}

function Get-RepoRelativePath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.Path]::GetRelativePath($repoRoot, $Path).Replace('\', '/')
}

function Get-FileSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Assert-RenderedTemplate {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [Parameter(Mandatory = $true)]
        [string]$SupportEmail
    )

    if ($Content.Contains($script:replacementToken)) {
        throw "Rendered template still contains $script:replacementToken`: $Path"
    }
    if ($Content.Contains($script:reservedSupportEmail)) {
        throw "Rendered template still contains reserved support email $script:reservedSupportEmail`: $Path"
    }
    if (-not $Content.Contains($SupportEmail)) {
        throw "Rendered template does not contain configured support email: $Path"
    }
    if (-not $Content.Contains('{{ .ConfirmationURL }}')) {
        throw "Rendered template must preserve Supabase {{ .ConfirmationURL }} variable: $Path"
    }
    if (-not $Content.Contains('{{ .SiteURL }}')) {
        throw "Rendered template must preserve Supabase {{ .SiteURL }} variable: $Path"
    }
}

Push-Location $repoRoot
try {
    Import-ReleaseEnvFile -Path $EnvFile

    if ([string]::IsNullOrWhiteSpace($SupportEmail)) {
        $SupportEmail = [Environment]::GetEnvironmentVariable('FLOWFIT_SUPPORT_EMAIL')
    }
    if ([string]::IsNullOrWhiteSpace($SupportEmail)) {
        throw 'SupportEmail or FLOWFIT_SUPPORT_EMAIL is required.'
    }

    $supportEmail = Assert-SupportEmail -Name 'SupportEmail' -Value $SupportEmail
    Assert-VerifiedSupportEmail

    $outRoot = Resolve-RepoOutputDirectory -Path $OutDir
    New-Item -ItemType Directory -Force -Path $outRoot | Out-Null

    $templates = @(
        [pscustomobject]@{
            source = 'supabase/email_templates/confirm_signup.html'
            output = 'confirm_signup.html'
            format = 'html'
        },
        [pscustomobject]@{
            source = 'supabase/email_templates/confirm_signup.txt'
            output = 'confirm_signup.txt'
            format = 'text'
        }
    )

    $outputs = @()
    foreach ($template in $templates) {
        $sourcePath = Join-Path $repoRoot $template.source
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            throw "Source template is missing: $($template.source)"
        }

        $sourceContent = [string](Get-Content -Raw -LiteralPath $sourcePath)
        if (-not $sourceContent.Contains($replacementToken)) {
            throw "Source template does not contain $replacementToken`: $($template.source)"
        }

        $rendered = $sourceContent.Replace($replacementToken, $supportEmail)
        $outputPath = Join-Path $outRoot $template.output
        Set-Content -LiteralPath $outputPath -Encoding utf8NoBOM -Value $rendered
        Assert-RenderedTemplate -Path $outputPath -Content $rendered -SupportEmail $supportEmail

        $item = Get-Item -LiteralPath $outputPath
        $outputs += [pscustomobject]@{
            source = $template.source
            output = Get-RepoRelativePath -Path $outputPath
            format = $template.format
            bytes = [int64]$item.Length
            sha256 = Get-FileSha256 -Path $outputPath
        }
    }

    $manifestPath = Join-Path $outRoot 'manifest.json'
    $manifest = [pscustomobject]@{
        generatedAt = (Get-Date).ToUniversalTime().ToString('o')
        supportEmail = $supportEmail
        outputDirectory = Get-RepoRelativePath -Path $outRoot
        templates = $outputs
        dashboardStep = 'Supabase Dashboard -> Authentication -> Email Templates -> Confirm signup'
    }
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding utf8NoBOM

    Write-Host "Rendered Supabase email templates: $(Get-RepoRelativePath -Path $outRoot)"
    Write-Host "Manifest: $(Get-RepoRelativePath -Path $manifestPath)"
    Write-Host 'SUPABASE_EMAIL_TEMPLATES_RENDERED'
} finally {
    Pop-Location
}
