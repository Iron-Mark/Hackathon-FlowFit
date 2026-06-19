# Deprecated RLS Quick Fix

Do not use partial RLS snippets for this maintained fork.

The supported setup path is:

1. Create/link the maintained Supabase development project.
2. Apply `supabase/migrations/20260614062844_recreate_flowfit_backend.sql`.
3. Verify RLS, policies, grants, and functions with
   `scripts/verify_supabase_backend.ps1 -Linked`.
4. Run advisors and finish the rest of the release checks with
   `docs/SUPABASE_RECOVERY_RUNBOOK.md`.

The older quick-fix SQL missed current tables, policy cleanup, explicit grants,
and recovery requirements. Keeping it as an executable setup path would make the
database drift from the app.
