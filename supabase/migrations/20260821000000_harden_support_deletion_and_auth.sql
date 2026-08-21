-- Harden support-request integrity, purge support rows on account deletion,
-- and delete the caller's auth user from a private security-definer helper.
-- public.request_account_deletion remains SECURITY INVOKER so app-table
-- deletes stay constrained by RLS.

begin;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated, service_role;
grant usage on schema private to authenticated, service_role;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'support_requests_user_id_fkey'
      and conrelid = 'public.support_requests'::regclass
  ) then
    alter table public.support_requests
      add constraint support_requests_user_id_fkey
      foreign key (user_id) references auth.users(id) on delete cascade;
  end if;
end;
$$;

create or replace function public.normalize_support_request_row()
returns trigger
language plpgsql
security invoker
set search_path = public, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'support request requires an authenticated user';
  end if;

  new.user_id := auth.uid();
  new.user_email := nullif(auth.jwt() ->> 'email', '');
  new.status := 'open';
  if new.app_surface is null or btrim(new.app_surface) = '' then
    new.app_surface := 'help_support';
  end if;
  return new;
end;
$$;

drop trigger if exists normalize_support_request_row
  on public.support_requests;
create trigger normalize_support_request_row
  before insert on public.support_requests
  for each row
  execute function public.normalize_support_request_row();

revoke all on function public.normalize_support_request_row()
  from public, anon, authenticated, service_role;

drop policy if exists "Users can insert own support requests"
  on public.support_requests;

create policy "Users can insert own support requests"
  on public.support_requests
  for insert
  to authenticated
  with check (
    (select auth.uid()) = user_id
    and status = 'open'
    and user_email is not distinct from nullif((select auth.jwt() ->> 'email'), '')
    and not public.has_pending_account_deletion(user_id)
  );

alter table public.support_requests force row level security;

create or replace function private.delete_own_auth_user()
returns void
language plpgsql
security definer
set search_path = auth
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'delete_own_auth_user requires an authenticated user';
  end if;

  delete from auth.users where id = uid;
end;
$$;

revoke all on function private.delete_own_auth_user()
  from public, anon, authenticated, service_role;
grant execute on function private.delete_own_auth_user() to authenticated;

create or replace function public.request_account_deletion()
returns jsonb
language plpgsql
security invoker
set search_path = public, auth, extensions, private
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
  delete from public.support_requests where user_id = current_user_id;
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

  perform private.delete_own_auth_user();

  return jsonb_build_object(
    'request_id', deletion_request_id,
    'status', 'pending'
  );
end;
$$;

comment on function public.request_account_deletion() is
  'Uses caller RLS to delete app-owned public data including support requests, queues an audit row, then deletes the signed-in auth user.';
comment on function private.delete_own_auth_user() is
  'SECURITY DEFINER helper that deletes only auth.users.id = auth.uid(). Kept out of the public schema.';
comment on function public.normalize_support_request_row() is
  'Forces support_requests.user_id and user_email from the JWT so clients cannot spoof another mailbox.';

commit;
