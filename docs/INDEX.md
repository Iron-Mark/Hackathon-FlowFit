# FlowFit Documentation Index

## 📚 Documentation Structure

All documentation has been organized into logical folders for easy navigation.

---

## 📁 Root Directory

Essential documentation that should be easily accessible:

- **README.md** - Main project overview and setup instructions
- **docs/QUICK_START.md** - Quick start guide for developers
- **docs/TROUBLESHOOTING.md** - Common issues and solutions
- **docs/architecture/ARCHITECTURE_REVIEW_2026-07-14.md** - Architecture survey, guard-test constraint map, executed refactor stages, and the ranked refactor roadmap

---

## 🎤 Presentation Documentation (`docs/presentation/`)

Documentation specifically for presenting the project to judges or stakeholders:

### Main Presentation Guide
- **PRESENTATION_GUIDE_WATCH_AI_INTEGRATION.md** ⭐
  - Complete presentation guide with layman's terms
  - Technical deep dive on Wear OS integration
  - Demo script and talking points
  - Q&A preparation
  - Data flow diagrams

### Technical References
- **SAMSUNG_TECHNOLOGIES_USED.md**
  - Complete list of Samsung technologies used
  - Samsung Health SDK details
  - Integration architecture
  - Talking points for judges

- **WEAR_OS_INTEGRATION_SUMMARY.md**
  - Quick technical summary
  - Step-by-step data flow
  - Performance metrics
  - Demo checklist

---

## 🔧 Implementation Documentation (`docs/implementation/`)

Technical implementation details and verification:

### Backend Recovery
- **SUPABASE_RECOVERY_RUNBOOK.md** (root docs runbook)
  - New Supabase development project setup
  - Project-scoped MCP configuration
  - Canonical migration and verification commands
  - Local Flutter credential recovery

### Release Readiness
- **RELEASE_READINESS_RUNBOOK.md** (root docs runbook)
  - Play Store signing and package configuration
  - App Store/macOS signing requirements
  - Flutter web build and hosting notes
  - Local verification command list

- **release/MVP_LAUNCH_READINESS_2026-07-02.md**
  - Current MVP launch verdict, verified local gates, Supabase/support blockers,
    and next release plan

- **release/FINAL_LAUNCH_EVIDENCE_2026-07-04.md**
  - Final merged-main MVP evidence, live web status, CI status, support inbox
    proof, Android AAB hash, and remaining external launch steps

- **release/PLAY_CONSOLE_SUBMISSION_PACK_2026-07-04.md**
  - Current Play Console internal testing candidate, listing copy, review notes,
    data-entry checklist, and real-device QA template

- **STORE_SUBMISSION_CHECKLIST.md**
  - Play Store, App Store, and Flutter web submission checklist
  - Privacy/account deletion URL requirements
  - Store asset and review readiness tracking

- **STORE_METADATA_DRAFT.md**
  - Draft Play/App Store listing copy
  - Screenshot shot list and review notes
  - Release evidence checklist

- **PRIVACY_DATA_MAP.md**
  - Data inventory for Play Data safety and App Store privacy labels
  - Points to `ios/Runner/PrivacyInfo.xcprivacy` as the iOS app privacy
    manifest source
  - Third-party SDK data considerations
  - Account deletion, retention, and disclosure notes

### AI Classification
- **AI_DETECTION_COMPLETE_IMPLEMENTATION.md**
  - Complete AI detection implementation guide
  - Architecture diagrams
  - Code examples
  - Data persistence strategy

---

## ✨ Feature Documentation (`docs/features/`)

Documentation for specific features implemented:

### AI & Activity Classification
- **AI_MODE_DETECTION_FEATURE.md**
  - AI activity mode detection overview
  - Feature description
  - How it works

- **AI_MODE_LIVE_DETECTION.md**
  - Live detection implementation
  - Continuous monitoring
  - Real-time updates

### Workout Features
- **SHARE_ACHIEVEMENT_FEATURE.md**
  - Achievement sharing feature
  - Social media integration

### Wellness Features
- **WELLNESS_MAP_GPS_TRACKING.md**
  - GPS tracking for wellness

- **WELLNESS_STEP_COUNTER.md**
  - Step counter implementation

---

## 🛠️ Scripts (`scripts/`)

Build and deployment scripts:

- **fetch_fonts.ps1** - Download General Sans fonts from Fontshare (the .otf
  files are not committed for license reasons; run once after cloning)
- **build_and_install.bat** - Build and install to device
- **run_phone.bat** - Run phone app
- **run_watch.bat** - Run watch app
- **test-phone.bat** - Test phone app
- **test-watch.bat** - Test watch app
- **release_preflight.ps1** - Local analyzer, test, web, optional Wasm,
  Android, Wear, and release-smoke gate
- **verify_offline_app_actions.ps1** - Supabase-free route/action guard and
  broad button-driven feature smoke
- **release_readiness_audit.ps1** - Non-secret Supabase, signing, web, and
  store readiness audit
- **verify_support_inbox.ps1** - Non-secret support inbox verification
  evidence for store/web release handoff
- **verify_store_metadata.ps1** - Store listing, privacy-map, checklist, and
  icon-asset evidence for Play/App Store/web handoff
- **verify_store_artifacts.ps1** - Re-hash and validate
  `build/store-release-artifacts.json` outputs before store/web handoff
- **create_android_upload_keystore.ps1** - Ignored Android upload signing
  material generator and private CI secret handoff
- **export_android_signing_env.ps1** - Ignored private Android signing secret
  handoff exporter from existing local keystore material
- **create_ios_export_options.ps1** - Ignored App Store/TestFlight
  export-options plist generator for macOS release hosts
- **store_release_build.ps1** - Production Android, iOS, and web artifact
  wrapper

---

## 🎯 Quick Navigation

### For Presentation:
1. Start with: `docs/presentation/PRESENTATION_GUIDE_WATCH_AI_INTEGRATION.md`
2. Reference: `docs/presentation/SAMSUNG_TECHNOLOGIES_USED.md`
3. Quick facts: `docs/presentation/WEAR_OS_INTEGRATION_SUMMARY.md`

### For Development:
1. Setup: `README.md` and `docs/QUICK_START.md`
2. Issues: `docs/TROUBLESHOOTING.md`
3. Implementation: `docs/implementation/`
4. Features: `docs/features/`

### For Verification:
1. Complete Guide: `docs/implementation/AI_DETECTION_COMPLETE_IMPLEMENTATION.md`

---

## 📊 Documentation Statistics

- **Markdown Documents:** 90 files
- **Archived Markdown Documents:** 1 file (`docs/archive/`)
- **Presentation Docs:** 3 files
- **Scripts:** 30 files

---

## 🔍 Search Tips

### Find by Topic:
- **AI Classification:** Search for "AI_" prefix
- **Wellness Features:** Search for "WELLNESS_" prefix
- **Workout Features:** Search for "WORKOUT_" or "RUNNING_"
- **Integration:** Look in `docs/implementation/`

### Find by Purpose:
- **Presenting:** `docs/presentation/`
- **Building:** `scripts/`
- **Understanding:** `docs/features/`
- **Debugging:** `docs/TROUBLESHOOTING.md` or `docs/implementation/`

---

## 📝 Documentation Conventions

### File Naming:
- **UPPERCASE_WITH_UNDERSCORES.md** - Documentation files
- **lowercase_with_underscores.bat/sh** - Script files

### Folder Structure:
```
flowfit/
├── README.md                    # Main readme
├── docs/QUICK_START.md              # Quick start guide
├── docs/TROUBLESHOOTING.md          # Troubleshooting
├── docs/
│   ├── INDEX.md                # This file
│   ├── presentation/           # For judges/stakeholders
│   ├── implementation/         # Technical implementation
│   └── features/               # Feature documentation
└── scripts/                    # Build/deployment scripts
```

---

## 🚀 Getting Started

1. **New to the project?** Start with `README.md`
2. **Want to run it?** Check `docs/QUICK_START.md`
3. **Preparing presentation?** Go to `docs/presentation/`
4. **Having issues?** Check `docs/TROUBLESHOOTING.md`

---

**Last Updated:** July 12, 2026
**Maintained By:** Development Team
