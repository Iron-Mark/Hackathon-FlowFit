# RLS Policy Testing Guide for user_profiles Table

This guide provides step-by-step instructions for testing Row Level Security (RLS) policies on the `user_profiles` table.

## Prerequisites

- Supabase project set up and running
- At least 2 test user accounts created
- Access to Supabase Dashboard or SQL Editor
- Flutter app connected to Supabase

## Test Scenarios

### Scenario 1: User Can Insert Their Own Profile

**Expected Result**: ✅ Success

**Steps**:

1. Sign up or log in as User A in the Flutter app
2. Complete the onboarding survey
3. Verify profile is created in Supabase Dashboard
4. Check that `user_id` matches User A's auth ID

**SQL Verification**:

```sql
-- Run in Supabase SQL Editor (as admin)
SELECT user_id, full_name, created_at
FROM user_profiles
WHERE user_id = '<USER_A_ID>';
```

---

### Scenario 2: User Can View Their Own Profile

**Expected Result**: ✅ Success - User sees their profile data

**Steps**:

1. Log in as User A in the Flutter app
2. Navigate to Profile tab
3. Verify all profile data is displayed correctly
4. Check that data matches what was entered in onboarding

**SQL Verification**:

```sql
-- Run as User A via Supabase client
const { data, error } = await supabase
  .from('user_profiles')
  .select('*')
  .eq('user_id', userA.id)
  .single();
```

---

### Scenario 3: User Can Update Their Own Profile

**Expected Result**: ✅ Success - Profile is updated

**Steps**:

1. Log in as User A in the Flutter app
2. Navigate to Profile tab
3. Tap edit button
4. Change some profile fields (e.g., weight, daily targets)
5. Save changes
6. Verify changes are reflected in UI
7. Refresh app and verify changes persist

**SQL Verification**:

```sql
-- Run as User A via Supabase client
const { data, error } = await supabase
  .from('user_profiles')
  .update({ weight: 75.5 })
  .eq('user_id', userA.id);
```

---

### Scenario 4: User Cannot View Another User's Profile

**Expected Result**: ❌ No data returned or empty result

**Steps**:

1. Log in as User A in the Flutter app
2. Try to fetch User B's profile via direct API call
3. Verify no data is returned

**SQL Verification**:

```sql
-- Run as User A via Supabase client (should return empty)
const { data, error } = await supabase
  .from('user_profiles')
  .select('*')
  .eq('user_id', '<USER_B_ID>')
  .single();

// Expected: data = null, error = "Row not found"
```

**Manual Test**:

```dart
// In Flutter app, logged in as User A
final response = await supabase
  .from('user_profiles')
  .select()
  .eq('user_id', '<USER_B_ID>')
  .single();

// Should return error or null
```

---

### Scenario 5: User Cannot Update Another User's Profile

**Expected Result**: ❌ Update fails or affects 0 rows

**Steps**:

1. Log in as User A in the Flutter app
2. Try to update User B's profile via direct API call
3. Verify update fails or affects 0 rows

**SQL Verification**:

```sql
-- Run as User A via Supabase client (should fail)
const { data, error } = await supabase
  .from('user_profiles')
  .update({ weight: 100 })
  .eq('user_id', '<USER_B_ID>');

// Expected: error or count = 0
```

---

### Scenario 6: User Cannot Insert Profile for Another User

**Expected Result**: ❌ Insert fails

**Steps**:

1. Log in as User A in the Flutter app
2. Try to insert a profile with User B's ID
3. Verify insert fails

**SQL Verification**:

```sql
-- Run as User A via Supabase client (should fail)
const { data, error } = await supabase
  .from('user_profiles')
  .insert({
    user_id: '<USER_B_ID>',
    full_name: 'Fake Name',
    age: 25
  });

// Expected: error due to RLS policy violation
```

---

### Scenario 7: Unauthenticated Users Cannot Access Profiles

**Expected Result**: ❌ No access

**Steps**:

1. Log out from the Flutter app
2. Try to fetch any profile data
3. Verify no data is returned

**SQL Verification**:

```sql
-- Run without authentication (should fail)
const { data, error } = await supabase
  .from('user_profiles')
  .select('*');

// Expected: error or empty array
```

---

### Scenario 8: Verify Data Constraints

**Expected Results**:

- ✅ Valid data accepted
- ❌ Invalid data rejected

**Age Constraint Test**:

```dart
// Should fail - age too young
await supabase.from('user_profiles').insert({
  'user_id': currentUserId,
  'age': 10, // Invalid: < 13
});

// Should fail - age too old
await supabase.from('user_profiles').insert({
  'user_id': currentUserId,
  'age': 150, // Invalid: > 120
});

// Should succeed
await supabase.from('user_profiles').insert({
  'user_id': currentUserId,
  'age': 25, // Valid
});
```

**Gender Constraint Test**:

```dart
// Should fail - invalid gender
await supabase.from('user_profiles').insert({
  'user_id': currentUserId,
  'gender': 'invalid', // Not in enum
});

// Should succeed
await supabase.from('user_profiles').insert({
  'user_id': currentUserId,
  'gender': 'male', // Valid
});
```

**Activity Level Constraint Test**:

```dart
// Should fail - invalid activity level
await supabase.from('user_profiles').insert({
  'user_id': currentUserId,
  'activity_level': 'super_active', // Not in enum
});

// Should succeed
await supabase.from('user_profiles').insert({
  'user_id': currentUserId,
  'activity_level': 'moderately_active', // Valid
});
```

**Unit Constraint Test**:

```dart
// Should fail - invalid height unit
await supabase.from('user_profiles').insert({
  'user_id': currentUserId,
  'height_unit': 'meters', // Not in enum
});

// Should succeed
await supabase.from('user_profiles').insert({
  'user_id': currentUserId,
  'height_unit': 'cm', // Valid
});
```

---

## Automated Testing Script

Create a Dart test file to automate RLS testing:

```dart
// test/integration/rls_policies_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient supabase;
  late String userAId;
  late String userBId;

  setUpAll(() async {
    // Initialize Supabase
    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL',
      anonKey: 'YOUR_ANON_KEY',
    );
    supabase = Supabase.instance.client;
  });

  group('RLS Policy Tests', () {
    test('User can insert their own profile', () async {
      // Sign in as User A
      final authResponse = await supabase.auth.signInWithPassword(
        email: 'userA@test.com',
        password: 'password123',
      );
      userAId = authResponse.user!.id;

      // Insert profile
      final response = await supabase.from('user_profiles').insert({
        'user_id': userAId,
        'full_name': 'User A',
        'age': 25,
      }).select();

      expect(response, isNotEmpty);
    });

    test('User can view their own profile', () async {
      final response = await supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userAId)
          .single();

      expect(response['user_id'], equals(userAId));
    });

    test('User cannot view another user profile', () async {
      // Sign in as User B
      final authResponse = await supabase.auth.signInWithPassword(
        email: 'userB@test.com',
        password: 'password123',
      );
      userBId = authResponse.user!.id;

      // Try to fetch User A's profile
      try {
        await supabase
            .from('user_profiles')
            .select()
            .eq('user_id', userAId)
            .single();
        fail('Should not be able to view another user profile');
      } catch (e) {
        expect(e, isNotNull);
      }
    });

    test('User cannot update another user profile', () async {
      // Logged in as User B, try to update User A
      try {
        await supabase
            .from('user_profiles')
            .update({'weight': 100})
            .eq('user_id', userAId);
        fail('Should not be able to update another user profile');
      } catch (e) {
        expect(e, isNotNull);
      }
    });
  });
}
```

---

## Quick Verification Checklist

- [ ] User A can create their profile
- [ ] User A can read their profile
- [ ] User A can update their profile
- [ ] User A cannot read User B's profile
- [ ] User A cannot update User B's profile
- [ ] User A cannot insert profile for User B
- [ ] Unauthenticated requests return no data
- [ ] Age constraint rejects invalid ages (< 13 or > 120)
- [ ] Gender constraint rejects invalid values
- [ ] Activity level constraint rejects invalid values
- [ ] Height/weight unit constraints reject invalid values
- [ ] Updated_at timestamp auto-updates on changes

---

## Troubleshooting

### Issue: RLS policies not working

**Solution**: Verify RLS is enabled

```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'user_profiles';
-- rowsecurity should be true
```

### Issue: User can see other users' data

**Solution**: Check policy definitions

```sql
SELECT * FROM pg_policies WHERE tablename = 'user_profiles';
```

### Issue: Constraints not enforced

**Solution**: Verify constraints exist

```sql
SELECT conname, contype, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'user_profiles'::regclass;
```

---

## Additional Resources

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL RLS Guide](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- [Testing RLS Policies](https://supabase.com/docs/guides/auth/row-level-security#testing-policies)
