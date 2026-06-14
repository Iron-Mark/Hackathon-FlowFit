# Supabase Database Migrations

This directory contains the active FlowFit Supabase migration set.

## Active Migration

- `20260614062844_recreate_flowfit_backend.sql`

This is the canonical recovery migration for the maintained fork. It creates or
repairs the current app backend schema:

- `public.user_profiles`
- `public.buddy_profiles`
- `public.workout_sessions`
- `public.heart_rate`
- `public.account_deletion_requests`
- `public.flowfit_recovery_quarantine`

It also enables RLS, creates user-owned policies, refreshes `updated_at`
triggers, and grants authenticated clients explicit Data API privileges.
Invalid legacy rows are copied into the service-role-only quarantine table
before cleanup deletes run, so partially populated development repair attempts
are auditable. Back up production or valuable data and write a purpose-built
data migration instead of applying this recovery migration directly.

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
npx -y supabase@latest db push --linked --dry-run
npx -y supabase@latest db push --linked
```

For full recovery steps, MCP setup, dashboard settings, credential recovery, and
verification SQL, see:

```text
docs/SUPABASE_RECOVERY_RUNBOOK.md
```
