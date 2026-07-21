-- Canonicalize kids-only mode.
--
-- FlowFit is a kids fitness app (ages 7-12): the UserProfile constructor,
-- fromJson, and every live writer (survey completion, buddy onboarding) all
-- produce is_kids_mode = true, and the only reader (dashboard_screen) renders
-- KidsProfileScreen unconditionally. The column, however, still defaulted to
-- false, which disagreed with the app and let any row created outside the app
-- (or by a pre-kids-mode client) sit at false forever. The client-side hazard
-- (fromJson defaulting false and clobbering a backend true on the next sync)
-- was fixed in the app; this aligns the backend to match.

begin;

-- New rows are kids-mode unless a future adult mode explicitly opts out.
alter table public.user_profiles
  alter column is_kids_mode set default true;

-- Backfill existing rows: nothing in the app intentionally writes false, so any
-- false is stale (e.g. the pre-kids-mode default). Safe to canonicalize to true.
update public.user_profiles
set is_kids_mode = true
where is_kids_mode is distinct from true;

comment on column public.user_profiles.is_kids_mode is
  'Flag indicating kids/Buddy mode. FlowFit is kids-only, so this defaults to true; re-seed from a real user choice if an adult mode ships.';

commit;
