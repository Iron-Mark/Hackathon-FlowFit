# FlowFit Supabase Database Setup

Use this guide when the app reports missing Supabase tables, schema-cache
errors, or onboarding/profile writes failing against a new project.

## Canonical Migration

The active migration is:

```text
supabase/migrations/20260614062844_recreate_flowfit_backend.sql
```

Older SQL files are archived in `supabase/legacy_migrations/` for reference
only. Do not apply `combined_migration.sql` or the old numbered migration files
to a new FlowFit project.

The canonical migration creates or repairs:

- `public.user_profiles`
- `public.buddy_profiles`
- `public.workout_sessions`
- `public.heart_rate`
- `public.account_deletion_requests`
- `public.flowfit_recovery_quarantine`
- RLS policies and authenticated Data API grants
- `updated_at` trigger support
- `request_account_deletion()`

The quarantine table is service-role-only. It preserves invalid legacy rows
before cleanup deletes if the recovery migration is applied to a partially
populated development project.

## Recommended Setup

Follow the full recovery guide:

```text
docs/SUPABASE_RECOVERY_RUNBOOK.md
```

Fast path after creating and linking the new Supabase project:

```powershell
npx --yes supabase login
npx --yes supabase link --project-ref <new-flowfit-dev-ref>
npx --yes supabase db push --linked --dry-run
npx --yes supabase db push --linked
```

You can also apply the canonical SQL through Supabase MCP or the dashboard SQL
editor after replacing `.mcp.json` with the real project ref and reloading
Codex.

## Verify

Use the verification SQL in `docs/SUPABASE_RECOVERY_RUNBOOK.md` to confirm
columns, policies, grants, and constraints.

Then run the local app gate:

```powershell
pwsh -NoProfile -File scripts/release_preflight.ps1 -IncludeReleaseSmoke
```

## Troubleshooting

If the app reports:

```text
PostgrestException(message: Could not find the table 'public.user_profiles' in the schema cache, code: PGRST205)
```

check these in order:

1. The running app/build received `SUPABASE_URL` and
   `SUPABASE_PUBLISHABLE_KEY` for the intended new Supabase project. Release
   scripts can read these from the process environment or ignored
   `.env.release`.
2. If no env/Dart defines are supplied, the optional ignored fallback
   `lib/secrets.dart` points at that same project and uses a publishable client
   key, not a secret or service-role key.
3. The canonical migration was applied to that same project.
4. Supabase dashboard Settings -> API schema cache has been reloaded.
5. RLS policies and authenticated grants exist for the public tables.

If using CLI local workflows, `supabase/config.toml` is initialized for FlowFit.
Local migration commands require the local Supabase stack to be running.
