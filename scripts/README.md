# FlowFit Build Scripts

Automated scripts for building and running FlowFit on different devices.

## 📜 Available Scripts

### 1. build_and_install.bat
**Purpose**: Automated build and installation on Galaxy Watch

**Usage**:
```bash
scripts\build_and_install.bat
```

**What it does**:
1. Cleans previous builds (`flutter clean`)
2. Gets dependencies (`flutter pub get`)
3. Builds debug APK (`flutter build apk --debug`)
4. Checks connected devices (`adb devices`)
5. Installs on watch (`adb -s 6ece264d install`)

**Requirements**:
- Watch connected and visible in `adb devices`
- Developer mode enabled on watch
- ADB debugging enabled on watch

**Important**: You must approve the installation on your watch screen when prompted!

---

### 2. run_watch.bat
**Purpose**: Quick run on Galaxy Watch

**Usage**:
```bash
scripts\run_watch.bat
```

**What it does**:
- Runs `flutter run -d 6ece264d`
- Launches app on watch in debug mode
- Enables hot reload

**Requirements**:
- Watch connected
- Previous build successful

---

### 3. run_phone.bat
**Purpose**: Quick run on Android Phone

**Usage**:
```bash
scripts\run_phone.bat
```

**What it does**:
- Runs `flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp`
- Launches companion app on phone
- Enables hot reload

**Requirements**:
- Phone connected
- Previous build successful

---

### 4. release_preflight.ps1
**Purpose**: Repeatable local release-readiness gate for analyzer, tests, web,
public privacy/account-deletion pages, release source safety, Android phone,
Wear OS, and optional release App Bundle smoke checks.

**Usage**:
```powershell
pwsh -NoProfile -File scripts/release_preflight.ps1
```

**Optional release smoke build**:
```powershell
pwsh -NoProfile -File scripts/release_preflight.ps1 -IncludeReleaseSmoke
```

**Optional Flutter web Wasm compile-smoke build**:
```powershell
pwsh -NoProfile -File scripts/release_preflight.ps1 -IncludeWasmSmoke
```

The release smoke build sets Gradle property
`FLOWFIT_ALLOW_DEBUG_RELEASE_SIGNING=true` through env var
`ORG_GRADLE_PROJECT_FLOWFIT_ALLOW_DEBUG_RELEASE_SIGNING=true` temporarily.
If production values are not already set, it also uses
`com.flowfit.smoke` package/auth defaults and matching Dart auth-scheme defines.
It also passes `FLOWFIT_SUPPORT_EMAIL`, defaulting to `support@flowfit.com`
when the environment does not override it. It passes placeholder Supabase
client values as Dart defines only for compile smoke coverage. Its App Bundle
proves release compilation, but it is not a Play Store upload artifact. Real
Play Store builds require either ignored `android/key.properties` plus the
referenced upload keystore, or wrapper-managed signing env secrets
(`FLOWFIT_ANDROID_KEYSTORE_BASE64`, `FLOWFIT_ANDROID_KEYSTORE_PASSWORD`,
`FLOWFIT_ANDROID_KEY_ALIAS`, and `FLOWFIT_ANDROID_KEY_PASSWORD`). They also
require a maintainer-owned package ID, real Supabase client env, and matching
Dart auth-scheme/support-email defines.
The strict audit and production wrapper reject `com.flowfit.smoke`,
`com.example.*`, `com.yourcompany.*`, reserved `.example`, `.invalid`, `.test`,
and localhost web hosts.

The app now compiles from tracked build-time defaults in
`lib/core/config/supabase_runtime_config.dart`, so preflight does not create a
temporary `lib/secrets.dart`.

`-IncludeWasmSmoke` runs a separate `flutter build web --wasm` after the normal
JavaScript web build. JS remains the default web handoff target; use the Wasm
smoke when the release needs explicit Flutter WebAssembly compile evidence.

After the Flutter web build, the script also verifies that
`build/web/privacy.html` and `build/web/account-deletion.html` exist, link to
each other, have the expected titles, and do not contain internal maintainer or
store-review wording.

Before analyzer/build checks, it also fails if release source reintroduces the
hard-coded example mobile auth redirect or a public privileged deletion RPC.

---

### 5. release_readiness_audit.ps1
**Purpose**: Non-secret readiness audit for Supabase recovery, MCP setup,
Android signing/package IDs, iOS bundle/auth schemes, public web compliance
URLs, support inbox verification, and local tooling gaps.

**Advisory usage**:
```powershell
pwsh -NoProfile -File scripts/release_readiness_audit.ps1
```

Advisory mode exits successfully when unresolved items are external setup gaps.
Use it during normal development and before running `release_preflight.ps1`.

**Strict pre-release usage**:
```powershell
pwsh -NoProfile -File scripts/release_readiness_audit.ps1 -Strict
```

Strict mode turns unresolved store/Supabase configuration gaps into failures.
Set `FLOWFIT_PUBLIC_WEB_BASE_URL` to the deployed HTTPS origin and
`FLOWFIT_SUPPORT_EMAIL_VERIFIED=true` only after the configured
`FLOWFIT_SUPPORT_EMAIL` value, or the default `support@flowfit.com`, is the
final support/privacy inbox. Advisory mode defaults to recovery MCP posture,
where the project-scoped Supabase MCP remains write-capable for migrations.
Strict mode defaults to release MCP posture and expects `read_only=true` after
migrations and advisors are complete. The script never prints Supabase keys or
signing passwords.

Use `-McpMode Recovery` to force the write-capable migration posture, or
`-McpMode Release` to force the read-only verification posture. The default
`-McpMode Auto` chooses `Recovery` for advisory runs and `Release` for
`-Strict` runs.

Write a JSON evidence artifact for release handoff:
```powershell
pwsh -NoProfile -File scripts/release_readiness_audit.ps1 -Strict -SupportEmailVerified -OutFile build/store-release-readiness-audit.json
```

When the release web values live in GitHub repository variables, audit them
directly without copying values into local files:
```powershell
pwsh -NoProfile -File scripts/release_readiness_audit.ps1 `
  -Strict `
  -GitHubRepo Iron-Mark/Hackathon-FlowFit `
  -OutFile build/store-release-readiness-audit.json
```

The GitHub-variable import is allowlisted to release client/config values:
`FLOWFIT_PUBLIC_WEB_BASE_URL`, `FLOWFIT_WEB_BASE_HREF`,
`FLOWFIT_SUPPORT_EMAIL`, `FLOWFIT_SUPPORT_EMAIL_VERIFIED`, `SUPABASE_URL`, and
`SUPABASE_PUBLISHABLE_KEY`. The audit reports how many values were imported but
does not print Supabase keys.

---

### 6. configure_supabase_mcp.ps1
**Purpose**: Validate and write project-scoped Supabase MCP config without
storing tokens, service-role keys, or database passwords in the repo.

**Recovery write-capable config**:
```powershell
pwsh -NoProfile -File scripts/configure_supabase_mcp.ps1 `
  -ProjectRef '<new-flowfit-dev-ref>'
```

**Dry run without writing `.mcp.json`**:
```powershell
pwsh -NoProfile -File scripts/configure_supabase_mcp.ps1 `
  -ProjectRef '<new-flowfit-dev-ref>' `
  -DryRun
```

**Release read-only config after migrations and advisors**:
```powershell
pwsh -NoProfile -File scripts/configure_supabase_mcp.ps1 `
  -ProjectRef '<new-flowfit-dev-ref>' `
  -ReleaseReadOnly
```

The helper writes
`https://mcp.supabase.com/mcp?project_ref=<ref>&features=database,docs,debugging,development`
and appends `read_only=true` only when `-ReleaseReadOnly` is passed. After
writing `.mcp.json`, reload Codex and complete the Supabase MCP OAuth flow when
prompted.

---

### 7. configure_github_release_variables.ps1
**Purpose**: Validate and set GitHub repository variables used by strict audit
and the GitHub Pages deployment workflow after the maintainer has real Supabase
client values and a verified support inbox.

**Dry run from the current environment**:
```powershell
pwsh -NoProfile -File scripts/configure_github_release_variables.ps1 `
  -Repo Iron-Mark/Hackathon-FlowFit `
  -DryRun
```

**Dry run from ignored release env file**:
```powershell
pwsh -NoProfile -File scripts/configure_github_release_variables.ps1 `
  -Repo Iron-Mark/Hackathon-FlowFit `
  -EnvFile .env.release `
  -DryRun
```

**Set variables after support inbox verification**:
```powershell
pwsh -NoProfile -File scripts/configure_github_release_variables.ps1 `
  -Repo Iron-Mark/Hackathon-FlowFit `
  -EnvFile .env.release `
  -SupportEmailVerified
```

The helper validates `FLOWFIT_PUBLIC_WEB_BASE_URL`, optional
`FLOWFIT_WEB_BASE_HREF`, `FLOWFIT_SUPPORT_EMAIL`,
`FLOWFIT_SUPPORT_EMAIL_VERIFIED`, `SUPABASE_URL`, and
`SUPABASE_PUBLISHABLE_KEY`, rejects placeholders, reserved/test-shaped values,
secret/service-role Supabase keys, and the retired project ref, then calls
`gh variable set`. It redacts the publishable key in all output. If
`FLOWFIT_SUPPORT_EMAIL_VERIFIED=true`, the `-SupportEmailVerified` switch is
required so the production web deploy cannot be enabled by accident.

---

### 8. store_release_build.ps1
**Purpose**: Production artifact build wrapper for store/web handoff. It fails
early when the git working tree is dirty, required production environment
values, signing files, or public web URLs are missing. By default it also runs
analyzer, Flutter tests, and Android release lint before producing artifacts.

**Required environment values**:
```powershell
$env:FLOWFIT_SUPPORT_EMAIL = 'support@flowfit.com'
$env:FLOWFIT_PUBLIC_WEB_BASE_URL = 'https://flowfit.your-owned-domain.com'
# Optional when the deployed Flutter web app is served from a subpath.
# The wrapper derives this from FLOWFIT_PUBLIC_WEB_BASE_URL when omitted.
# $env:FLOWFIT_WEB_BASE_HREF = '/Hackathon-FlowFit/'
$env:SUPABASE_URL = 'https://PROJECT_REF.supabase.co'
$env:SUPABASE_PUBLISHABLE_KEY = 'REPLACE_WITH_SUPABASE_PUBLISHABLE_KEY'
$env:ORG_GRADLE_PROJECT_FLOWFIT_ANDROID_APPLICATION_ID = 'com.oldstlabs.flowfit'
$env:ORG_GRADLE_PROJECT_FLOWFIT_AUTH_SCHEME = 'com.oldstlabs.flowfit'
# Optional Android wrapper signing path for CI/ephemeral release machines:
$env:FLOWFIT_ANDROID_KEYSTORE_BASE64 = 'REPLACE_WITH_BASE64_ENCODED_UPLOAD_KEYSTORE'
$env:FLOWFIT_ANDROID_KEYSTORE_PASSWORD = 'REPLACE_WITH_UPLOAD_KEYSTORE_PASSWORD'
$env:FLOWFIT_ANDROID_KEY_ALIAS = 'upload'
$env:FLOWFIT_ANDROID_KEY_PASSWORD = 'REPLACE_WITH_UPLOAD_KEY_PASSWORD'
# Optional on macOS when Xcode signing needs an explicit export profile:
$env:FLOWFIT_IOS_EXPORT_OPTIONS_PLIST = "$HOME/export_options.plist"
```

You can also copy `.env.release.example` to ignored `.env.release`, fill the
same values there, and pass `-EnvFile .env.release` to the audit or build
wrapper. The loader accepts simple `NAME=value` lines and does not print key
values.

The iOS target reads production bundle/auth values from
`ios/Flutter/FlowFit.xcconfig`, requires macOS with Xcode, and uses
`FLOWFIT_IOS_EXPORT_OPTIONS_PLIST` when the variable is set.

**Build Android, iOS, and web artifacts**:
```powershell
pwsh -NoProfile -File scripts/store_release_build.ps1 -Target All
```

Run `-Target All` on macOS for the complete Play Store, App Store, and web
handoff. On Windows, run the Android and web targets separately because iOS IPA
archive/export is not available from the Windows Flutter toolchain.

**Build only iOS for App Store/TestFlight**:
```powershell
pwsh -NoProfile -File scripts/store_release_build.ps1 -Target iOS
```

**Build only Flutter web**:
```powershell
pwsh -NoProfile -File scripts/store_release_build.ps1 -Target Web
```

**Build only Flutter web with WebAssembly output**:
```powershell
pwsh -NoProfile -File scripts/store_release_build.ps1 -Target Web -WebWasm
```

**Run the strict audit before building**:
```powershell
pwsh -NoProfile -File scripts/store_release_build.ps1 -Target All -RunStrictAudit -SupportEmailVerified
```

**Build from an ignored release env file**:
```powershell
Copy-Item .env.release.example .env.release
# Fill .env.release locally, then:
pwsh -NoProfile -File scripts/store_release_build.ps1 -Target All -RunStrictAudit -EnvFile .env.release
```

The Android target requires ignored `android/key.properties` and the referenced
upload keystore, or the signing env variables above. When signing env variables
are used, `scripts/store_release_build.ps1` writes ignored signing files before
the build and removes them before exit. It fails instead of overwriting an
existing keystore file. Every target requires real Supabase client values from
`SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`, or the local fallback
`lib/secrets.dart`; the wrapper passes those values to Flutter as
`--dart-define` inputs and never writes them to the artifact manifest. The iOS
target produces the signed IPA under `build/ios/ipa/` when Apple signing is
configured. The web target builds `build/web`, replaces `support@flowfit.com`
in the built public compliance pages with `FLOWFIT_SUPPORT_EMAIL`, creates
`build/release/flowfit-web-release.zip` for static-host uploads, and writes
`build/store-release-artifacts.json`. If `FLOWFIT_PUBLIC_WEB_BASE_URL` includes
a path, such as `https://iron-mark.github.io/Hackathon-FlowFit`, the wrapper
passes the matching Flutter `--base-href` so project-site hosts load assets
from the correct subpath. Override that derived value only when needed with
`FLOWFIT_WEB_BASE_HREF`. The web target uses the JavaScript backend by default;
pass `-WebWasm` when the deployed web release should be Flutter WebAssembly.
The artifact manifest records the selected backend in
`releaseInputs.webBuildBackend` and the resolved base href in
`releaseInputs.webBaseHref`.
Use `-AllowDirty` only for an explicitly documented emergency rebuild from
uncommitted source. Use `-SkipValidation` only when the same commit already has
fresh analyzer, test, and release-lint evidence.
That manifest includes artifact paths, SHA-256 digests, byte sizes, file
counts, git commit/dirty state, selected toolchain versions, non-secret release
inputs, and strict-audit summary when `-RunStrictAudit` is used. When
`-AllowDirty` is used, it also records the uncommitted status lines.
For web releases, confirm the manifest includes both `flutter-web-build` and
`flutter-web-release-zip`.
Confirm `com.oldstlabs.flowfit` belongs to the maintainer's store accounts and
replace every `your-owned-domain.com`, `PROJECT_REF`, and
`REPLACE_WITH_SUPABASE_PUBLISHABLE_KEY` example before running the production
wrapper. Production URLs must use a real HTTPS origin, not `.example`,
`.invalid`, `.test`, localhost, or an IP-loopback host.
Pass `-SupportEmailVerified` only after the configured/default support inbox is
owned by the maintainer and usable for privacy/account deletion contact.
When `-RunStrictAudit` is used, the wrapper also writes
`build/store-release-readiness-audit.json` and includes it in the artifact
manifest after the strict audit passes.

---

### 9. verify_web_deployment.ps1
**Purpose**: Verify the deployed Flutter web origin before using it in Play
Console or App Store Connect.

**Usage**:
```powershell
pwsh -NoProfile -File scripts/verify_web_deployment.ps1 `
  -BaseUrl 'https://flowfit.your-owned-domain.com' `
  -SupportEmail 'support@flowfit.com' `
  -OutFile build/web-deployment-verification.json
```

The script checks the app shell, `manifest.json`, public privacy page, and
public account-deletion page. It requires HTTPS for real deployment URLs,
verifies the configured support email, rejects internal maintainer/store-review
wording, and writes JSON evidence when `-OutFile` is provided.

For local smoke testing only, run a local static server for `build/web` and add
`-AllowInsecureLocalhost`.

### GitHub Pages deployment workflow

`.github/workflows/flutter-web-pages.yml` builds the production Flutter web
artifact with `scripts/store_release_build.ps1 -Target Web -SkipFlutterPubGet`,
uploads `build/web` to GitHub Pages, deploys it, and verifies the deployed
site with `scripts/verify_web_deployment.ps1`. It uploads the JSON verification
evidence as `flowfit-github-pages-verification`.

The workflow has a `deploy-ready` job. Pushes to `main` skip the production
Pages deployment with a notice until Supabase variables and verified support
inbox status are configured. Manual dispatch uses the same gate.

Configure repository variables before dispatching it:

- `FLOWFIT_PUBLIC_WEB_BASE_URL`, for example
  `https://iron-mark.github.io/Hackathon-FlowFit`.
- `SUPABASE_URL`.
- `SUPABASE_PUBLISHABLE_KEY`.
- Optional `FLOWFIT_SUPPORT_EMAIL`.
- `FLOWFIT_SUPPORT_EMAIL_VERIFIED=true`, set only after the configured/default
  support inbox is receiving mail from outside the maintainer account.

If the repository has no Pages site yet, enable Settings > Pages > GitHub
Actions as the source before expecting the workflow to publish.

---

### 10. configure_local_release.ps1
**Purpose**: Create/update local release configuration from validated inputs.
By default it writes only non-secret Android package/auth IDs to tracked
`android/gradle.properties`. When real Supabase client values are provided, it
also writes ignored `lib/secrets.dart` as a local fallback for the production
wrapper without printing the key. Store/web builds should prefer
`SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` environment variables.

**Usage**:
```powershell
pwsh -NoProfile -File scripts/configure_local_release.ps1
```

**With Supabase client config**:
```powershell
pwsh -NoProfile -File scripts/configure_local_release.ps1 `
  -SupabaseUrl 'https://PROJECT_REF.supabase.co' `
  -SupabasePublishableKey 'REPLACE_WITH_SUPABASE_PUBLISHABLE_KEY' `
  -Force
```

The helper rejects placeholder/example/smoke IDs and secret/service-role
Supabase keys.

---

## 🚀 Quick Start

### First Time Setup

1. **Connect your devices**:
   ```bash
   adb devices
   ```
   Should show:
   ```
   6ece264d        device
   adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp    device
   ```

2. **Build and install on watch**:
   ```bash
   scripts\build_and_install.bat
   ```

3. **Approve installation on watch** when prompted

4. **Run on watch**:
   ```bash
   scripts\run_watch.bat
   ```

### Daily Development

For quick iterations during development:

```bash
# Make code changes, then:
scripts\run_watch.bat

# Or for phone:
scripts\run_phone.bat
```

Hot reload will work automatically for quick UI changes.

---

## 🔧 Manual Commands

If you prefer manual control:

### Watch Commands
```bash
# Clean build
flutter clean
flutter pub get

# Build APK
flutter build apk --debug

# Install
adb -s 6ece264d install -r build\app\outputs\flutter-apk\app-debug.apk

# Run with hot reload
flutter run -d 6ece264d

# Uninstall
adb -s 6ece264d uninstall com.oldstlabs.flowfit
```

### Phone Commands
```bash
# Run on phone
flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp

# Install APK
adb -s adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp install -r build\app\outputs\flutter-apk\app-debug.apk
```

---

## 🐛 Troubleshooting

### Script Fails with "Device not found"

**Check devices**:
```bash
adb devices
```

**If watch not showing**:
1. Check USB connection
2. Enable ADB debugging on watch
3. Restart ADB: `adb kill-server && adb start-server`

### "INSTALL_FAILED_USER_RESTRICTED"

**Solution**: Approve installation on watch screen
- Watch will show "Install app?" prompt
- Tap "Install" button
- Must approve within 30 seconds

### "INSTALL_FAILED_MISSING_SHARED_LIBRARY"

**Solution**: This should be fixed in the latest build
- Check `android/app/src/main/AndroidManifest.xml`
- Ensure wearable library is set to `required="false"`

### Build Fails

**Clean and rebuild**:
```bash
flutter clean
flutter pub get
scripts\build_and_install.bat
```

**Check Kotlin errors**:
- Review `android/app/src/main/kotlin/` files
- Check logcat for detailed errors

---

## 📊 Script Output

### Successful Build
```
========================================
FlowFit Build and Install Script
========================================

Step 1: Cleaning previous builds...
✓ Clean complete

Step 2: Getting dependencies...
✓ Dependencies resolved

Step 3: Building APK for watch...
✓ Built build\app\outputs\flutter-apk\app-debug.apk

Step 4: Checking connected devices...
6ece264d        device

Step 5: Installing on watch (6ece264d)...
✓ Installation successful

========================================
SUCCESS! App installed on watch
========================================
```

### Failed Build
```
ERROR: Build failed
Compilation error. See log for more details

Common issues:
1. Kotlin compilation errors
2. Missing dependencies
3. SDK version mismatch
```

---

## 🎯 Best Practices

### Development Workflow

1. **Use `run_watch.bat` for quick iterations**
   - Faster than full rebuild
   - Hot reload enabled
   - Good for UI changes

2. **Use `build_and_install.bat` for clean builds**
   - After major changes
   - After dependency updates
   - When debugging build issues

3. **Check logs regularly**
   ```bash
   adb -s 6ece264d logcat | findstr "FlowFit"
   ```

4. **Run release readiness checks before handoff**
   ```powershell
   pwsh -NoProfile -File scripts/release_readiness_audit.ps1
   ```

5. **Run release preflight before handoff**
   ```powershell
   pwsh -NoProfile -File scripts/release_preflight.ps1 -IncludeReleaseSmoke
   ```

6. **Build production artifacts after external config is complete**
   ```powershell
   pwsh -NoProfile -File scripts/store_release_build.ps1 -Target All -RunStrictAudit -SupportEmailVerified
   ```
   Run this on macOS for the complete Android, iOS, and web handoff. On
   Windows, use `-Target Android` and `-Target Web` separately because iOS
   archive/export requires Xcode.

### Performance Tips

- **Keep watch connected via USB** for faster deployment
- **Use hot reload** (`r` in terminal) for quick UI changes
- **Use hot restart** (`R` in terminal) for state changes
- **Clean build** only when necessary (it's slow)

---

## 📝 Creating Custom Scripts

You can create your own scripts based on these templates:

### Example: Clean Install Script
```batch
@echo off
echo Cleaning and reinstalling...
flutter clean
adb -s 6ece264d uninstall com.oldstlabs.flowfit
flutter pub get
flutter run -d 6ece264d
```

### Example: Log Viewer Script
```batch
@echo off
echo Viewing FlowFit logs...
adb -s 6ece264d logcat | findstr "FlowFit MainActivity HealthTrackingManager"
```

---

## 🔗 Related Documentation

- **[Installation Troubleshooting](../docs/INSTALLATION_TROUBLESHOOTING.md)** - Detailed error solutions
- **[Build Fixes Applied](../docs/BUILD_FIXES_APPLIED.md)** - Recent fixes
- **[Run Instructions](../docs/RUN_INSTRUCTIONS.md)** - Device-specific commands

---

## 💡 Tips

- **Always approve installations on watch** - Required for security
- **Keep watch unlocked during install** - Installation fails if locked
- **Check battery level** - Low battery can cause issues
- **Use WiFi debugging** - For wireless development (advanced)

---

**Back to [Main README](../README.md)**
