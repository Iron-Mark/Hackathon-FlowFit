# Supabase Database Migrations

This directory contains the active FlowFit Supabase migration set.

## Active Migrations

- `20260614062844_recreate_flowfit_backend.sql`
- `20260703010000_add_support_requests.sql` and later incremental migrations
- `20260821000000_harden_support_deletion_and_auth.sql`

`20260614062844_recreate_flowfit_backend.sql` is the canonical recovery
migration for the maintained fork. It creates or
repairs the current app backend schema:

- `public.user_profiles`
- `public.buddy_profiles`
- `public.workout_sessions`
- `public.heart_rate`
- `public.support_requests` (added by later incremental migrations)
- `public.account_deletion_requests`
- `public.flowfit_recovery_quarantine`

It also enables RLS, creates user-owned policies, refreshes `updated_at`
triggers, and grants authenticated clients explicit Data API privileges.
Invalid legacy rows are copied into the service-role-only quarantine table
before cleanup deletes run, so partially populated development repair attempts
are auditable. Back up production or valuable data and write a purpose-built
data migration instead of applying this recovery migration directly.

The 2026-08-21 hardening migration binds support-request email to the JWT,
purges `support_requests` on account deletion, adds an `auth.users` foreign
key with `ON DELETE CASCADE`, and deletes the caller's auth user through
`private.delete_own_auth_user()`. Apply it to the live linked project with
the pinned CLI below after a dry run.

## Legacy Migrations

The older fragmented SQL files were moved to:

```text
supabase/legacy_migrations/
```

Keep them for historical reference only. Do not apply them to a new FlowFit
development project. They predate the current Buddy/profile schema and can
produce stale tables or conflicting policies.

## Apply

After creating and linking a new `flowfit-dev` Supabase project:

```powershell
npx -y supabase@2.115.0 db push --linked --dry-run
npx -y supabase@2.115.0 db push --linked
```

For full recovery steps, MCP setup, dashboard settings, credential recovery, and
verification, see:

```text
docs/SUPABASE_RECOVERY_RUNBOOK.md
```

After applying the migration, run the canonical read-only verifier:

```powershell
pwsh -NoProfile -File scripts/verify_supabase_backend.ps1 -Linked
```

The SQL is tracked at:

```text
supabase/verification/verify_flowfit_backend.sql
```
