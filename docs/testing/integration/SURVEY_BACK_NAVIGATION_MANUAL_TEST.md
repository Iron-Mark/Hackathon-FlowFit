# Survey Back Button Navigation - Manual Testing Guide

## Overview

This document provides manual testing procedures to verify that the back button navigation works correctly through all survey steps after implementing the fix for the onboarding back button issue.

## Requirements Being Tested

- **Requirement 1.1**: Back button navigates to previous survey step
- **Requirement 1.2**: Data is preserved when navigating back
- **Requirement 1.4**: No black screens appear during navigation

## Prerequisites

- Flutter app installed on a test device or emulator
- Access to the survey flow (either through signup or direct navigation)

## Test Cases

### Test Case 1: Back Button from Basic Info to Survey Intro

**Objective**: Verify back button works from Step 1 to Step 0

**Steps**:

1. Launch the app
2. Navigate to the survey intro screen (either through signup or direct navigation)
3. Tap "LET'S PERSONALIZE" button
4. Verify you're on the "Tell us about yourself" screen (Basic Info)
5. Tap the back button in the app bar
6. **Expected Result**: You should return to the Survey Intro screen showing "Quick Setup" and "(2 Minutes)"
7. **Verify**: No black screen appears

**Status**: ☐ Pass ☐ Fail

**Notes**:

---

---

### Test Case 2: Data Preservation - Basic Info

**Objective**: Verify data is preserved when navigating back from Body Measurements

**Steps**:

1. Navigate to Basic Info screen
2. Select gender: "Male"
3. Enter age: "30"
4. Tap "Continue" button
5. Verify you're on "Body Measurements" screen
6. Tap the back button
7. **Expected Result**: You should return to Basic Info screen
8. **Verify**: Gender is still "Male" and age is still "30"

**Status**: ☐ Pass ☐ Fail

**Notes**:

---

---

### Test Case 3: Complete Back Navigation Through All Steps

**Objective**: Verify back button works through entire survey flow

**Steps**:

1. Start from Survey Intro screen
2. Tap "LET'S PERSONALIZE"
3. **Step 1 - Basic Info**:
   - Select gender: "Female"
   - Enter age: "25"
   - Tap "Continue"
4. **Step 2 - Body Measurements**:
   - Enter weight: "60" kg
   - Enter height: "165" cm
   - Tap "Continue"
5. **Step 3 - Activity Goals**:
   - Select activity level: "Moderately Active"
   - Select goal: "Lose Weight"
   - Tap "Continue"
6. **Step 4 - Daily Targets**:
   - Verify you're on "Your Daily Targets" screen
7. **Now navigate backwards**:
   - Tap back button → Should return to Activity Goals
   - Tap back button → Should return to Body Measurements
   - Tap back button → Should return to Basic Info
   - Tap back button → Should return to Survey Intro

**Expected Results**:

- Each back button tap navigates to the previous screen
- No black screens appear at any point
- All screens display correctly

**Status**: ☐ Pass ☐ Fail

**Notes**:

---

---

### Test Case 4: Forward and Backward Data Preservation

**Objective**: Verify data persists through multiple forward/backward navigations

**Steps**:

1. Navigate to Basic Info
2. Select gender: "Other"
3. Enter age: "35"
4. Tap "Continue" → Body Measurements screen
5. Enter weight: "75" kg
6. Enter height: "180" cm
7. Tap back button → Basic Info screen
8. **Verify**: Gender is "Other", age is "35"
9. Tap "Continue" again → Body Measurements screen
10. **Verify**: Weight is "75" kg, height is "180" cm
11. Tap "Continue" → Activity Goals screen
12. Select activity level: "Very Active"
13. Select goal: "Build Muscle"
14. Tap back button → Body Measurements screen
15. **Verify**: Weight and height are still preserved
16. Tap back button → Basic Info screen
17. **Verify**: Gender and age are still preserved

**Expected Results**:

- All data is preserved through forward and backward navigation
- No data loss occurs
- No black screens appear

**Status**: ☐ Pass ☐ Fail

**Notes**:

---

---

### Test Case 5: No Black Screen Verification

**Objective**: Specifically verify no black screens appear during navigation

**Steps**:

1. Navigate through survey: Intro → Basic Info → Body Measurements
2. Fill in required data at each step
3. Use back button to navigate: Body Measurements → Basic Info → Survey Intro
4. **At each navigation**:
   - Verify the screen renders immediately
   - Verify no black/empty screen appears
   - Verify no loading delays or flickers
   - Verify all UI elements are visible

**Expected Results**:

- Smooth transitions between screens
- No black screens at any point
- No error messages or crashes
- All screens render correctly

**Status**: ☐ Pass ☐ Fail

**Notes**:

---

---

### Test Case 6: Survey Intro Back Button

**Objective**: Verify back button on Survey Intro navigates correctly

**Steps**:

1. Navigate to Survey Intro from dashboard or after signup
2. Verify back button is visible in app bar (if applicable)
3. Tap back button
4. **Expected Result**: Should navigate to previous screen (dashboard or welcome)
5. **Verify**: No black screen appears

**Status**: ☐ Pass ☐ Fail

**Notes**:

---

---

## Test Summary

**Date Tested**: ******\_\_\_******

**Tester Name**: ******\_\_\_******

**Device/Emulator**: ******\_\_\_******

**Flutter Version**: ******\_\_\_******

**Overall Result**: ☐ All Tests Pass ☐ Some Tests Fail

**Total Tests**: 6
**Passed**: **\_**
**Failed**: **\_**

## Issues Found

| Test Case | Issue Description | Severity | Screenshot/Video |
| --------- | ----------------- | -------- | ---------------- |
|           |                   |          |                  |
|           |                   |          |                  |
|           |                   |          |                  |

## Additional Notes

---

---

---

## Sign-off

**Tested By**: ******\_\_\_****** **Date**: ******\_\_\_******

**Reviewed By**: ******\_\_\_****** **Date**: ******\_\_\_******

**Approved**: ☐ Yes ☐ No

---

## Quick Verification Checklist

Use this quick checklist for rapid verification:

- ☐ Back button visible on all survey screens (except intro)
- ☐ Back button navigates to previous screen
- ☐ No black screens appear
- ☐ Data preserved when going back
- ☐ Data preserved when going forward again
- ☐ All 4 survey steps accessible
- ☐ Can navigate from Step 4 back to Step 0
- ☐ No crashes or errors
- ☐ Smooth transitions
- ☐ UI renders correctly at each step
