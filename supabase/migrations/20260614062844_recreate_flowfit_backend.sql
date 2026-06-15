-- Canonical FlowFit backend recovery migration.
-- Targets a new development Supabase project, while staying additive for
-- partially configured projects created from the older fragmented scripts.

begin;

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

create or replace function public.update_updated_at_column()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Invalid legacy rows are preserved here before cleanup deletes run below.
-- This migration targets a new development project, but the quarantine table
-- makes partially populated repair attempts auditable instead of destructive.
create table if not exists public.flowfit_recovery_quarantine (
  id uuid primary key default extensions.gen_random_uuid(),
  source_table text not null,
  reason text not null,
  row_data jsonb not null,
  quarantined_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- user_profiles
-- ---------------------------------------------------------------------------

create table if not exists public.user_profiles (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  full_name text,
  age integer check (age is null or (age between 7 and 120)),
  gender text check (gender is null or gender in ('male', 'female', 'other')),
  weight double precision check (weight is null or weight > 0),
  height double precision check (height is null or height > 0),
  height_unit text default 'cm' check (height_unit in ('cm', 'ft')),
  weight_unit text default 'kg' check (weight_unit in ('kg', 'lbs')),
  activity_level text,
  goals text[] default '{}',
  wellness_goals text[] default '{}',
  notifications_enabled boolean not null default false,
  daily_calorie_target integer check (
    daily_calorie_target is null or daily_calorie_target >= 0
  ),
  daily_steps_target integer check (
    daily_steps_target is null or daily_steps_target >= 0
  ),
  daily_active_minutes_target integer check (
    daily_active_minutes_target is null or daily_active_minutes_target >= 0
  ),
  daily_water_target double precision check (
    daily_water_target is null or daily_water_target >= 0
  ),
  profile_image_url text,
  nickname text,
  is_kids_mode boolean not null default false,
  survey_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_profiles
  add column if not exists id uuid default extensions.gen_random_uuid(),
  add column if not exists user_id uuid,
  add column if not exists full_name text,
  add column if not exists age integer,
  add column if not exists gender text,
  add column if not exists weight double precision,
  add column if not exists height double precision,
  add column if not exists height_unit text default 'cm',
  add column if not exists weight_unit text default 'kg',
  add column if not exists activity_level text,
  add column if not exists goals text[] default '{}',
  add column if not exists wellness_goals text[] default '{}',
  add column if not exists notifications_enabled boolean not null default false,
  add column if not exists daily_calorie_target integer,
  add column if not exists daily_steps_target integer,
  add column if not exists daily_active_minutes_target integer,
  add column if not exists daily_water_target double precision,
  add column if not exists profile_image_url text,
  add column if not exists nickname text,
  add column if not exists is_kids_mode boolean not null default false,
  add column if not exists survey_completed boolean not null default false,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

update public.user_profiles
set id = extensions.gen_random_uuid()
where id is null;

insert into public.flowfit_recovery_quarantine (
  source_table,
  reason,
  row_data
)
select 'user_profiles', 'missing user_id', to_jsonb(profile_row)
from public.user_profiles as profile_row
where profile_row.user_id is null;

delete from public.user_profiles
where user_id is null;

alter table public.user_profiles
  alter column full_name drop not null,
  alter column age drop not null,
  alter column gender drop not null,
  alter column weight drop not null,
  alter column height drop not null,
  alter column height_unit drop not null,
  alter column weight_unit drop not null,
  alter column activity_level drop not null,
  alter column goals drop not null,
  alter column wellness_goals drop not null,
  alter column daily_calorie_target drop not null,
  alter column daily_steps_target drop not null,
  alter column daily_active_minutes_target drop not null,
  alter column daily_water_target drop not null,
  alter column profile_image_url drop not null,
  alter column nickname drop not null;

alter table public.user_profiles
  alter column id set default extensions.gen_random_uuid(),
  alter column id set not null,
  alter column user_id set not null,
  alter column goals set default '{}',
  alter column wellness_goals set default '{}',
  alter column notifications_enabled set default false,
  alter column notifications_enabled set not null,
  alter column is_kids_mode set default false,
  alter column is_kids_mode set not null,
  alter column survey_completed set default false,
  alter column survey_completed set not null,
  alter column created_at set default now(),
  alter column created_at set not null,
  alter column updated_at set default now(),
  alter column updated_at set not null;

-- Replace stale anonymous CHECK constraints from fragmented legacy migrations
-- with the canonical named constraints below. This keeps recovered projects
-- aligned with the current onboarding contract, including kids-mode ages 7+.
do $$
declare
  constraint_record record;
begin
  for constraint_record in
    select conname
    from pg_constraint
    where conrelid = 'public.user_profiles'::regclass
      and contype = 'c'
  loop
    execute format(
      'alter table public.user_profiles drop constraint if exists %I',
      constraint_record.conname
    );
  end loop;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'user_profiles_user_id_fkey'
      and conrelid = 'public.user_profiles'::regclass
  ) then
    alter table public.user_profiles
      add constraint user_profiles_user_id_fkey
      foreign key (user_id) references auth.users(id) on delete cascade;
  end if;
end;
$$;

create unique index if not exists user_profiles_user_id_unique
  on public.user_profiles(user_id);
create index if not exists idx_user_profiles_created_at
  on public.user_profiles(created_at);
create index if not exists idx_user_profiles_wellness_goals
  on public.user_profiles using gin (wellness_goals);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'user_profiles_age_valid'
      and conrelid = 'public.user_profiles'::regclass
  ) then
    alter table public.user_profiles
      add constraint user_profiles_age_valid
      check (age is null or (age between 7 and 120)) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'user_profiles_gender_valid'
      and conrelid = 'public.user_profiles'::regclass
  ) then
    alter table public.user_profiles
      add constraint user_profiles_gender_valid
      check (gender is null or gender in ('male', 'female', 'other')) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'user_profiles_weight_valid'
      and conrelid = 'public.user_profiles'::regclass
  ) then
    alter table public.user_profiles
      add constraint user_profiles_weight_valid
      check (weight is null or weight > 0) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'user_profiles_height_valid'
      and conrelid = 'public.user_profiles'::regclass
  ) then
    alter table public.user_profiles
      add constraint user_profiles_height_valid
      check (height is null or height > 0) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'user_profiles_height_unit_valid'
      and conrelid = 'public.user_profiles'::regclass
  ) then
    alter table public.user_profiles
      add constraint user_profiles_height_unit_valid
      check (height_unit in ('cm', 'ft')) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'user_profiles_weight_unit_valid'
      and conrelid = 'public.user_profiles'::regclass
  ) then
    alter table public.user_profiles
      add constraint user_profiles_weight_unit_valid
      check (weight_unit in ('kg', 'lbs')) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'user_profiles_daily_calorie_target_valid'
      and conrelid = 'public.user_profiles'::regclass
  ) then
    alter table public.user_profiles
      add constraint user_profiles_daily_calorie_target_valid
      check (daily_calorie_target is null or daily_calorie_target >= 0) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'user_profiles_daily_steps_target_valid'
      and conrelid = 'public.user_profiles'::regclass
  ) then
    alter table public.user_profiles
      add constraint user_profiles_daily_steps_target_valid
      check (daily_steps_target is null or daily_steps_target >= 0) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'user_profiles_daily_active_minutes_target_valid'
      and conrelid = 'public.user_profiles'::regclass
  ) then
    alter table public.user_profiles
      add constraint user_profiles_daily_active_minutes_target_valid
      check (
        daily_active_minutes_target is null or daily_active_minutes_target >= 0
      ) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'user_profiles_daily_water_target_valid'
      and conrelid = 'public.user_profiles'::regclass
  ) then
    alter table public.user_profiles
      add constraint user_profiles_daily_water_target_valid
      check (daily_water_target is null or daily_water_target >= 0) not valid;
  end if;
end;
$$;

drop trigger if exists update_user_profiles_updated_at
  on public.user_profiles;
create trigger update_user_profiles_updated_at
  before update on public.user_profiles
  for each row
  execute function public.update_updated_at_column();

-- ---------------------------------------------------------------------------
-- buddy_profiles
-- ---------------------------------------------------------------------------

create table if not exists public.buddy_profiles (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 20),
  color text not null default 'blue',
  level integer not null default 1 check (level >= 1),
  xp integer not null default 0 check (xp >= 0),
  unlocked_colors text[] not null default array['blue'],
  accessories jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.buddy_profiles
  add column if not exists id uuid default extensions.gen_random_uuid(),
  add column if not exists user_id uuid,
  add column if not exists name text,
  add column if not exists color text default 'blue',
  add column if not exists level integer not null default 1,
  add column if not exists xp integer not null default 0,
  add column if not exists unlocked_colors text[] not null default array['blue'],
  add column if not exists accessories jsonb not null default '{}'::jsonb,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

update public.buddy_profiles
set id = extensions.gen_random_uuid()
where id is null;

insert into public.flowfit_recovery_quarantine (
  source_table,
  reason,
  row_data
)
select 'buddy_profiles', 'missing user_id', to_jsonb(buddy_row)
from public.buddy_profiles as buddy_row
where buddy_row.user_id is null;

delete from public.buddy_profiles
where user_id is null;

update public.buddy_profiles
set
  name = coalesce(nullif(name, ''), 'Buddy'),
  color = coalesce(nullif(color, ''), 'blue'),
  level = coalesce(level, 1),
  xp = coalesce(xp, 0),
  unlocked_colors = coalesce(unlocked_colors, array['blue']),
  accessories = coalesce(accessories, '{}'::jsonb),
  created_at = coalesce(created_at, now()),
  updated_at = coalesce(updated_at, now());

alter table public.buddy_profiles
  alter column id set default extensions.gen_random_uuid(),
  alter column id set not null,
  alter column user_id set not null,
  alter column name set not null,
  alter column color set default 'blue',
  alter column color set not null,
  alter column level set default 1,
  alter column level set not null,
  alter column xp set default 0,
  alter column xp set not null,
  alter column unlocked_colors set default array['blue'],
  alter column unlocked_colors set not null,
  alter column accessories set default '{}'::jsonb,
  alter column accessories set not null,
  alter column created_at set default now(),
  alter column created_at set not null,
  alter column updated_at set default now(),
  alter column updated_at set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'buddy_profiles_user_id_fkey'
      and conrelid = 'public.buddy_profiles'::regclass
  ) then
    alter table public.buddy_profiles
      add constraint buddy_profiles_user_id_fkey
      foreign key (user_id) references auth.users(id) on delete cascade;
  end if;
end;
$$;

create unique index if not exists buddy_profiles_user_id_unique
  on public.buddy_profiles(user_id);
create index if not exists idx_buddy_profiles_level
  on public.buddy_profiles(level);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'buddy_profiles_name_valid'
      and conrelid = 'public.buddy_profiles'::regclass
  ) then
    alter table public.buddy_profiles
      add constraint buddy_profiles_name_valid
      check (char_length(name) between 1 and 20) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'buddy_profiles_level_valid'
      and conrelid = 'public.buddy_profiles'::regclass
  ) then
    alter table public.buddy_profiles
      add constraint buddy_profiles_level_valid
      check (level >= 1) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'buddy_profiles_xp_valid'
      and conrelid = 'public.buddy_profiles'::regclass
  ) then
    alter table public.buddy_profiles
      add constraint buddy_profiles_xp_valid
      check (xp >= 0) not valid;
  end if;
end;
$$;

drop trigger if exists update_buddy_profiles_updated_at
  on public.buddy_profiles;
create trigger update_buddy_profiles_updated_at
  before update on public.buddy_profiles
  for each row
  execute function public.update_updated_at_column();

-- ---------------------------------------------------------------------------
-- workout_sessions
-- ---------------------------------------------------------------------------

create table if not exists public.workout_sessions (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  workout_type text not null check (
    workout_type in ('running', 'walking', 'resistance')
  ),
  workout_subtype text,
  start_time timestamptz not null,
  end_time timestamptz,
  duration_seconds integer check (
    duration_seconds is null or duration_seconds >= 0
  ),
  pre_workout_mood integer check (
    pre_workout_mood is null or pre_workout_mood between 1 and 5
  ),
  pre_workout_mood_emoji text,
  pre_workout_notes text,
  post_workout_mood integer check (
    post_workout_mood is null or post_workout_mood between 1 and 5
  ),
  post_workout_mood_emoji text,
  post_workout_notes text,
  mood_change integer,
  goal_type text,
  target_distance double precision check (
    target_distance is null or target_distance >= 0
  ),
  target_duration integer check (
    target_duration is null or target_duration >= 0
  ),
  current_distance double precision not null default 0 check (
    current_distance >= 0
  ),
  distance_km double precision check (distance_km is null or distance_km >= 0),
  avg_pace double precision check (avg_pace is null or avg_pace >= 0),
  route_polyline text,
  steps integer check (steps is null or steps >= 0),
  elevation_gain_m integer check (
    elevation_gain_m is null or elevation_gain_m >= 0
  ),
  mode text,
  mission_id uuid,
  mission_completed boolean not null default false,
  exercises_completed jsonb not null default '[]'::jsonb,
  total_volume_kg double precision check (
    total_volume_kg is null or total_volume_kg >= 0
  ),
  rest_timer_seconds integer check (
    rest_timer_seconds is null or rest_timer_seconds in (60, 90, 120)
  ),
  audio_cues_enabled boolean not null default true,
  hr_monitor_enabled boolean not null default false,
  time_under_tension integer check (
    time_under_tension is null or time_under_tension >= 0
  ),
  avg_heart_rate integer check (
    avg_heart_rate is null or avg_heart_rate between 0 and 250
  ),
  max_heart_rate integer check (
    max_heart_rate is null or max_heart_rate between 0 and 250
  ),
  heart_rate_zones jsonb not null default '{}'::jsonb,
  calories_burned integer check (
    calories_burned is null or calories_burned >= 0
  ),
  status text not null default 'active' check (
    status in ('active', 'paused', 'completed', 'cancelled')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.workout_sessions
  add column if not exists id uuid default extensions.gen_random_uuid(),
  add column if not exists user_id uuid,
  add column if not exists workout_type text,
  add column if not exists workout_subtype text,
  add column if not exists start_time timestamptz,
  add column if not exists end_time timestamptz,
  add column if not exists duration_seconds integer,
  add column if not exists pre_workout_mood integer,
  add column if not exists pre_workout_mood_emoji text,
  add column if not exists pre_workout_notes text,
  add column if not exists post_workout_mood integer,
  add column if not exists post_workout_mood_emoji text,
  add column if not exists post_workout_notes text,
  add column if not exists mood_change integer,
  add column if not exists goal_type text,
  add column if not exists target_distance double precision,
  add column if not exists target_duration integer,
  add column if not exists current_distance double precision not null default 0,
  add column if not exists distance_km double precision,
  add column if not exists avg_pace double precision,
  add column if not exists route_polyline text,
  add column if not exists steps integer,
  add column if not exists elevation_gain_m integer,
  add column if not exists mode text,
  add column if not exists mission_id uuid,
  add column if not exists mission_completed boolean not null default false,
  add column if not exists exercises_completed jsonb not null default '[]'::jsonb,
  add column if not exists total_volume_kg double precision,
  add column if not exists rest_timer_seconds integer,
  add column if not exists audio_cues_enabled boolean not null default true,
  add column if not exists hr_monitor_enabled boolean not null default false,
  add column if not exists time_under_tension integer,
  add column if not exists avg_heart_rate integer,
  add column if not exists max_heart_rate integer,
  add column if not exists heart_rate_zones jsonb not null default '{}'::jsonb,
  add column if not exists calories_burned integer,
  add column if not exists status text not null default 'active',
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

update public.workout_sessions
set id = extensions.gen_random_uuid()
where id is null;

insert into public.flowfit_recovery_quarantine (
  source_table,
  reason,
  row_data
)
select 'workout_sessions', 'missing user_id', to_jsonb(session_row)
from public.workout_sessions as session_row
where session_row.user_id is null;

delete from public.workout_sessions
where user_id is null;

insert into public.flowfit_recovery_quarantine (
  source_table,
  reason,
  row_data
)
select
  'workout_sessions',
  'missing required workout identity',
  to_jsonb(session_row)
from public.workout_sessions as session_row
where session_row.workout_type is null
   or session_row.start_time is null;

delete from public.workout_sessions
where workout_type is null
   or start_time is null;

update public.workout_sessions
set
  current_distance = coalesce(current_distance, 0),
  mission_completed = coalesce(mission_completed, false),
  exercises_completed = coalesce(exercises_completed, '[]'::jsonb),
  audio_cues_enabled = coalesce(audio_cues_enabled, true),
  hr_monitor_enabled = coalesce(hr_monitor_enabled, false),
  heart_rate_zones = coalesce(heart_rate_zones, '{}'::jsonb),
  status = coalesce(status, 'active'),
  created_at = coalesce(created_at, now()),
  updated_at = coalesce(updated_at, now()),
  mode = case
    when workout_type = 'walking' and mode is null then 'free'
    else mode
  end;

alter table public.workout_sessions
  alter column id set default extensions.gen_random_uuid(),
  alter column id set not null,
  alter column user_id set not null,
  alter column workout_type set not null,
  alter column start_time set not null,
  alter column current_distance set default 0,
  alter column current_distance set not null,
  alter column mission_completed set default false,
  alter column mission_completed set not null,
  alter column exercises_completed set default '[]'::jsonb,
  alter column exercises_completed set not null,
  alter column audio_cues_enabled set default true,
  alter column audio_cues_enabled set not null,
  alter column hr_monitor_enabled set default false,
  alter column hr_monitor_enabled set not null,
  alter column heart_rate_zones set default '{}'::jsonb,
  alter column heart_rate_zones set not null,
  alter column status set default 'active',
  alter column status set not null,
  alter column created_at set default now(),
  alter column created_at set not null,
  alter column updated_at set default now(),
  alter column updated_at set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'workout_sessions_user_id_fkey'
      and conrelid = 'public.workout_sessions'::regclass
  ) then
    alter table public.workout_sessions
      add constraint workout_sessions_user_id_fkey
      foreign key (user_id) references auth.users(id) on delete cascade;
  end if;
end;
$$;

create index if not exists idx_workout_sessions_user_id
  on public.workout_sessions(user_id);
create index if not exists idx_workout_sessions_start_time
  on public.workout_sessions(start_time desc);
create index if not exists idx_workout_sessions_workout_type
  on public.workout_sessions(workout_type);
create index if not exists idx_workout_sessions_status
  on public.workout_sessions(status);
create index if not exists idx_workout_sessions_user_type
  on public.workout_sessions(user_id, workout_type);

alter table public.workout_sessions
  drop constraint if exists workout_sessions_type_valid;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'workout_sessions_type_valid'
      and conrelid = 'public.workout_sessions'::regclass
  ) then
    alter table public.workout_sessions
      add constraint workout_sessions_type_valid
      check (
        workout_type in ('running', 'walking', 'resistance')
      ) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'workout_sessions_status_valid'
      and conrelid = 'public.workout_sessions'::regclass
  ) then
    alter table public.workout_sessions
      add constraint workout_sessions_status_valid
      check (status in ('active', 'paused', 'completed', 'cancelled'))
      not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'workout_sessions_heart_rate_valid'
      and conrelid = 'public.workout_sessions'::regclass
  ) then
    alter table public.workout_sessions
      add constraint workout_sessions_heart_rate_valid
      check (
        (avg_heart_rate is null or avg_heart_rate between 0 and 250)
        and (max_heart_rate is null or max_heart_rate between 0 and 250)
      ) not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'workout_sessions_nonnegative_metrics_valid'
      and conrelid = 'public.workout_sessions'::regclass
  ) then
    alter table public.workout_sessions
      add constraint workout_sessions_nonnegative_metrics_valid
      check (
        (duration_seconds is null or duration_seconds >= 0)
        and (target_distance is null or target_distance >= 0)
        and (target_duration is null or target_duration >= 0)
        and current_distance >= 0
        and (distance_km is null or distance_km >= 0)
        and (avg_pace is null or avg_pace >= 0)
        and (steps is null or steps >= 0)
        and (elevation_gain_m is null or elevation_gain_m >= 0)
        and (total_volume_kg is null or total_volume_kg >= 0)
        and (time_under_tension is null or time_under_tension >= 0)
        and (calories_burned is null or calories_burned >= 0)
      ) not valid;
  end if;
end;
$$;

drop trigger if exists update_workout_sessions_updated_at
  on public.workout_sessions;
create trigger update_workout_sessions_updated_at
  before update on public.workout_sessions
  for each row
  execute function public.update_updated_at_column();

-- ---------------------------------------------------------------------------
-- heart_rate compatibility table
-- ---------------------------------------------------------------------------

create table if not exists public.heart_rate (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users(id) on delete cascade,
  bpm integer check (bpm is null or bpm between 0 and 250),
  "timestamp" bigint not null,
  status text,
  "ibiValues" jsonb not null default '[]'::jsonb,
  ibi_values jsonb not null default '[]'::jsonb,
  raw_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.heart_rate
  add column if not exists id uuid default extensions.gen_random_uuid(),
  add column if not exists user_id uuid default auth.uid(),
  add column if not exists bpm integer,
  add column if not exists "timestamp" bigint,
  add column if not exists status text,
  add column if not exists "ibiValues" jsonb not null default '[]'::jsonb,
  add column if not exists ibi_values jsonb not null default '[]'::jsonb,
  add column if not exists raw_data jsonb not null default '{}'::jsonb,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

update public.heart_rate
set id = extensions.gen_random_uuid()
where id is null;

insert into public.flowfit_recovery_quarantine (
  source_table,
  reason,
  row_data
)
select 'heart_rate', 'missing user_id', to_jsonb(heart_rate_row)
from public.heart_rate as heart_rate_row
where heart_rate_row.user_id is null;

delete from public.heart_rate
where user_id is null;

insert into public.flowfit_recovery_quarantine (
  source_table,
  reason,
  row_data
)
select 'heart_rate', 'missing timestamp', to_jsonb(heart_rate_row)
from public.heart_rate as heart_rate_row
where heart_rate_row."timestamp" is null;

delete from public.heart_rate
where "timestamp" is null;

update public.heart_rate
set
  "ibiValues" = coalesce("ibiValues", '[]'::jsonb),
  ibi_values = coalesce(ibi_values, '[]'::jsonb),
  raw_data = coalesce(raw_data, '{}'::jsonb),
  created_at = coalesce(created_at, now()),
  updated_at = coalesce(updated_at, now());

alter table public.heart_rate
  alter column id set default extensions.gen_random_uuid(),
  alter column id set not null,
  alter column user_id set default auth.uid(),
  alter column user_id set not null,
  alter column "ibiValues" set default '[]'::jsonb,
  alter column "ibiValues" set not null,
  alter column ibi_values set default '[]'::jsonb,
  alter column ibi_values set not null,
  alter column raw_data set default '{}'::jsonb,
  alter column raw_data set not null,
  alter column created_at set default now(),
  alter column created_at set not null,
  alter column updated_at set default now(),
  alter column updated_at set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'heart_rate_user_id_fkey'
      and conrelid = 'public.heart_rate'::regclass
  ) then
    alter table public.heart_rate
      add constraint heart_rate_user_id_fkey
      foreign key (user_id) references auth.users(id) on delete cascade;
  end if;
end;
$$;

create index if not exists idx_heart_rate_user_id
  on public.heart_rate(user_id);
create index if not exists idx_heart_rate_timestamp
  on public.heart_rate("timestamp" desc);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'heart_rate_bpm_valid'
      and conrelid = 'public.heart_rate'::regclass
  ) then
    alter table public.heart_rate
      add constraint heart_rate_bpm_valid
      check (bpm is null or bpm between 0 and 250) not valid;
  end if;
end;
$$;

drop trigger if exists update_heart_rate_updated_at
  on public.heart_rate;
create trigger update_heart_rate_updated_at
  before update on public.heart_rate
  for each row
  execute function public.update_updated_at_column();

-- ---------------------------------------------------------------------------
-- account deletion requests
-- ---------------------------------------------------------------------------

create table if not exists public.account_deletion_requests (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null,
  user_email text,
  status text not null default 'pending',
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  processor_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint account_deletion_requests_status_valid
    check (status in ('pending', 'processing', 'completed', 'rejected'))
);

alter table public.account_deletion_requests
  add column if not exists id uuid default extensions.gen_random_uuid(),
  add column if not exists user_id uuid,
  add column if not exists user_email text,
  add column if not exists status text not null default 'pending',
  add column if not exists requested_at timestamptz not null default now(),
  add column if not exists processed_at timestamptz,
  add column if not exists processor_notes text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

update public.account_deletion_requests
set id = extensions.gen_random_uuid()
where id is null;

insert into public.flowfit_recovery_quarantine (
  source_table,
  reason,
  row_data
)
select
  'account_deletion_requests',
  'missing user_id',
  to_jsonb(deletion_request_row)
from public.account_deletion_requests as deletion_request_row
where deletion_request_row.user_id is null;

delete from public.account_deletion_requests
where user_id is null;

update public.account_deletion_requests
set
  status = coalesce(status, 'pending'),
  requested_at = coalesce(requested_at, now()),
  created_at = coalesce(created_at, now()),
  updated_at = coalesce(updated_at, now());

alter table public.account_deletion_requests
  alter column id set default extensions.gen_random_uuid(),
  alter column id set not null,
  alter column user_id set not null,
  alter column status set default 'pending',
  alter column status set not null,
  alter column requested_at set default now(),
  alter column requested_at set not null,
  alter column created_at set default now(),
  alter column created_at set not null,
  alter column updated_at set default now(),
  alter column updated_at set not null;

do $$
begin
  alter table public.account_deletion_requests
    drop constraint if exists account_deletion_requests_user_id_fkey;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'account_deletion_requests_status_valid'
      and conrelid = 'public.account_deletion_requests'::regclass
  ) then
    alter table public.account_deletion_requests
      add constraint account_deletion_requests_status_valid
      check (status in ('pending', 'processing', 'completed', 'rejected')) not valid;
  end if;
end;
$$;

create index if not exists idx_account_deletion_requests_user_id
  on public.account_deletion_requests(user_id);
create index if not exists idx_account_deletion_requests_status
  on public.account_deletion_requests(status, requested_at desc);
create unique index if not exists idx_account_deletion_requests_one_pending
  on public.account_deletion_requests(user_id)
  where status = 'pending';

drop trigger if exists update_account_deletion_requests_updated_at
  on public.account_deletion_requests;
create trigger update_account_deletion_requests_updated_at
  before update on public.account_deletion_requests
  for each row
  execute function public.update_updated_at_column();

create or replace function public.request_account_deletion()
returns jsonb
language plpgsql
security invoker
set search_path = public, auth, extensions
as $$
declare
  current_user_id uuid := auth.uid();
  current_email text := nullif(auth.jwt() ->> 'email', '');
  deletion_request_id uuid;
begin
  if current_user_id is null then
    raise exception 'request_account_deletion requires an authenticated user';
  end if;

  -- Runs as the authenticated caller, so deletes remain constrained by RLS.
  -- Auth-account deletion still requires a server-side admin action outside
  -- the Flutter client.
  delete from public.heart_rate where user_id = current_user_id;
  delete from public.workout_sessions where user_id = current_user_id;
  delete from public.buddy_profiles where user_id = current_user_id;
  delete from public.user_profiles where user_id = current_user_id;

  perform set_config('app.flowfit_account_deletion_rpc', '1', true);

  insert into public.account_deletion_requests (
    user_id,
    user_email,
    status,
    requested_at
  )
  values (
    current_user_id,
    current_email,
    'pending',
    now()
  )
  on conflict do nothing;

  select id
    into deletion_request_id
    from public.account_deletion_requests
   where user_id = current_user_id
     and status = 'pending'
   order by requested_at desc
   limit 1;

  if deletion_request_id is null then
    raise exception 'Unable to create account deletion request';
  end if;

  return jsonb_build_object(
    'request_id', deletion_request_id,
    'status', 'pending'
  );
end;
$$;

create or replace function public.has_pending_account_deletion(target_user_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = public
as $$
  select exists (
    select 1
      from public.account_deletion_requests
     where user_id = target_user_id
       and status in ('pending', 'processing')
  );
$$;

-- ---------------------------------------------------------------------------
-- RLS, policies, and Data API privileges
-- ---------------------------------------------------------------------------

alter table public.user_profiles enable row level security;
alter table public.buddy_profiles enable row level security;
alter table public.workout_sessions enable row level security;
alter table public.heart_rate enable row level security;
alter table public.account_deletion_requests enable row level security;
alter table public.flowfit_recovery_quarantine enable row level security;

do $$
declare
  policy_record record;
begin
  for policy_record in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = any (array[
        'user_profiles',
        'buddy_profiles',
        'workout_sessions',
        'heart_rate',
        'account_deletion_requests'
      ])
  loop
    execute format(
      'drop policy if exists %I on %I.%I',
      policy_record.policyname,
      policy_record.schemaname,
      policy_record.tablename
    );
  end loop;
end;
$$;

create policy "Users can view own profile"
  on public.user_profiles
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can insert own profile"
  on public.user_profiles
  for insert
  to authenticated
  with check (
    (select auth.uid()) = user_id
    and not public.has_pending_account_deletion(user_id)
  );

create policy "Users can update own profile"
  on public.user_profiles
  for update
  to authenticated
  using (
    (select auth.uid()) = user_id
    and not public.has_pending_account_deletion(user_id)
  )
  with check (
    (select auth.uid()) = user_id
    and not public.has_pending_account_deletion(user_id)
  );

create policy "Users can delete own profile"
  on public.user_profiles
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can view own buddy profile"
  on public.buddy_profiles
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can insert own buddy profile"
  on public.buddy_profiles
  for insert
  to authenticated
  with check (
    (select auth.uid()) = user_id
    and not public.has_pending_account_deletion(user_id)
  );

create policy "Users can update own buddy profile"
  on public.buddy_profiles
  for update
  to authenticated
  using (
    (select auth.uid()) = user_id
    and not public.has_pending_account_deletion(user_id)
  )
  with check (
    (select auth.uid()) = user_id
    and not public.has_pending_account_deletion(user_id)
  );

create policy "Users can delete own buddy profile"
  on public.buddy_profiles
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can view own workout sessions"
  on public.workout_sessions
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can insert own workout sessions"
  on public.workout_sessions
  for insert
  to authenticated
  with check (
    (select auth.uid()) = user_id
    and not public.has_pending_account_deletion(user_id)
  );

create policy "Users can update own workout sessions"
  on public.workout_sessions
  for update
  to authenticated
  using (
    (select auth.uid()) = user_id
    and not public.has_pending_account_deletion(user_id)
  )
  with check (
    (select auth.uid()) = user_id
    and not public.has_pending_account_deletion(user_id)
  );

create policy "Users can delete own workout sessions"
  on public.workout_sessions
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can view own heart rate"
  on public.heart_rate
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can insert own heart rate"
  on public.heart_rate
  for insert
  to authenticated
  with check (
    (select auth.uid()) = user_id
    and not public.has_pending_account_deletion(user_id)
  );

create policy "Users can update own heart rate"
  on public.heart_rate
  for update
  to authenticated
  using (
    (select auth.uid()) = user_id
    and not public.has_pending_account_deletion(user_id)
  )
  with check (
    (select auth.uid()) = user_id
    and not public.has_pending_account_deletion(user_id)
  );

create policy "Users can delete own heart rate"
  on public.heart_rate
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can view own account deletion requests"
  on public.account_deletion_requests
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Deletion RPC can create own pending account deletion requests"
  on public.account_deletion_requests
  for insert
  to authenticated
  with check (
    (select auth.uid()) = user_id
    and status = 'pending'
    and processed_at is null
    and processor_notes is null
    and coalesce(current_setting('app.flowfit_account_deletion_rpc', true), '') = '1'
  );

alter default privileges for role postgres in schema public
  revoke select, insert, update, delete on tables
  from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke execute on functions
  from public, anon, authenticated, service_role;

revoke all on schema public from public;
grant usage on schema public to anon, authenticated, service_role;
grant usage on schema extensions to authenticated, service_role;
revoke all
  on public.user_profiles,
     public.buddy_profiles,
     public.workout_sessions,
     public.heart_rate,
     public.account_deletion_requests,
     public.flowfit_recovery_quarantine
  from public, anon, authenticated, service_role;
grant select, insert, update, delete
  on public.user_profiles,
     public.buddy_profiles,
     public.workout_sessions,
     public.heart_rate
  to authenticated;
grant select, insert, update, delete
  on public.user_profiles,
     public.buddy_profiles,
     public.workout_sessions,
     public.heart_rate
  to service_role;
grant select
  on public.account_deletion_requests
  to authenticated;
grant insert (user_id, user_email, status, requested_at)
  on public.account_deletion_requests
  to authenticated;
grant select, update
  on public.account_deletion_requests
  to service_role;
grant select, delete
  on public.flowfit_recovery_quarantine
  to service_role;
revoke all on function public.update_updated_at_column()
  from public, anon, authenticated;
revoke all on function public.has_pending_account_deletion(uuid)
  from public, anon, authenticated, service_role;
revoke all on function public.request_account_deletion()
  from public, anon, authenticated, service_role;
grant execute on function public.has_pending_account_deletion(uuid)
  to authenticated, service_role;
grant execute on function public.request_account_deletion() to authenticated;

comment on table public.user_profiles is
  'FlowFit user profile, survey, and Buddy onboarding flags.';
comment on table public.buddy_profiles is
  'FlowFit Buddy companion customization and progression state.';
comment on table public.workout_sessions is
  'FlowFit workout sessions for running, walking, and resistance flows.';
comment on table public.heart_rate is
  'Compatibility table for legacy heart rate sync helpers.';
comment on table public.account_deletion_requests is
  'User-initiated FlowFit account deletion requests for privileged backend/admin processing.';
comment on table public.flowfit_recovery_quarantine is
  'Service-role-only quarantine for invalid legacy rows copied before recovery migration cleanup deletes.';
comment on function public.request_account_deletion() is
  'Uses caller RLS to delete app-owned public data for the signed-in user and queues auth-account deletion for admin processing.';
comment on function public.has_pending_account_deletion(uuid) is
  'RLS helper that blocks authenticated app-data writes after account deletion is pending or processing.';

commit;
