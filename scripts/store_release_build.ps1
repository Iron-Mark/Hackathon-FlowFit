param(
    [ValidateSet('Android', 'iOS', 'Web', 'All')]
    [string]$Target = 'All',
    [switch]$RunStrictAudit,
    [switch]$SupportEmailVerified,
    [string]$EnvFile = '',
    [switch]$SkipFlutterPubGet,
    [switch]$SkipValidation,
    [switch]$WebWasm,
    [switch]$AllowDirty
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$artifactManifest = New-Object System.Collections.Generic.List[object]
$strictAuditRanThisInvocation = $false
$supabaseClientConfig = $null
$resolvedWebReleaseConfig = $null
$generatedAndroidSigningFiles = New-Object System.Collections.Generic.List[string]

function Invoke-OptionalCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Command,
        [int]$MaxLines = 20
    )

    try {
        $arguments = @()
        if ($Command.Length -gt 1) {
            $arguments = $Command[1..($Command.Length - 1)]
        }

        $output = & $Command[0] @arguments 2>&1
        return ($output | Select-Object -First $MaxLines) -join "`n"
    } catch {
        return ''
    }
}

function ConvertTo-RelativeArtifactPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
    $relativePath = [System.IO.Path]::GetRelativePath($repoRoot, $fullPath)
    return $relativePath.Replace('\', '/')
}

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

    if (-not (Test-Path $envPath)) {
        throw "Release env file does not exist: $envPath"
    }

    foreach ($line in Get-Content $envPath) {
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

function Get-DirectoryDigest {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
    $files = @(Get-ChildItem -Path $fullPath -Recurse -File | Sort-Object FullName)
    $totalBytes = [int64]0
    $digestInput = New-Object System.Text.StringBuilder

    foreach ($file in $files) {
        $totalBytes += $file.Length
        $relativePath = [System.IO.Path]::GetRelativePath($fullPath, $file.FullName).Replace('\', '/')
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

    return @{
        Sha256 = $digest
        SizeBytes = $totalBytes
        FileCount = $files.Count
    }
}

function New-ArtifactRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$Url = ''
    )

    if (-not (Test-Path $Path)) {
        throw "Artifact does not exist: $Path"
    }

    $item = Get-Item $Path
    $relativePath = ConvertTo-RelativeArtifactPath $Path
    if ($item.PSIsContainer) {
        $digest = Get-DirectoryDigest $Path
        return [pscustomobject]@{
            name = $Name
            kind = 'directory'
            path = $relativePath
            url = $Url
            sha256 = $digest.Sha256
            sizeBytes = $digest.SizeBytes
            fileCount = $digest.FileCount
        }
    }

    return [pscustomobject]@{
        name = $Name
        kind = 'file'
        path = $relativePath
        url = $Url
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $item.FullName).Hash.ToLowerInvariant()
        sizeBytes = $item.Length
        fileCount = 1
    }
}

function Get-GitEvidence {
    $status = Invoke-OptionalCommand @('git', 'status', '--porcelain') -MaxLines 500
    $statusLines = @()
    if (-not [string]::IsNullOrWhiteSpace($status)) {
        $statusLines = @($status -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

    return [pscustomobject]@{
        branch = Invoke-OptionalCommand @('git', 'branch', '--show-current') -MaxLines 1
        commit = Invoke-OptionalCommand @('git', 'rev-parse', 'HEAD') -MaxLines 1
        dirty = $statusLines.Count -gt 0
        changedFileCount = $statusLines.Count
        allowDirtyOverride = [bool]$AllowDirty
        uncommittedStatus = if ($AllowDirty) { @($statusLines) } else { @() }
    }
}

function Get-ToolchainEvidence {
    return [pscustomobject]@{
        flutter = Invoke-OptionalCommand @('flutter', '--version') -MaxLines 3
        dart = Invoke-OptionalCommand @('dart', '--version') -MaxLines 1
        java = Invoke-OptionalCommand @('java', '-version') -MaxLines 3
    }
}

function Get-ReleaseInputEvidence {
    $iosBundleId = ''
    $iosConfigPath = 'ios/Flutter/FlowFit.xcconfig'
    if (Test-Path $iosConfigPath) {
        $properties = Read-Properties $iosConfigPath
        if ($properties.ContainsKey('FLOWFIT_IOS_BUNDLE_IDENTIFIER')) {
            $iosBundleId = Resolve-XcconfigValue $properties['FLOWFIT_IOS_BUNDLE_IDENTIFIER'] $properties
        }
    }

    return [pscustomobject]@{
        supportEmail = [Environment]::GetEnvironmentVariable('FLOWFIT_SUPPORT_EMAIL')
        publicWebBaseUrl = [Environment]::GetEnvironmentVariable('FLOWFIT_PUBLIC_WEB_BASE_URL')
        supabaseUrl = if ($null -ne $script:supabaseClientConfig) { $script:supabaseClientConfig.Url } else { '' }
        supabaseConfigSource = if ($null -ne $script:supabaseClientConfig) { $script:supabaseClientConfig.Source } else { '' }
        androidApplicationId = [Environment]::GetEnvironmentVariable('ORG_GRADLE_PROJECT_FLOWFIT_ANDROID_APPLICATION_ID')
        androidAuthScheme = [Environment]::GetEnvironmentVariable('ORG_GRADLE_PROJECT_FLOWFIT_AUTH_SCHEME')
        iosBundleIdentifier = $iosBundleId
        webBuildBackend = if ($WebWasm) { 'wasm' } else { 'javascript' }
        webBaseHref = if ($null -ne $script:resolvedWebReleaseConfig) {
            $script:resolvedWebReleaseConfig.WebBaseHref
        } else {
            [Environment]::GetEnvironmentVariable('FLOWFIT_WEB_BASE_HREF')
        }
    }
}

function Get-StrictAuditEvidence {
    $path = 'build/store-release-readiness-audit.json'
    if (-not $script:strictAuditRanThisInvocation -or -not (Test-Path $path)) {
        return [pscustomobject]@{
            ran = $false
            path = ''
            summary = $null
        }
    }

    try {
        $audit = Get-Content -Raw $path | ConvertFrom-Json
        return [pscustomobject]@{
            ran = $true
            path = ConvertTo-RelativeArtifactPath $path
            generatedAt = $audit.generatedAt
            mode = $audit.mode
            supportEmailVerified = $audit.supportEmailVerified
            summary = $audit.summary
        }
    } catch {
        return [pscustomobject]@{
            ran = $true
            path = ConvertTo-RelativeArtifactPath $path
            summary = $null
        }
    }
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

function Get-GitPorcelainStatus {
    $output = & git status --porcelain 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to inspect git working tree before release build: $($output -join "`n")"
    }

    return @($output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Assert-CleanGitTree {
    $statusLines = Get-GitPorcelainStatus
    if ($statusLines.Count -eq 0) {
        return
    }

    if ($AllowDirty) {
        Write-Warning "Building store artifacts from a dirty working tree because -AllowDirty was provided."
        return
    }

    throw @"
Store release builds require a clean git working tree.
Commit or stash these changes, or rerun with -AllowDirty only for an explicitly documented emergency rebuild:
$($statusLines -join "`n")
"@
}

function Get-GradleExecutable {
    $wrapperName = if ($IsWindows) { 'gradlew.bat' } else { 'gradlew' }
    $wrapperPath = Join-Path (Join-Path $repoRoot 'android') $wrapperName

    if (-not (Test-Path $wrapperPath)) {
        throw "Android Gradle wrapper not found: $wrapperPath"
    }

    return $wrapperPath
}

function Remove-IgnoredGeneratedAndroidRegistrant {
    $generatedRegistrant = Join-Path $repoRoot 'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java'
    if (Test-Path $generatedRegistrant) {
        Remove-Item -LiteralPath $generatedRegistrant -Force
    }
}

function Invoke-ReleaseValidation {
    Invoke-CheckedCommand 'Dart analyzer machine output' @('dart', 'analyze', '--format=machine')
    Invoke-CheckedCommand 'Flutter analyzer' @('flutter', 'analyze')
    Invoke-CheckedCommand 'Flutter tests' @('flutter', 'test', '--reporter', 'compact')

    if ($Target -eq 'Android' -or $Target -eq 'All') {
        Remove-IgnoredGeneratedAndroidRegistrant
        Invoke-CheckedCommand 'Android release lint' @((Get-GradleExecutable), ':app:lintRelease')
    }
}

function Add-Artifact {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$Url = ''
    )

    $record = New-ArtifactRecord -Name $Name -Path $Path -Url $Url
    $artifactManifest.Add($record)
}

function New-WebReleaseArchive {
    $releaseDirectory = 'build/release'
    if (-not (Test-Path $releaseDirectory)) {
        New-Item -ItemType Directory -Path $releaseDirectory | Out-Null
    }

    $archivePath = Join-Path $releaseDirectory 'flowfit-web-release.zip'
    if (Test-Path $archivePath) {
        Remove-Item -LiteralPath $archivePath -Force
    }

    Compress-Archive -Path 'build/web/*' -DestinationPath $archivePath -CompressionLevel Optimal
    return $archivePath
}

function Get-RequiredEnv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Purpose
    )

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "$Name is required for $Purpose."
    }

    return $value.Trim()
}

function Get-OptionalEnv {
    param([Parameter(Mandatory = $true)][string]$Name)

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        return ''
    }

    return $value.Trim()
}

function Assert-ProductionValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    if (
        [string]::IsNullOrWhiteSpace($Value) -or
        $Value -match 'YOUR_|REPLACE_WITH|<your-|your[-_]|com\.example\.|com\.yourcompany\.|(^|[./-])smoke($|[./-])|(^|[./:-])(example|invalid|test|localhost)(\.|/|:|$)|127\.0\.0\.1|\$\([^)]+\)'
    ) {
        throw "$Name is still placeholder/test/reserved-shaped: $Value"
    }
}

function Resolve-WebBaseHref {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $baseHref = $Value.Trim()
    if ($baseHref -notmatch '^/.*/$') {
        throw 'FLOWFIT_WEB_BASE_HREF must start and end with "/", for example /Hackathon-FlowFit/.'
    }
    if ($baseHref.Contains('//')) {
        throw 'FLOWFIT_WEB_BASE_HREF must not contain duplicate slashes.'
    }

    return $baseHref
}

function Resolve-PublicWebBaseUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PublicWebBaseUrl
    )

    Assert-ProductionValue 'FLOWFIT_PUBLIC_WEB_BASE_URL' $PublicWebBaseUrl

    $uri = $null
    if (-not [System.Uri]::TryCreate($PublicWebBaseUrl.Trim().TrimEnd('/'), [System.UriKind]::Absolute, [ref]$uri)) {
        throw 'FLOWFIT_PUBLIC_WEB_BASE_URL must be an absolute HTTPS URL, for example https://iron-mark.github.io/Hackathon-FlowFit.'
    }
    if ($uri.Scheme -ne 'https') {
        throw 'FLOWFIT_PUBLIC_WEB_BASE_URL must use HTTPS.'
    }
    if (-not [string]::IsNullOrWhiteSpace($uri.Query) -or -not [string]::IsNullOrWhiteSpace($uri.Fragment)) {
        throw 'FLOWFIT_PUBLIC_WEB_BASE_URL must not include query strings or fragments.'
    }

    $normalizedUrl = $uri.GetLeftPart([System.UriPartial]::Authority).TrimEnd('/')
    $basePath = $uri.AbsolutePath
    if (-not [string]::IsNullOrWhiteSpace($basePath) -and $basePath -ne '/') {
        $normalizedUrl += $basePath.TrimEnd('/')
    }

    return $normalizedUrl
}

function Resolve-WebReleaseConfig {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PublicWebBaseUrl
    )

    $normalizedUrl = Resolve-PublicWebBaseUrl -PublicWebBaseUrl $PublicWebBaseUrl
    $uri = [System.Uri]$normalizedUrl

    $basePath = $uri.AbsolutePath
    if ([string]::IsNullOrWhiteSpace($basePath)) {
        $basePath = '/'
    }
    if (-not $basePath.EndsWith('/')) {
        $basePath = "$basePath/"
    }

    $baseHrefOverride = [Environment]::GetEnvironmentVariable('FLOWFIT_WEB_BASE_HREF')
    $webBaseHref = if ([string]::IsNullOrWhiteSpace($baseHrefOverride)) {
        Resolve-WebBaseHref -Value $basePath
    } else {
        Resolve-WebBaseHref -Value $baseHrefOverride
    }

    return [pscustomobject]@{
        PublicWebBaseUrl = $normalizedUrl
        WebBaseHref = $webBaseHref
    }
}

function Assert-SupabasePublishableKey {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $normalized = $Value.Trim()
    $lower = $normalized.ToLowerInvariant()
    if (
        [string]::IsNullOrWhiteSpace($normalized) -or
        $lower -match '\.\.\.|your_|replace_with|<your-|your-|project_ref|placeholder|dnasghxxqwibwqnljvxr|sb_secret_|service_role|\s' -or
        $lower -match '(^|[_-])(example|smoke|test)($|[_-])' -or
        $normalized -notmatch '^sb_publishable_[A-Za-z0-9_-]{20,}$'
    ) {
        throw "$Source must provide a real Supabase publishable client key in sb_publishable_ format."
    }
}

function Assert-Email {
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

function Assert-SupabaseClientValues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [Parameter(Mandatory = $true)]
        [string]$PublishableKey
    )

    if ($Url -match 'YOUR_|REPLACE_WITH|<your-|project_ref|placeholder|dnasghxxqwibwqnljvxr|(^|[./:-])(example|invalid|test|localhost)(\.|/|:|$)|127\.0\.0\.1') {
        throw "$Source Supabase URL still contains placeholder or old project values."
    }
    if ($Url -notmatch '^https://[a-z0-9-]+\.supabase\.co$') {
        throw "$Source must provide a valid Supabase Project URL."
    }
    Assert-SupabasePublishableKey -Source "$Source Supabase publishable key" -Value $PublishableKey
}

function Assert-SupabaseClientConfig {
    $envUrl = [Environment]::GetEnvironmentVariable('SUPABASE_URL')
    $envKey = [Environment]::GetEnvironmentVariable('SUPABASE_PUBLISHABLE_KEY')
    $hasEnvUrl = -not [string]::IsNullOrWhiteSpace($envUrl)
    $hasEnvKey = -not [string]::IsNullOrWhiteSpace($envKey)

    if ($hasEnvUrl -xor $hasEnvKey) {
        throw 'Provide both SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY, or provide neither and use the local fallback file.'
    }

    if ($hasEnvUrl -and $hasEnvKey) {
        $envUrl = $envUrl.Trim()
        $envKey = $envKey.Trim()
        Assert-SupabaseClientValues -Source 'environment' -Url $envUrl -PublishableKey $envKey
        $script:supabaseClientConfig = [pscustomobject]@{
            Source = 'environment'
            Url = $envUrl
            PublishableKey = $envKey
        }
        return
    }

    $secretsPath = Join-Path $repoRoot 'lib/secrets.dart'
    if (-not (Test-Path $secretsPath)) {
        throw 'Store builds require SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY, or a local fallback lib/secrets.dart.'
    }

    $secrets = Get-Content -Raw $secretsPath
    if ($secrets -match 'sb_secret_|service_role') {
        throw 'lib/secrets.dart contains a secret/service-role credential. Use only a publishable client key.'
    }
    if ($secrets -match 'YOUR_|REPLACE_WITH|<your-|dnasghxxqwibwqnljvxr') {
        throw 'lib/secrets.dart still contains placeholder or old Supabase project values.'
    }

    $urlMatch = [regex]::Match($secrets, "url\s*=\s*'([^']+)'")
    if (-not $urlMatch.Success -or $urlMatch.Groups[1].Value -notmatch '^https://[a-z0-9-]+\.supabase\.co$') {
        throw 'lib/secrets.dart must define a valid Supabase Project URL.'
    }

    $keyMatch = [regex]::Match($secrets, "publishableKey\s*=\s*'([^']+)'")
    if (-not $keyMatch.Success) {
        throw 'lib/secrets.dart must define SupabaseConfig.publishableKey.'
    }

    $publishableKey = $keyMatch.Groups[1].Value

    Assert-SupabaseClientValues -Source 'lib/secrets.dart' -Url $urlMatch.Groups[1].Value -PublishableKey $publishableKey
    $script:supabaseClientConfig = [pscustomobject]@{
        Source = 'lib/secrets.dart'
        Url = $urlMatch.Groups[1].Value
        PublishableKey = $publishableKey
    }
}

function Read-Properties {
    param([string]$Path)

    $properties = @{}
    if (-not (Test-Path $Path)) {
        return $properties
    }

    foreach ($line in Get-Content $Path) {
        if ($line -match '^\s*$' -or $line -match '^\s*#') {
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

function Assert-MacOsBuildHost {
    $runningOnMacOS = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [System.Runtime.InteropServices.OSPlatform]::OSX
    )

    if (-not $runningOnMacOS) {
        throw 'iOS App Store IPA builds require macOS with Xcode. Run -Target iOS or -Target All on macOS, or use -Target Android/-Target Web on this machine.'
    }

    foreach ($tool in @('xcodebuild', 'flutter')) {
        if ($null -eq (Get-Command $tool -ErrorAction SilentlyContinue)) {
            throw "$tool is required for iOS App Store builds."
        }
    }
}

function Assert-AndroidSigning {
    $keyPropertiesPath = Join-Path $repoRoot 'android/key.properties'
    if (-not (Test-Path $keyPropertiesPath)) {
        throw 'Missing android/key.properties. Copy android/key.properties.example and configure the upload keystore first.'
    }

    $properties = Read-Properties $keyPropertiesPath
    foreach ($field in @('storeFile', 'storePassword', 'keyAlias', 'keyPassword')) {
        if (-not $properties.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($properties[$field])) {
            throw "android/key.properties is missing $field."
        }
        if ($field -ne 'storeFile' -and $properties[$field] -match 'YOUR_|REPLACE_WITH') {
            throw "android/key.properties contains a placeholder $field."
        }
    }

    $storeFile = Join-Path (Join-Path $repoRoot 'android') $properties['storeFile']
    if (-not (Test-Path $storeFile)) {
        throw "Android upload keystore not found: $storeFile"
    }
}

function Initialize-AndroidSigningFromEnv {
    $keyPropertiesPath = Join-Path $repoRoot 'android/key.properties'
    if (Test-Path $keyPropertiesPath) {
        return
    }

    $keystoreBase64 = Get-OptionalEnv 'FLOWFIT_ANDROID_KEYSTORE_BASE64'
    $storePassword = Get-OptionalEnv 'FLOWFIT_ANDROID_KEYSTORE_PASSWORD'
    $keyAlias = Get-OptionalEnv 'FLOWFIT_ANDROID_KEY_ALIAS'
    $keyPassword = Get-OptionalEnv 'FLOWFIT_ANDROID_KEY_PASSWORD'
    $provided = @($keystoreBase64, $storePassword, $keyAlias, $keyPassword) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    if ($provided.Count -eq 0) {
        return
    }

    if ($provided.Count -ne 4) {
        throw 'Android signing env is incomplete. Set FLOWFIT_ANDROID_KEYSTORE_BASE64, FLOWFIT_ANDROID_KEYSTORE_PASSWORD, FLOWFIT_ANDROID_KEY_ALIAS, and FLOWFIT_ANDROID_KEY_PASSWORD together.'
    }

    foreach ($entry in @{
        FLOWFIT_ANDROID_KEYSTORE_PASSWORD = $storePassword
        FLOWFIT_ANDROID_KEY_ALIAS = $keyAlias
        FLOWFIT_ANDROID_KEY_PASSWORD = $keyPassword
    }.GetEnumerator()) {
        if ($entry.Value -match 'YOUR_|REPLACE_WITH') {
            throw "$($entry.Key) contains a placeholder value."
        }
        if ($entry.Value -match "[\r\n]") {
            throw "$($entry.Key) must be a single-line value."
        }
    }

    $storeFileName = Get-OptionalEnv 'FLOWFIT_ANDROID_KEYSTORE_FILE_NAME'
    if ([string]::IsNullOrWhiteSpace($storeFileName)) {
        $storeFileName = 'upload-keystore.jks'
    }
    if (
        $storeFileName -match '[\\/]' -or
        $storeFileName -match '^\.' -or
        $storeFileName -notmatch '\.(jks|keystore)$'
    ) {
        throw 'FLOWFIT_ANDROID_KEYSTORE_FILE_NAME must be a simple .jks or .keystore file name.'
    }

    try {
        $keystoreBytes = [Convert]::FromBase64String($keystoreBase64)
    } catch {
        throw 'FLOWFIT_ANDROID_KEYSTORE_BASE64 is not valid base64.'
    }

    $androidDir = Join-Path $repoRoot 'android'
    $storeFilePath = Join-Path $androidDir $storeFileName
    if (Test-Path -LiteralPath $storeFilePath) {
        throw "Refusing to overwrite existing Android upload keystore: $storeFilePath. Remove it or set FLOWFIT_ANDROID_KEYSTORE_FILE_NAME to an unused file name."
    }

    [System.IO.File]::WriteAllBytes($storeFilePath, $keystoreBytes)
    $script:generatedAndroidSigningFiles.Add($storeFilePath)

    $propertiesContent = @(
        "storePassword=$storePassword"
        "keyPassword=$keyPassword"
        "keyAlias=$keyAlias"
        "storeFile=$storeFileName"
    ) -join [Environment]::NewLine
    Set-Content -LiteralPath $keyPropertiesPath -Value $propertiesContent -NoNewline
    $script:generatedAndroidSigningFiles.Add($keyPropertiesPath)
}

function Remove-GeneratedAndroidSigningFiles {
    foreach ($path in @($script:generatedAndroidSigningFiles.ToArray())) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)) {
            Remove-Item -LiteralPath $path -Force
        }
    }
}

function Assert-WebCompliancePages {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SupportEmail,
        [Parameter(Mandatory = $true)]
        [string]$PublicWebBaseUrl
    )

    $pages = @(
        @{
            Path = 'build/web/privacy.html'
            Title = '<title>FlowFit Privacy Policy</title>'
            Link = 'account-deletion.html'
            Url = "$PublicWebBaseUrl/privacy.html"
            RequiredTerms = @(
                $SupportEmail,
                'account and associated app data',
                'Profile &gt; Settings &gt; Delete Account'
            )
        },
        @{
            Path = 'build/web/account-deletion.html'
            Title = '<title>FlowFit Account Deletion</title>'
            Link = 'privacy.html'
            Url = "$PublicWebBaseUrl/account-deletion.html"
            RequiredTerms = @(
                "mailto:$SupportEmail",
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
        $content = $content.Replace('support@flowfit.com', $SupportEmail)
        Set-Content -Path $page.Path -Value $content -NoNewline

        $content = Get-Content -Raw $page.Path
        if (-not $content.Contains($page.Title)) {
            throw "Missing expected title in $($page.Path): $($page.Title)"
        }
        if (-not $content.Contains($page.Link)) {
            throw "Missing expected cross-link in $($page.Path): $($page.Link)"
        }
        if (-not $content.Contains($SupportEmail)) {
            throw "Public web page $($page.Path) does not include configured support email."
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

        Add-Artifact -Name ([System.IO.Path]::GetFileName($page.Path)) -Path $page.Path -Url $page.Url
    }
}

function Invoke-AndroidReleaseBuild {
    $applicationId = Get-RequiredEnv 'ORG_GRADLE_PROJECT_FLOWFIT_ANDROID_APPLICATION_ID' 'Android Play Store package ID'
    $authScheme = Get-RequiredEnv 'ORG_GRADLE_PROJECT_FLOWFIT_AUTH_SCHEME' 'Android Supabase auth redirect scheme'
    $supportEmail = Get-RequiredEnv 'FLOWFIT_SUPPORT_EMAIL' 'in-app support and privacy contact'
    $publicWebBaseUrl = Get-RequiredEnv 'FLOWFIT_PUBLIC_WEB_BASE_URL' 'in-app website and public compliance URL'

    Assert-ProductionValue 'ORG_GRADLE_PROJECT_FLOWFIT_ANDROID_APPLICATION_ID' $applicationId
    Assert-ProductionValue 'ORG_GRADLE_PROJECT_FLOWFIT_AUTH_SCHEME' $authScheme
    Assert-Email 'FLOWFIT_SUPPORT_EMAIL' $supportEmail
    $publicWebBaseUrl = Resolve-PublicWebBaseUrl -PublicWebBaseUrl $publicWebBaseUrl
    Assert-AndroidSigning

    Remove-IgnoredGeneratedAndroidRegistrant
    Invoke-CheckedCommand 'Android Play Store App Bundle' @(
        'flutter',
        'build',
        'appbundle',
        '--release',
        '--no-pub',
        "--dart-define=FLOWFIT_AUTH_SCHEME=$authScheme",
        "--dart-define=FLOWFIT_SUPPORT_EMAIL=$supportEmail",
        "--dart-define=FLOWFIT_PUBLIC_WEB_BASE_URL=$publicWebBaseUrl",
        "--dart-define=SUPABASE_URL=$($script:supabaseClientConfig.Url)",
        "--dart-define=SUPABASE_PUBLISHABLE_KEY=$($script:supabaseClientConfig.PublishableKey)"
    )

    $artifactPath = 'build/app/outputs/bundle/release/app-release.aab'
    if (-not (Test-Path $artifactPath)) {
        throw "Expected Android App Bundle was not produced: $artifactPath"
    }

    Add-Artifact -Name 'android-play-store-aab' -Path $artifactPath
}

function Invoke-IosReleaseBuild {
    Assert-MacOsBuildHost

    $supportEmail = Get-RequiredEnv 'FLOWFIT_SUPPORT_EMAIL' 'App Store support and privacy contact'
    $publicWebBaseUrl = Get-RequiredEnv 'FLOWFIT_PUBLIC_WEB_BASE_URL' 'in-app website and public compliance URL'
    Assert-Email 'FLOWFIT_SUPPORT_EMAIL' $supportEmail
    $publicWebBaseUrl = Resolve-PublicWebBaseUrl -PublicWebBaseUrl $publicWebBaseUrl

    $iosConfigPath = 'ios/Flutter/FlowFit.xcconfig'
    if (-not (Test-Path $iosConfigPath)) {
        throw 'Missing ios/Flutter/FlowFit.xcconfig.'
    }

    $properties = Read-Properties $iosConfigPath
    foreach ($field in @('FLOWFIT_IOS_BUNDLE_IDENTIFIER')) {
        if (-not $properties.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($properties[$field])) {
            throw "$iosConfigPath is missing $field."
        }
    }

    $bundleId = Resolve-XcconfigValue $properties['FLOWFIT_IOS_BUNDLE_IDENTIFIER'] $properties

    Assert-ProductionValue 'FLOWFIT_IOS_BUNDLE_IDENTIFIER' $bundleId

    $command = @(
        'flutter',
        'build',
        'ipa',
        '--release',
        '--no-pub',
        "--dart-define=FLOWFIT_AUTH_SCHEME=$bundleId",
        "--dart-define=FLOWFIT_SUPPORT_EMAIL=$supportEmail",
        "--dart-define=FLOWFIT_PUBLIC_WEB_BASE_URL=$publicWebBaseUrl",
        "--dart-define=SUPABASE_URL=$($script:supabaseClientConfig.Url)",
        "--dart-define=SUPABASE_PUBLISHABLE_KEY=$($script:supabaseClientConfig.PublishableKey)"
    )

    $exportOptionsPlist = [Environment]::GetEnvironmentVariable('FLOWFIT_IOS_EXPORT_OPTIONS_PLIST')
    if (-not [string]::IsNullOrWhiteSpace($exportOptionsPlist)) {
        $exportOptionsPlist = $exportOptionsPlist.Trim()
        if (-not (Test-Path $exportOptionsPlist)) {
            throw "FLOWFIT_IOS_EXPORT_OPTIONS_PLIST does not exist: $exportOptionsPlist"
        }
        $command += "--export-options-plist=$exportOptionsPlist"
    }

    Invoke-CheckedCommand 'iOS App Store IPA' $command

    $ipaDirectory = 'build/ios/ipa'
    if (-not (Test-Path $ipaDirectory)) {
        throw "Expected iOS IPA output directory was not produced: $ipaDirectory"
    }

    $ipa = Get-ChildItem -Path $ipaDirectory -Filter '*.ipa' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($null -eq $ipa) {
        throw "Expected iOS IPA was not produced under $ipaDirectory."
    }

    Add-Artifact -Name 'ios-app-store-ipa' -Path (Join-Path $ipaDirectory $ipa.Name)

    $archivePath = 'build/ios/archive/Runner.xcarchive'
    if (Test-Path $archivePath) {
        Add-Artifact -Name 'ios-xcode-archive' -Path $archivePath
    }
}

function Invoke-WebReleaseBuild {
    $supportEmail = Get-RequiredEnv 'FLOWFIT_SUPPORT_EMAIL' 'public web support and privacy contact'
    $publicWebBaseUrl = Get-RequiredEnv 'FLOWFIT_PUBLIC_WEB_BASE_URL' 'public privacy/account-deletion URLs'

    Assert-Email 'FLOWFIT_SUPPORT_EMAIL' $supportEmail
    $script:resolvedWebReleaseConfig = Resolve-WebReleaseConfig -PublicWebBaseUrl $publicWebBaseUrl
    $publicWebBaseUrl = $script:resolvedWebReleaseConfig.PublicWebBaseUrl
    $webBaseHref = $script:resolvedWebReleaseConfig.WebBaseHref

    $webBuildBackend = if ($WebWasm) { 'Wasm' } else { 'JavaScript' }
    $webBuildCommand = @(
        'flutter',
        'build',
        'web',
        '--release'
    )
    if ($WebWasm) {
        $webBuildCommand += '--wasm'
    }
    $webBuildCommand += @(
        '--no-pub',
        "--base-href=$webBaseHref",
        "--dart-define=FLOWFIT_SUPPORT_EMAIL=$supportEmail",
        "--dart-define=FLOWFIT_PUBLIC_WEB_BASE_URL=$publicWebBaseUrl",
        "--dart-define=SUPABASE_URL=$($script:supabaseClientConfig.Url)",
        "--dart-define=SUPABASE_PUBLISHABLE_KEY=$($script:supabaseClientConfig.PublishableKey)"
    )

    Invoke-CheckedCommand "Flutter web $webBuildBackend release build" $webBuildCommand
    Assert-WebCompliancePages -SupportEmail $supportEmail -PublicWebBaseUrl $publicWebBaseUrl
    Add-Artifact -Name 'flutter-web-build' -Path 'build/web' -Url $publicWebBaseUrl
    $webArchivePath = New-WebReleaseArchive
    Add-Artifact -Name 'flutter-web-release-zip' -Path $webArchivePath -Url $publicWebBaseUrl
}

Push-Location $repoRoot
try {
    Import-ReleaseEnvFile -Path $EnvFile

    Assert-CleanGitTree
    Assert-SupabaseClientConfig
    if ($Target -eq 'Android' -or $Target -eq 'All' -or $RunStrictAudit) {
        Initialize-AndroidSigningFromEnv
    }

    if ($RunStrictAudit) {
        $strictAuditScript = Join-Path $repoRoot 'scripts/release_readiness_audit.ps1'
        $strictAuditCommand = @(
            'pwsh',
            '-NoProfile',
            '-File',
            $strictAuditScript,
            '-Strict',
            '-OutFile',
            'build/store-release-readiness-audit.json'
        )
        if ($SupportEmailVerified) {
            $strictAuditCommand += '-SupportEmailVerified'
        }

        Invoke-CheckedCommand 'Strict release readiness audit' $strictAuditCommand
        $script:strictAuditRanThisInvocation = $true
        Add-Artifact -Name 'store-release-readiness-audit' -Path 'build/store-release-readiness-audit.json'
    }

    if (-not $SkipFlutterPubGet) {
        Invoke-CheckedCommand 'Flutter dependencies' @('flutter', 'pub', 'get')
    }

    if (-not $SkipValidation) {
        Invoke-ReleaseValidation
    }

    if ($Target -eq 'Android' -or $Target -eq 'All') {
        Invoke-AndroidReleaseBuild
    }

    if ($Target -eq 'iOS' -or $Target -eq 'All') {
        Invoke-IosReleaseBuild
    }

    if ($Target -eq 'Web' -or $Target -eq 'All') {
        Invoke-WebReleaseBuild
    }

    $manifestPath = 'build/store-release-artifacts.json'
    $manifest = [pscustomobject]@{
        generatedAt = (Get-Date).ToUniversalTime().ToString('o')
        target = $Target
        strictAudit = Get-StrictAuditEvidence
        git = Get-GitEvidence
        toolchain = Get-ToolchainEvidence
        releaseInputs = Get-ReleaseInputEvidence
        artifacts = @($artifactManifest.ToArray())
    }
    $manifest | ConvertTo-Json -Depth 5 | Set-Content -Path $manifestPath
    Write-Host ""
    Write-Host "Store release build finished. Artifact manifest: $manifestPath"
}
finally {
    Remove-GeneratedAndroidSigningFiles
    Pop-Location
}
