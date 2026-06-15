# Troubleshooting Guide

## Supabase Table or Schema Cache Errors

Common error:

```text
PostgrestException(message: Could not find the table 'public.user_profiles' in the schema cache, code: PGRST205)
```

Check these first:

1. Runtime `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` dart defines, or the
   ignored `lib/secrets.dart` script fallback, point to the intended Supabase
   project.
2. The project uses a publishable key, not a service-role or secret key.
3. `supabase/migrations/20260614062844_recreate_flowfit_backend.sql` has been
   applied to that same project.
4. Supabase dashboard Settings -> API schema cache has been reloaded.
5. RLS policies and authenticated grants exist for `user_profiles`,
   `buddy_profiles`, `workout_sessions`, `heart_rate`, and
   `account_deletion_requests`.

Use `docs/SUPABASE_RECOVERY_RUNBOOK.md` for the full recovery flow.

## Local Verification

Run the consolidated local gate:

```powershell
pwsh -NoProfile -File scripts/release_preflight.ps1 -IncludeReleaseSmoke
```

This runs dependencies, analyzers, tests, Flutter web build, public
privacy/account-deletion page checks, Android debug, Wear debug, and a
debug-signed release App Bundle smoke build.

## Common Issues

### Invalid email or password

- Make sure the user exists in the active Supabase project.
- Check email spelling and password length.
- Verify the Email auth provider is enabled in Supabase.

### App crashes on startup

- Confirm the app was launched with real `SUPABASE_URL` and
  `SUPABASE_PUBLISHABLE_KEY` dart defines, or use the release wrapper to pass
  the ignored `lib/secrets.dart` fallback values.
- Confirm the Supabase project is active.
- Check the device network connection.

### Survey or Buddy data does not save

- Confirm the canonical migration was applied.
- Confirm RLS policies use the signed-in user's `auth.uid()`.
- Confirm the app is authenticated before saving.

### Network errors

- Check device internet access.
- Check Supabase status at https://status.supabase.com.
- Confirm firewalls or VPNs are not blocking Supabase.

## More Help

- Supabase recovery: `docs/SUPABASE_RECOVERY_RUNBOOK.md`
- Release readiness: `docs/RELEASE_READINESS_RUNBOOK.md`
- Store checklist: `docs/STORE_SUBMISSION_CHECKLIST.md`
- Manual testing: `test/integration/MANUAL_TESTING_GUIDE.md`
