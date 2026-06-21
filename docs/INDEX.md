# FlowFit Documentation Index

## 📚 Documentation Structure

All documentation has been organized into logical folders for easy navigation.

---

## 📁 Root Directory

Essential documentation that should be easily accessible:

- **README.md** - Main project overview and setup instructions
- **docs/QUICK_START.md** - Quick start guide for developers
- **docs/TROUBLESHOOTING.md** - Common issues and solutions

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

- **release/FINAL_RELEASE_HANDOFF_2026-06-19.md**
  - Current Android Play Store candidate artifact path, SHA-256 hash, size,
    source commit, strict audit result, and store handoff steps

- **release/PLAY_STORE_RELEASE_NOTES_AND_QA_2026-06-19.md**
  - Play Store release notes, listing copy, QA evidence, and real-device
    internal testing checklist

- **release/PLAY_STORE_SUBMISSION_CHECKLIST_2026-06-19.md**
  - Final Play Console setup, protected release workflow inputs, listing copy,
    store assets, and internal testing result template

- **release/GITHUB_ACTIONS_CI_AUDIT_2026-06-19.md**
  - Remote workflow status, automatic CI gate coverage, intentional CI limits,
    and future protected release-workflow recommendation

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

### Maintenance
- **maintenance/CODEBASE_CLEANUP_AUDIT_2026-06-19.md**
  - Current docs clutter, dependency freshness, and DRY/refactor findings
  - Safe cleanup applied during the maintained-fork release cycle
  - Recommended cleanup and dependency-upgrade order

### AI Classification
- **AI_DETECTION_COMPLETE_IMPLEMENTATION.md**
  - Complete AI detection implementation guide
  - Architecture diagrams
  - Code examples
  - Data persistence strategy

- **AI_CLASSIFICATION_VERIFICATION.md**
  - Verification checklist
  - Testing guide
  - Debugging guide
  - Performance metrics

- **AI_LIVE_CLASSIFICATION_CONFIRMED.md** ✅
  - Confirmation that AI is working
  - Code verification
  - Flow verification
  - Testing checklist

### Watch Integration
- **ACTIVITY_AI_WATCH_INTEGRATION.md**
  - Watch heart rate integration
  - Data flow details
  - UI feedback implementation

### General Implementation
- **FINAL_INTEGRATION_SUMMARY.md**
  - Overall integration summary
  - System architecture

- **REAL_DATA_INTEGRATION.md**
  - Real data vs simulated data
  - Integration details

- **SCHEMA_ALIGNMENT_FIX.md**
  - Database schema fixes
  - Alignment issues resolved

- **FLOW_FIXED.md**
  - Flow fixes and improvements

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

- **AI_INTEGRATION_UNIFIED.md**
  - Unified AI integration approach

- **SHARED_AI_CLASSIFIER_INTEGRATION.md**
  - Shared classifier implementation

### Workout Features
- **RUNNING_FLOW_COMPLETE.md**
  - Complete running workout flow
  - From start to summary

- **WORKOUT_FLOW_UI_UPDATE.md**
  - Workout flow UI improvements

- **SHARE_ACHIEVEMENT_FEATURE.md**
  - Achievement sharing feature
  - Social media integration

### Wellness Features
- **WELLNESS_TRACKER_COMPLETE.md**
  - Complete wellness tracker implementation

- **WELLNESS_TRACKER_IMPLEMENTATION.md**
  - Implementation details

- **WELLNESS_MAP_GPS_TRACKING.md**
  - GPS tracking for wellness

- **WELLNESS_STEP_COUNTER.md**
  - Step counter implementation

- **WELLNESS_BPM_FIXES.md**
  - Heart rate fixes for wellness

- **WELLNESS_UI_FIXES.md**
  - UI improvements for wellness

### Authentication & User Management
- **AUTH_GUARDS_SUMMARY.md**
  - Authentication guards implementation

- **EMAIL_VERIFICATION_FLOW_UPDATE.md**
  - Email verification flow

### UI & UX Features
- **UI_CONSISTENCY_IMPROVEMENTS.md**
  - UI consistency updates

- **SURVEY_HEADER_CONSISTENCY_UPDATE.md**
  - Survey UI improvements

- **MEASUREMENT_UNIT_TOGGLE_UPDATE.md**
  - Unit toggle feature (kg/lbs, km/mi)

### Navigation & Deep Links
- **DEEP_LINK_QUICK_REF.md**
  - Deep link implementation reference

---

## 🛠️ Scripts (`scripts/`)

Build and deployment scripts:

- **clean_build.bat** - Clean build script for Windows
- **build_and_install.bat** - Build and install to device
- **run_phone.bat** - Run phone app
- **run_watch.bat** - Run watch app
- **test-phone.bat** - Test phone app
- **test-watch.bat** - Test watch app
- **test_phone_receiver.sh** - Test phone data receiver (Linux/Mac)
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
5. Maintenance: `docs/maintenance/`

### For Verification:
1. AI Working: `docs/implementation/AI_LIVE_CLASSIFICATION_CONFIRMED.md`
2. Testing: `docs/implementation/AI_CLASSIFICATION_VERIFICATION.md`
3. Complete Guide: `docs/implementation/AI_DETECTION_COMPLETE_IMPLEMENTATION.md`

---

## 📊 Documentation Statistics

- **Markdown Documents:** 200 files
- **Active Markdown Documents:** 188 files outside `docs/archive`
- **Archived Markdown Documents:** 12 files
- **Presentation Docs:** 3 files
- **Maintenance Docs:** 1 file
- **Scripts:** 23 files

---

## 🔍 Search Tips

### Find by Topic:
- **AI Classification:** Search for "AI_" prefix
- **Wellness Features:** Search for "WELLNESS_" prefix
- **Workout Features:** Search for "WORKOUT_" or "RUNNING_"
- **UI/UX:** Search for "UI_" prefix
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
4. **Need to verify AI?** See `docs/implementation/AI_LIVE_CLASSIFICATION_CONFIRMED.md`
5. **Having issues?** Check `docs/TROUBLESHOOTING.md`

---

**Last Updated:** June 19, 2026
**Maintained By:** Development Team
