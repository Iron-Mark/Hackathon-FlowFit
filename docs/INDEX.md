# FlowFit Documentation Index

## 📚 Documentation Structure

All documentation has been organized into logical folders for easy navigation.

---

## 📁 Root Directory

Essential documentation that should be easily accessible:

- **README.md** - Main project overview and setup instructions
- **QUICK_START.md** - Quick start guide for developers
- **TROUBLESHOOTING.md** - Common issues and solutions

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
- **SUPABASE_RECOVERY_RUNBOOK.md**
  - New Supabase development project setup
  - Project-scoped MCP configuration
  - Canonical migration and verification commands
  - Local Flutter credential recovery

### Release Readiness
- **RELEASE_READINESS_RUNBOOK.md**
  - Play Store signing and package configuration
  - App Store/macOS signing requirements
  - Flutter web build and hosting notes
  - Local verification command list

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
- **release_readiness_audit.ps1** - Non-secret Supabase, signing, web, and
  store readiness audit
- **verify_support_inbox.ps1** - Non-secret support inbox verification
  evidence for store/web release handoff
- **verify_store_metadata.ps1** - Store listing, privacy-map, checklist, and
  icon-asset evidence for Play/App Store/web handoff
- **create_android_upload_keystore.ps1** - Ignored Android upload signing
  material generator and private CI secret handoff
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
1. Setup: `README.md` and `QUICK_START.md`
2. Issues: `TROUBLESHOOTING.md`
3. Implementation: `docs/implementation/`
4. Features: `docs/features/`

### For Verification:
1. AI Working: `docs/implementation/AI_LIVE_CLASSIFICATION_CONFIRMED.md`
2. Testing: `docs/implementation/AI_CLASSIFICATION_VERIFICATION.md`
3. Complete Guide: `docs/implementation/AI_DETECTION_COMPLETE_IMPLEMENTATION.md`

---

## 📊 Documentation Statistics

- **Total Documents:** 134 files
- **Presentation Docs:** 3 files
- **Implementation Docs:** 9 files
- **Feature Docs:** 21 files
- **Root Docs:** 11 files
- **Scripts:** 22 files

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
- **Debugging:** `TROUBLESHOOTING.md` or `docs/implementation/`

---

## 📝 Documentation Conventions

### File Naming:
- **UPPERCASE_WITH_UNDERSCORES.md** - Documentation files
- **lowercase_with_underscores.bat/sh** - Script files

### Folder Structure:
```
flowfit/
├── README.md                    # Main readme
├── QUICK_START.md              # Quick start guide
├── TROUBLESHOOTING.md          # Troubleshooting
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
2. **Want to run it?** Check `QUICK_START.md`
3. **Preparing presentation?** Go to `docs/presentation/`
4. **Need to verify AI?** See `docs/implementation/AI_LIVE_CLASSIFICATION_CONFIRMED.md`
5. **Having issues?** Check `TROUBLESHOOTING.md`

---

**Last Updated:** June 14, 2026
**Maintained By:** Development Team
