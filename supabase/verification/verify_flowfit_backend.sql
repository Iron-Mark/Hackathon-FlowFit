-- FlowFit backend verification.
-- Read-only query intended for Supabase MCP execute_sql, the dashboard SQL
-- editor, or `supabase db query --file`.

with
expected_tables(table_name) as (
  values
    ('user_profiles'),
    ('buddy_profiles'),
    ('workout_sessions'),
    ('heart_rate'),
    ('account_deletion_requests'),
    ('flowfit_recovery_quarantine')
),
expected_id_constraints(table_name, column_name) as (
  values
    ('user_profiles', 'id'),
    ('buddy_profiles', 'id'),
    ('workout_sessions', 'id'),
    ('heart_rate', 'id'),
    ('account_deletion_requests', 'id'),
    ('flowfit_recovery_quarantine', 'id')
),
expected_columns(table_name, column_name) as (
  values
    ('user_profiles', 'id'),
    ('user_profiles', 'user_id'),
    ('user_profiles', 'full_name'),
    ('user_profiles', 'age'),
    ('user_profiles', 'gender'),
    ('user_profiles', 'weight'),
    ('user_profiles', 'height'),
    ('user_profiles', 'height_unit'),
    ('user_profiles', 'weight_unit'),
    ('user_profiles', 'activity_level'),
    ('user_profiles', 'goals'),
    ('user_profiles', 'wellness_goals'),
    ('user_profiles', 'notifications_enabled'),
    ('user_profiles', 'daily_calorie_target'),
    ('user_profiles', 'daily_steps_target'),
    ('user_profiles', 'daily_active_minutes_target'),
    ('user_profiles', 'daily_water_target'),
    ('user_profiles', 'profile_image_url'),
    ('user_profiles', 'nickname'),
    ('user_profiles', 'is_kids_mode'),
    ('user_profiles', 'survey_completed'),
    ('user_profiles', 'created_at'),
    ('user_profiles', 'updated_at'),
    ('buddy_profiles', 'id'),
    ('buddy_profiles', 'user_id'),
    ('buddy_profiles', 'name'),
    ('buddy_profiles', 'color'),
    ('buddy_profiles', 'level'),
    ('buddy_profiles', 'xp'),
    ('buddy_profiles', 'unlocked_colors'),
    ('buddy_profiles', 'accessories'),
    ('buddy_profiles', 'created_at'),
    ('buddy_profiles', 'updated_at'),
    ('workout_sessions', 'id'),
    ('workout_sessions', 'user_id'),
    ('workout_sessions', 'workout_type'),
    ('workout_sessions', 'workout_subtype'),
    ('workout_sessions', 'start_time'),
    ('workout_sessions', 'end_time'),
    ('workout_sessions', 'duration_seconds'),
    ('workout_sessions', 'pre_workout_mood'),
    ('workout_sessions', 'pre_workout_mood_emoji'),
    ('workout_sessions', 'post_workout_mood'),
    ('workout_sessions', 'post_workout_mood_emoji'),
    ('workout_sessions', 'current_distance'),
    ('workout_sessions', 'distance_km'),
    ('workout_sessions', 'steps'),
    ('workout_sessions', 'exercises_completed'),
    ('workout_sessions', 'status'),
    ('workout_sessions', 'created_at'),
    ('workout_sessions', 'updated_at'),
    ('heart_rate', 'id'),
    ('heart_rate', 'user_id'),
    ('heart_rate', 'bpm'),
    ('heart_rate', 'timestamp'),
    ('heart_rate', 'status'),
    ('heart_rate', 'ibiValues'),
    ('heart_rate', 'ibi_values'),
    ('heart_rate', 'raw_data'),
    ('heart_rate', 'created_at'),
    ('heart_rate', 'updated_at'),
    ('account_deletion_requests', 'id'),
    ('account_deletion_requests', 'user_id'),
    ('account_deletion_requests', 'user_email'),
    ('account_deletion_requests', 'status'),
    ('account_deletion_requests', 'requested_at'),
    ('account_deletion_requests', 'processed_at'),
    ('account_deletion_requests', 'processor_notes'),
    ('account_deletion_requests', 'created_at'),
    ('account_deletion_requests', 'updated_at'),
    ('flowfit_recovery_quarantine', 'id'),
    ('flowfit_recovery_quarantine', 'source_table'),
    ('flowfit_recovery_quarantine', 'reason'),
    ('flowfit_recovery_quarantine', 'row_data'),
    ('flowfit_recovery_quarantine', 'quarantined_at')
),
app_tables(table_name) as (
  values
    ('user_profiles'),
    ('buddy_profiles'),
    ('workout_sessions'),
    ('heart_rate')
),
expected_policies(table_name, command_name) as (
  select table_name, command_name
  from app_tables
  cross join (
    values ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE')
  ) as commands(command_name)
  union all
  values
    ('account_deletion_requests', 'SELECT'),
    ('account_deletion_requests', 'INSERT')
),
expected_table_grants(role_name, table_name, privilege_type) as (
  select role_name, table_name, privilege_type
  from (
    values ('authenticated'), ('service_role')
  ) as roles(role_name)
  cross join app_tables
  cross join (
    values ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE')
  ) as privileges(privilege_type)
  union all
  values
    ('authenticated', 'account_deletion_requests', 'SELECT'),
    ('service_role', 'account_deletion_requests', 'SELECT'),
    ('service_role', 'account_deletion_requests', 'UPDATE'),
    ('service_role', 'flowfit_recovery_quarantine', 'SELECT'),
    ('service_role', 'flowfit_recovery_quarantine', 'DELETE')
),
expected_column_grants(role_name, table_name, column_name, privilege_type) as (
  values
    ('authenticated', 'account_deletion_requests', 'user_id', 'INSERT'),
    ('authenticated', 'account_deletion_requests', 'user_email', 'INSERT'),
    ('authenticated', 'account_deletion_requests', 'status', 'INSERT'),
    ('authenticated', 'account_deletion_requests', 'requested_at', 'INSERT')
),
expected_triggers(table_name, trigger_name) as (
  values
    ('user_profiles', 'update_user_profiles_updated_at'),
    ('buddy_profiles', 'update_buddy_profiles_updated_at'),
    ('workout_sessions', 'update_workout_sessions_updated_at'),
    ('heart_rate', 'update_heart_rate_updated_at'),
    ('account_deletion_requests', 'update_account_deletion_requests_updated_at')
),
expected_indexes(index_name) as (
  values
    ('user_profiles_user_id_unique'),
    ('buddy_profiles_user_id_unique'),
    ('idx_workout_sessions_user_id'),
    ('idx_workout_sessions_user_start_time_desc'),
    ('idx_heart_rate_user_id'),
    ('idx_account_deletion_requests_one_pending')
),
expected_constraints(table_name, constraint_name) as (
  values
    (
      'workout_sessions',
      'workout_sessions_type_specific_fields_valid'
    )
),
missing_tables as (
  select e.table_name
  from expected_tables e
  left join information_schema.tables t
    on t.table_schema = 'public'
   and t.table_name = e.table_name
  where t.table_name is null
),
missing_columns as (
  select e.table_name, e.column_name
  from expected_columns e
  left join information_schema.columns c
    on c.table_schema = 'public'
   and c.table_name = e.table_name
   and c.column_name = e.column_name
  where c.column_name is null
),
missing_id_constraints as (
  select e.table_name, e.column_name
  from expected_id_constraints e
  where not exists (
    select 1
    from pg_constraint con
    join pg_class c on c.oid = con.conrelid
    join pg_namespace n on n.oid = c.relnamespace
    join pg_attribute a
      on a.attrelid = c.oid
     and a.attname = e.column_name
     and not a.attisdropped
    where n.nspname = 'public'
      and c.relname = e.table_name
      and con.contype in ('p', 'u')
      and con.conkey = array[a.attnum]::smallint[]
  )
),
missing_id_not_null as (
  select e.table_name, e.column_name
  from expected_id_constraints e
  where not exists (
    select 1
    from information_schema.columns c
    where c.table_schema = 'public'
      and c.table_name = e.table_name
      and c.column_name = e.column_name
      and c.is_nullable = 'NO'
  )
),
missing_rls as (
  select e.table_name
  from expected_tables e
  where not exists (
    select 1
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = e.table_name
      and c.relrowsecurity
  )
),
missing_policies as (
  select e.table_name, e.command_name
  from expected_policies e
  where not exists (
    select 1
    from pg_policies p
    where p.schemaname = 'public'
      and p.tablename = e.table_name
      and p.cmd = e.command_name
      and 'authenticated' = any(p.roles)
  )
),
missing_table_grants as (
  select e.role_name, e.table_name, e.privilege_type
  from expected_table_grants e
  where not exists (
    select 1
    from information_schema.role_table_grants g
    where g.table_schema = 'public'
      and g.grantee = e.role_name
      and g.table_name = e.table_name
      and g.privilege_type = e.privilege_type
  )
),
missing_column_grants as (
  select e.role_name, e.table_name, e.column_name, e.privilege_type
  from expected_column_grants e
  where not exists (
    select 1
    from information_schema.column_privileges g
    where g.table_schema = 'public'
      and g.grantee = e.role_name
      and g.table_name = e.table_name
      and g.column_name = e.column_name
      and g.privilege_type = e.privilege_type
  )
),
unexpected_anon_table_grants as (
  select g.table_name, g.privilege_type
  from information_schema.role_table_grants g
  join expected_tables e on e.table_name = g.table_name
  where g.table_schema = 'public'
    and g.grantee = 'anon'
),
missing_triggers as (
  select e.table_name, e.trigger_name
  from expected_triggers e
  where not exists (
    select 1
    from information_schema.triggers t
    where t.event_object_schema = 'public'
      and t.event_object_table = e.table_name
      and t.trigger_name = e.trigger_name
  )
),
missing_indexes as (
  select e.index_name
  from expected_indexes e
  where not exists (
    select 1
    from pg_indexes i
    where i.schemaname = 'public'
      and i.indexname = e.index_name
  )
),
missing_constraints as (
  select e.table_name, e.constraint_name
  from expected_constraints e
  where not exists (
    select 1
    from pg_constraint con
    join pg_class c on c.oid = con.conrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = e.table_name
      and con.conname = e.constraint_name
  )
),
missing_extension_usage as (
  select role_name
  from (values ('authenticated'), ('service_role')) as roles(role_name)
  where not exists (
    select 1
    from pg_namespace n
    where n.nspname = 'extensions'
      and has_schema_privilege(roles.role_name, n.oid, 'USAGE')
  )
),
public_security_definer_functions as (
  select p.proname
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.prosecdef
),
flowfit_backend_verification as (
  select
    'required public tables' as check_name,
    case when count(*) = 0 then 'pass' else 'fail' end as status,
    case
      when count(*) = 0 then 'all expected public tables exist'
      else 'missing: ' || string_agg(table_name, ', ' order by table_name)
    end as detail
  from missing_tables
  union all
  select
    'required public columns',
    case when count(*) = 0 then 'pass' else 'fail' end,
    case
      when count(*) = 0 then 'all expected columns exist'
      else 'missing: ' || string_agg(table_name || '.' || column_name, ', ' order by table_name, column_name)
    end
  from missing_columns
  union all
  select
    'id uniqueness constraints',
    case when count(*) = 0 then 'pass' else 'fail' end,
    case
      when count(*) = 0 then 'every managed id column is primary-keyed or unique'
      else 'missing: ' || string_agg(table_name || '.' || column_name, ', ' order by table_name)
    end
  from missing_id_constraints
  union all
  select
    'id not-null constraints',
    case when count(*) = 0 then 'pass' else 'fail' end,
    case
      when count(*) = 0 then 'every managed id column is not nullable'
      else 'missing: ' || string_agg(table_name || '.' || column_name, ', ' order by table_name)
    end
  from missing_id_not_null
  union all
  select
    'row level security enabled',
    case when count(*) = 0 then 'pass' else 'fail' end,
    case
      when count(*) = 0 then 'rls is enabled on every managed table'
      else 'missing rls: ' || string_agg(table_name, ', ' order by table_name)
    end
  from missing_rls
  union all
  select
    'authenticated rls policies',
    case when count(*) = 0 then 'pass' else 'fail' end,
    case
      when count(*) = 0 then 'expected authenticated policies exist'
      else 'missing: ' || string_agg(table_name || ':' || command_name, ', ' order by table_name, command_name)
    end
  from missing_policies
  union all
  select
    'table grants for data api',
    case when count(*) = 0 then 'pass' else 'fail' end,
    case
      when count(*) = 0 then 'expected table grants exist'
      else 'missing: ' || string_agg(role_name || ':' || table_name || ':' || privilege_type, ', ' order by role_name, table_name, privilege_type)
    end
  from missing_table_grants
  union all
  select
    'column-scoped deletion queue grants',
    case when count(*) = 0 then 'pass' else 'fail' end,
    case
      when count(*) = 0 then 'authenticated insert grant is column-scoped for deletion queue creation'
      else 'missing: ' || string_agg(role_name || ':' || table_name || '.' || column_name || ':' || privilege_type, ', ' order by role_name, table_name, column_name)
    end
  from missing_column_grants
  union all
  select
    'anon table grants absent',
    case when count(*) = 0 then 'pass' else 'fail' end,
    case
      when count(*) = 0 then 'anon has no direct table privileges on managed public tables'
      else 'unexpected: ' || string_agg(table_name || ':' || privilege_type, ', ' order by table_name, privilege_type)
    end
  from unexpected_anon_table_grants
  union all
  select
    'updated_at triggers',
    case when count(*) = 0 then 'pass' else 'fail' end,
    case
      when count(*) = 0 then 'updated_at triggers exist on managed mutable tables'
      else 'missing: ' || string_agg(table_name || ':' || trigger_name, ', ' order by table_name)
    end
  from missing_triggers
  union all
  select
    'required indexes',
    case when count(*) = 0 then 'pass' else 'fail' end,
    case
      when count(*) = 0 then 'expected lookup and uniqueness indexes exist'
      else 'missing: ' || string_agg(index_name, ', ' order by index_name)
    end
  from missing_indexes
  union all
  select
    'required check constraints',
    case when count(*) = 0 then 'pass' else 'fail' end,
    case
      when count(*) = 0 then 'expected check constraints exist'
      else 'missing: ' || string_agg(table_name || ':' || constraint_name, ', ' order by table_name, constraint_name)
    end
  from missing_constraints
  union all
  select
    'extensions schema usage',
    case when count(*) = 0 then 'pass' else 'fail' end,
    case
      when count(*) = 0 then 'runtime roles can use extension-backed uuid defaults'
      else 'missing usage grant: ' || string_agg(role_name, ', ' order by role_name)
    end
  from missing_extension_usage
  union all
  select
    'public functions are security invoker',
    case when count(*) = 0 then 'pass' else 'fail' end,
    case
      when count(*) = 0 then 'no public security definer functions found'
      else 'security definer: ' || string_agg(proname, ', ' order by proname)
    end
  from public_security_definer_functions
  union all
  select
    'request_account_deletion rpc exists',
    case
      when exists (
        select 1
        from pg_proc p
        join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'public'
          and p.proname = 'request_account_deletion'
          and p.prosecdef = false
      ) then 'pass' else 'fail'
    end,
    'request_account_deletion must exist and remain security invoker'
  union all
  select
    'has_pending_account_deletion helper exists',
    case
      when exists (
        select 1
        from pg_proc p
        join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'public'
          and p.proname = 'has_pending_account_deletion'
          and p.prosecdef = false
      ) then 'pass' else 'fail'
    end,
    'pending-deletion rls helper must exist and remain security invoker'
  union all
  select
    'account deletion rpc execute grants',
    case
      when exists (
        select 1
        from information_schema.routine_privileges
        where routine_schema = 'public'
          and routine_name = 'request_account_deletion'
          and grantee = 'authenticated'
          and privilege_type = 'EXECUTE'
      )
      and not exists (
        select 1
        from information_schema.routine_privileges
        where routine_schema = 'public'
          and routine_name = 'request_account_deletion'
          and grantee = 'anon'
          and privilege_type = 'EXECUTE'
      ) then 'pass' else 'fail'
    end,
    'authenticated can execute request_account_deletion and anon cannot'
  union all
  select
    'updated_at helper execute grants absent',
    case
      when not exists (
        select 1
        from information_schema.routine_privileges
        where routine_schema = 'public'
          and routine_name = 'update_updated_at_column'
          and grantee in ('anon', 'authenticated')
          and privilege_type = 'EXECUTE'
      ) then 'pass' else 'fail'
    end,
    'trigger helper should not be directly executable by client roles'
  union all
  select
    'deletion queue does not cascade with auth user',
    case
      when not exists (
        select 1
        from pg_constraint con
        join pg_class c on c.oid = con.conrelid
        join pg_namespace n on n.oid = c.relnamespace
        where n.nspname = 'public'
          and c.relname = 'account_deletion_requests'
          and con.conname = 'account_deletion_requests_user_id_fkey'
      ) then 'pass' else 'fail'
    end,
    'account deletion queue must survive later auth.users deletion for admin processing'
)
select check_name, status, detail
from flowfit_backend_verification
order by
  case status
    when 'fail' then 0
    when 'warn' then 1
    else 2
  end,
  check_name;
