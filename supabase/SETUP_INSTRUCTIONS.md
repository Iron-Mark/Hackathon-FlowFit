# FlowFit Supabase Setup Instructions

FlowFit now uses one canonical backend migration for maintained-fork recovery.
Do not run the archived legacy migration files for a new project.

## Setup Order

1. Create a new Supabase project for FlowFit.
2. Replace the project ref in `.mcp.json`, then reload Codex and complete
   Supabase MCP OAuth.
3. Copy `lib/secrets.dart.example` to ignored `lib/secrets.dart` and fill the
   Project URL plus publishable key.
4. Apply `supabase/migrations/20260614062844_recreate_flowfit_backend.sql`.
5. Run Supabase advisors and fix high-risk findings.
6. Smoke test signup, login, profile onboarding, Buddy onboarding, workout
   session persistence, and account deletion request.

## CLI Path

The Supabase CLI can be run through `npx` on this machine:

```powershell
npx --yes supabase --version
npx --yes supabase login
npx --yes supabase link --project-ref <new-flowfit-dev-ref>
npx --yes supabase db push --linked --dry-run
npx --yes supabase db push --linked
```

`supabase/config.toml` is present for local CLI workflows. Commands that inspect
or apply local migrations require the local Supabase stack to be running.

## Full Runbook

Use the maintained runbook for the exact MCP, dashboard, credential, migration,
advisor, and smoke-test steps:

```text
docs/SUPABASE_RECOVERY_RUNBOOK.md
```
