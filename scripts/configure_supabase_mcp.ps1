param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRef,
    [string]$McpConfigPath = '.mcp.json',
    [switch]$ReleaseReadOnly,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$requiredFeatures = 'database,docs,debugging,development'
$placeholderProjectRef = 'REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF'
$retiredProjectRef = 'dnasghxxqwibwqnljvxr'
# Expected recovery URL shape: https://mcp.supabase.com/mcp?project_ref=REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF&features=database,docs,debugging,development

function Assert-SupabaseProjectRef {
    param([Parameter(Mandatory = $true)][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw 'Supabase project ref is required.'
    }

    $normalized = $Value.Trim()
    $lower = $normalized.ToLowerInvariant()
    if ($normalized -ne $Value) {
        throw 'Supabase project ref must not contain leading or trailing whitespace.'
    }

    if (
        $lower -match 'https?://|\.supabase\.co|[/?#]' -or
        $lower -match 'your_|replace_with|placeholder|project_ref' -or
        $normalized -eq $placeholderProjectRef -or
        $lower -eq $retiredProjectRef -or
        $lower -match 'sb_secret_|service_role'
    ) {
        throw 'Supabase project ref must be the new project_ref only, not a URL, key, placeholder, or retired FlowFit project.'
    }

    if ($normalized -notmatch '^[a-z0-9]{20}$') {
        throw 'Supabase project ref must be the 20-character lowercase Supabase project_ref.'
    }

    return $normalized
}

function Resolve-McpConfigPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'McpConfigPath is required.'
    }

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    return Join-Path $repoRoot $Path
}

$projectRefValue = Assert-SupabaseProjectRef -Value $ProjectRef
$mcpUrl = "https://mcp.supabase.com/mcp?project_ref=$projectRefValue&features=$requiredFeatures"
if ($ReleaseReadOnly) {
    $mcpUrl = "$mcpUrl&read_only=true"
}

$config = [ordered]@{
    mcpServers = [ordered]@{
        supabase = [ordered]@{
            type = 'http'
            url = $mcpUrl
        }
    }
}

$json = $config | ConvertTo-Json -Depth 5

if ($DryRun) {
    Write-Host $json
    Write-Host "Supabase MCP URL: $mcpUrl"
    Write-Host 'Reload Codex after writing .mcp.json, then complete the Supabase MCP OAuth flow when prompted.'
    Write-Host 'SUPABASE_MCP_CONFIG_DRY_RUN_OK'
    return
}

$outputPath = Resolve-McpConfigPath -Path $McpConfigPath
$outputDirectory = Split-Path -Parent $outputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory) -and -not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

Set-Content -LiteralPath $outputPath -Value $json

Write-Host "Wrote Supabase MCP config: $outputPath"
Write-Host "Supabase MCP URL: $mcpUrl"
if ($ReleaseReadOnly) {
    Write-Host 'Release verification posture enabled with read_only=true.'
} else {
    Write-Host 'Recovery posture enabled: MCP remains write-capable for migrations and advisors.'
}
Write-Host 'Reload Codex after writing .mcp.json, then complete the Supabase MCP OAuth flow when prompted.'
Write-Host 'SUPABASE_MCP_CONFIG_WRITTEN_OK'
