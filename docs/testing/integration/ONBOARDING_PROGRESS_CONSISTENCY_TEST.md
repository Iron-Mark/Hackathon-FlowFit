# Onboarding Progress Consistency - Manual Test Guide

## Test Objective

Verify that all onboarding survey screens consistently display the progress indicator with correct step numbers, styling, and positioning.

## Prerequisites

- App is running on a device or emulator
- User is logged in or has just signed up
- User is at the survey intro screen or can navigate to it

## Test Procedure

### Test 1: Survey Intro Screen (Step 0/4)

**Navigation**: From signup or dashboard → Survey Intro

**Expected Results**:

- ✅ AppBar displays "Quick Setup" as title
- ✅ Progress indicator shows "0/4" in the top-right corner
- ✅ Progress text is grey color with semi-bold font weight
- ✅ Progress text has 16px right padding
- ✅ NO back button is visible (currentStep = 0)
- ✅ Horizontal progress bars below AppBar show all 4 steps as grey (not started)

**Visual Check**:

```
┌─────────────────────────────────────────────┐
│          Quick Setup                  0/4   │
└─────────────────────────────────────────────┘
│ ▭ ▭ ▭ ▭  (all grey bars)                   │
```

---

### Test 2: Basic Info Screen (Step 1/4)

**Navigation**: Survey Intro → Click "LET'S PERSONALIZE"

**Expected Results**:

- ✅ AppBar has NO title (only back button and progress)
- ✅ Progress indicator shows "1/4" in the top-right corner
- ✅ Progress text styling matches intro screen (grey, semi-bold)
- ✅ Back button IS visible (arrow pointing left)
- ✅ Horizontal progress bars show 1st bar filled (blue), others grey

**Visual Check**:

```
┌─────────────────────────────────────────────┐
│ ←                                      1/4  │
└─────────────────────────────────────────────┘
│ ▬ ▭ ▭ ▭  (1st blue, rest grey)             │
```

---

### Test 3: Body Measurements Screen (Step 2/4)

**Navigation**: Basic Info → Click "Continue"

**Expected Results**:

- ✅ AppBar has NO title
- ✅ Progress indicator shows "2/4" in the top-right corner
- ✅ Progress text styling is consistent
- ✅ Back button IS visible
- ✅ Horizontal progress bars show 2 bars filled (blue), 2 grey

**Visual Check**:

```
┌─────────────────────────────────────────────┐
│ ←                                      2/4  │
└─────────────────────────────────────────────┘
│ ▬ ▬ ▭ ▭  (2 blue, 2 grey)                  │
```

---

### Test 4: Activity & Goals Screen (Step 3/4)

**Navigation**: Body Measurements → Click "Continue"

**Expected Results**:

- ✅ AppBar displays "Activity & Goals" as title
- ✅ Progress indicator shows "3/4" in the top-right corner
- ✅ Progress text styling is consistent
- ✅ Back button IS visible
- ✅ Horizontal progress bars show 3 bars filled (blue), 1 grey

**Visual Check**:

```
┌─────────────────────────────────────────────┐
│ ←    Activity & Goals                  3/4  │
└─────────────────────────────────────────────┘
│ ▬ ▬ ▬ ▭  (3 blue, 1 grey)                  │
```

---

### Test 5: Daily Targets Screen (Step 4/4)

**Navigation**: Activity & Goals → Click "Continue"

**Expected Results**:

- ✅ AppBar displays "Your Daily Targets" as title
- ✅ Progress indicator shows "4/4" in the top-right corner
- ✅ Progress text styling is consistent
- ✅ Back button IS visible
- ✅ Horizontal progress bars show ALL 4 bars filled (blue)

**Visual Check**:

```
┌─────────────────────────────────────────────┐
│ ←    Your Daily Targets                4/4  │
└─────────────────────────────────────────────┘
│ ▬ ▬ ▬ ▬  (all blue)                        │
```

---

## Test 6: Back Navigation Flow

**Procedure**:

1. Start at Daily Targets (4/4)
2. Click back button → Should show Activity & Goals (3/4)
3. Click back button → Should show Body Measurements (2/4)
4. Click back button → Should show Basic Info (1/4)
5. Click back button → Should show Survey Intro (0/4)

**Expected Results**:

- ✅ Progress indicator updates correctly on each back navigation
- ✅ Horizontal progress bars update to reflect current step
- ✅ No visual glitches or layout shifts
- ✅ Back button disappears on intro screen (0/4)

---

## Test 7: Visual Consistency Check

**Procedure**: Navigate through entire flow forward and backward

**Check for Consistency**:

- ✅ Progress text always appears in same position (top-right)
- ✅ Progress text always has same styling (grey, semi-bold)
- ✅ Progress text always has same padding (16px right)
- ✅ AppBar height is consistent across all screens
- ✅ Back button icon and color are consistent
- ✅ Title text (when present) has consistent styling

---

## Test 8: Edge Cases

### Test 8a: Rapid Navigation

**Procedure**: Quickly click Continue → Back → Continue → Back

**Expected Results**:

- ✅ Progress indicator updates smoothly
- ✅ No race conditions or incorrect step numbers
- ✅ UI remains responsive

### Test 8b: Screen Rotation (Mobile)

**Procedure**: Rotate device on each screen

**Expected Results**:

- ✅ Progress indicator remains visible and correctly positioned
- ✅ Layout adapts properly to landscape/portrait
- ✅ No text overflow or truncation

---

## Success Criteria

All tests must pass with the following confirmed:

1. **Presence**: Progress indicator appears on ALL 5 survey screens
2. **Accuracy**: Step numbers are correct (0/4, 1/4, 2/4, 3/4, 4/4)
3. **Styling**: Text color is grey, font weight is semi-bold
4. **Positioning**: Always in AppBar actions area, right-aligned with 16px padding
5. **Consistency**: Visual appearance is identical across all screens
6. **Functionality**: Updates correctly during forward and backward navigation

---

## Test Results

**Date**: ********\_********
**Tester**: ********\_********
**Device/Emulator**: ********\_********

| Test                            | Pass | Fail | Notes |
| ------------------------------- | ---- | ---- | ----- |
| Test 1: Intro (0/4)             | ☐    | ☐    |       |
| Test 2: Basic Info (1/4)        | ☐    | ☐    |       |
| Test 3: Body Measurements (2/4) | ☐    | ☐    |       |
| Test 4: Activity & Goals (3/4)  | ☐    | ☐    |       |
| Test 5: Daily Targets (4/4)     | ☐    | ☐    |       |
| Test 6: Back Navigation         | ☐    | ☐    |       |
| Test 7: Visual Consistency      | ☐    | ☐    |       |
| Test 8: Edge Cases              | ☐    | ☐    |       |

**Overall Result**: ☐ PASS ☐ FAIL

**Additional Notes**:

---

---

---

---

## Known Issues

None at this time.

---

## Requirements Coverage

This test verifies the following requirements:

- **Requirement 1.1**: Progress indicator on every survey screen
- **Requirement 1.2**: Format "X/Y" with current and total steps
- **Requirement 1.3**: Positioned in AppBar actions area (right side)
- **Requirement 1.4**: Grey color and semi-bold font weight
- **Requirement 1.5**: Visible on all 5 screens with correct numbers
- **Requirement 2.1**: SurveyAppBar used consistently
- **Requirement 2.2**: SurveyAppBar supports progress indicator
- **Requirement 2.3**: No duplicate AppBar implementations
- **Requirement 2.4**: Backward compatibility maintained
- **Requirement 2.5**: Refactored screens use standardized widget
