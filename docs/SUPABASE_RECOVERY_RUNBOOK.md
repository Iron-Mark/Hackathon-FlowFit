# FlowFit Supabase Recovery Runbook

This runbook rebuilds FlowFit against a new Supabase development project.

## 1. Create the Supabase Project

Create a new Supabase project named `flowfit-dev`.

- Region: choose Singapore or the nearest Southeast Asia region available.
- Auth provider: enable Email.
- Keep email confirmation enabled so local smoke tests exercise the mobile
  redirect/deep-link path.
- Redirect URLs:
  - `com.oldstlabs.flowfit://auth-callback`
  - `com.oldstlabs.flowfit.dev://auth-callback`

Do not use the old project ref `dnasghxxqwibwqnljvxr` for this recovery.

## 2. Enable Project MCP

Open `.mcp.json` and replace `REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF` with the new project ref.

Expected URL shape:

```json
{
  "mcpServers": {
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp?project_ref=<new-flowfit-dev-ref>&features=database,docs,debugging,development"
    }
  }
}
```

Notes:

- Keep this read-write for development migrations. Do not add `read_only=true`
  until the recovery migration and advisor fixes are complete.
- Do not store Supabase personal access tokens, service-role keys, or database passwords in the repo.
- After editing `.mcp.json`, reload or restart Codex so the project-scoped Supabase MCP appears.
- Complete the Supabase OAuth flow when Codex asks for MCP authentication.
- Advisory audit mode defaults to recovery MCP posture and expects write access:
  `pwsh -NoProfile -File scripts/release_readiness_audit.ps1`.
- Strict release audit mode defaults to release MCP posture and expects
  `read_only=true` after migrations/advisors are done:
  `pwsh -NoProfile -File scripts/release_readiness_audit.ps1 -Strict`.

## 3. Restore Local Flutter Credentials

In the Supabase dashboard, open Project Settings -> API.

Copy:

- Project URL
- Publishable key

Preferred for production, store, and web builds:

```powershell
$env:SUPABASE_URL = 'https://PROJECT_REF.supabase.co'
$env:SUPABASE_PUBLISHABLE_KEY = 'REPLACE_WITH_SUPABASE_PUBLISHABLE_KEY'
```

The app reads those values through tracked Dart build-time config and the
release wrapper passes them with `--dart-define`.

You can put the same values in ignored `.env.release` by copying
`.env.release.example`, then pass `-EnvFile .env.release` to
`scripts\release_readiness_audit.ps1` or `scripts\store_release_build.ps1`.

Optional local fallback: copy `lib/secrets.dart.example` to `lib/secrets.dart`
and fill the values:

```dart
class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT_REF.supabase.co';
  static const String publishableKey = 'sb_publishable_YOUR_KEY';

  @Deprecated('Use publishableKey instead.')
  static const String anonKey = publishableKey;
}
```

`lib/secrets.dart` is gitignored. Never put service-role or secret keys in Flutter.

Current FlowFit resolves `supabase_flutter` 2.10.x, where the initialize
parameter is still named `anonKey`. The app passes the publishable key through
that older parameter name for SDK compatibility.

## 4. Apply the Backend Migration

The canonical recovery migration is:

```powershell
supabase\migrations\20260614062844_recreate_flowfit_backend.sql
```

Older fragmented migration files are archived under
`supabase\legacy_migrations\` for reference only. Do not apply them to a new
FlowFit development project.

It creates or repairs:

- `public.user_profiles`
- `public.buddy_profiles`
- `public.workout_sessions`
- `public.heart_rate`
- `public.account_deletion_requests`
- `public.flowfit_recovery_quarantine`
- `updated_at` trigger function and table triggers
- RLS policies using `(select auth.uid()) = user_id`
- explicit authenticated and service-role grants for the Data API
- explicit `extensions` schema usage for UUID defaults
- cleanup of legacy policies and stale grants before canonical policies/grants
  are recreated

If this recovery migration is ever applied to a partially populated development
project, rows that cannot satisfy the repaired required columns are copied to
`public.flowfit_recovery_quarantine` before cleanup deletes run. That table has
RLS enabled and is granted only to `service_role`; inspect it with Supabase MCP
or the SQL editor before discarding any quarantined legacy data. For production
or valuable user data, take a backup and write a purpose-built data migration
instead of using this recovery migration as-is.

MCP path after Codex reload:

1. Use Supabase MCP to verify the project URL and publishable key.
2. Apply `20260614062844_recreate_flowfit_backend.sql`.
3. Run Supabase advisors and fix high-risk security or performance findings.
4. Verify `public.request_account_deletion()` is `security invoker`, not a
   privileged public function.
5. Verify `public.account_deletion_requests` is not tied to `auth.users` with
   `on delete cascade`; queue rows are retained for admin processing after the
   Auth user is deleted.
6. Verify `public.has_pending_account_deletion(uuid)` exists and the app-data
   insert/update RLS policies call it to block writes while deletion is pending
   or processing.
7. After migrations and advisor fixes are complete, switch verification-only
   MCP use to `read_only=true` or remove the MCP config until more schema work
   is needed. Strict release audit treats a write-capable MCP URL as a release
   blocker. Never point this MCP config at production data.

CLI path if you prefer terminal auth:

```powershell
npx -y supabase@latest login
npx -y supabase@latest link --project-ref <new-flowfit-dev-ref>
npx -y supabase@latest db push --linked --dry-run
npx -y supabase@latest db push --linked
```

## 5. Verify Database Shape

Use MCP `execute_sql` or the dashboard SQL editor:

```sql
select table_name, column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name in (
    'user_profiles',
    'buddy_profiles',
    'workout_sessions',
    'heart_rate',
    'account_deletion_requests'
  )
order by table_name, ordinal_position;
```

```sql
select schemaname, tablename, policyname, cmd, roles
from pg_policies
where schemaname = 'public'
  and tablename in (
    'user_profiles',
    'buddy_profiles',
    'workout_sessions',
    'heart_rate',
    'account_deletion_requests'
  )
order by tablename, policyname;
```

```sql
select table_schema, table_name, privilege_type
from information_schema.role_table_grants
where grantee in ('authenticated', 'service_role')
  and table_schema = 'public'
  and table_name in (
    'user_profiles',
    'buddy_profiles',
    'workout_sessions',
    'heart_rate',
    'account_deletion_requests'
  )
order by grantee, table_name, privilege_type;
```

```sql
select
  role_name,
  has_schema_privilege(role_name, 'extensions', 'USAGE') as has_usage
from (values ('authenticated'), ('service_role')) as roles(role_name);
```

Expected extension schema grants:

- `authenticated` and `service_role` have `USAGE` on `extensions` so table
  defaults that call `extensions.gen_random_uuid()` work during inserts.

```sql
select
  routine_schema,
  routine_name,
  grantee,
  privilege_type
from information_schema.routine_privileges
where routine_schema = 'public'
  and routine_name = 'request_account_deletion'
order by grantee, privilege_type;
```

Expected RPC grants:

- `authenticated` has `EXECUTE`.
- `anon` does not have `EXECUTE`.

Expected deletion queue grants:

- `authenticated` has only `SELECT` and `INSERT` on
  `public.account_deletion_requests`.
- `service_role` has `SELECT` and `UPDATE` on
  `public.account_deletion_requests` for admin queue processing.
- `account_deletion_requests_user_id_fkey` is absent, so the queue row is not
  cascaded away during the later Auth user deletion step.

```sql
select
  c.relname as table_name,
  con.conname as constraint_name,
  con.contype as constraint_type,
  con.convalidated as is_validated
from pg_constraint con
join pg_class c on c.oid = con.conrelid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
    'user_profiles',
    'buddy_profiles',
    'workout_sessions',
    'heart_rate',
    'account_deletion_requests'
  )
order by c.relname, con.conname;
```

`NOT VALID` check constraints are expected when repairing a partially existing
project. They still protect new or updated rows. Clean old bad rows first, then
validate constraints explicitly.

## 6. Run Local Checks

```powershell
pwsh -NoProfile -File scripts\release_readiness_audit.ps1
flutter pub get
dart analyze --format=machine
flutter analyze
flutter test --reporter compact
flutter build apk --debug --no-pub
flutter build apk --debug -t lib\main_wear.dart --no-pub
```

The audit command does not print credentials. It should move from Supabase
warnings to passes after `.mcp.json` points at the recreated development
project and `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY` are set, or the ignored
`lib/secrets.dart` fallback contains real development values.

## 7. Smoke Test the App

With real Supabase client values:

1. Create a dev test user through the app.
2. Confirm signup/login reaches onboarding or dashboard.
3. Complete profile onboarding and verify a `user_profiles` row exists for the auth user.
4. Complete Buddy onboarding and verify:
   - a `buddy_profiles` row exists for the auth user
   - the same `user_profiles.user_id` row has Buddy onboarding fields updated
5. Save and list one workout session if the UI path is reachable.

After the smoke test passes, re-enable email confirmation before treating the project as a realistic shared dev backend.
