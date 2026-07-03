-- Add an app-owned support request queue.
-- This keeps support submission inside FlowFit instead of depending on
-- mailbox scraping for product-level support evidence.

begin;

create table if not exists public.support_requests (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null,
  user_email text,
  category text not null default 'support',
  subject text not null,
  message text not null,
  status text not null default 'open',
  app_surface text not null default 'help_support',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint support_requests_category_valid
    check (category in ('support', 'bug', 'account', 'privacy')),
  constraint support_requests_status_valid
    check (status in ('open', 'in_review', 'resolved', 'closed')),
  constraint support_requests_subject_valid
    check (char_length(btrim(subject)) between 3 and 160),
  constraint support_requests_message_valid
    check (char_length(btrim(message)) between 10 and 4000)
);

alter table public.support_requests
  add column if not exists id uuid default extensions.gen_random_uuid(),
  add column if not exists user_id uuid,
  add column if not exists user_email text,
  add column if not exists category text not null default 'support',
  add column if not exists subject text,
  add column if not exists message text,
  add column if not exists status text not null default 'open',
  add column if not exists app_surface text not null default 'help_support',
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

update public.support_requests
set id = extensions.gen_random_uuid()
where id is null;

alter table public.support_requests
  alter column id set default extensions.gen_random_uuid(),
  alter column id set not null,
  alter column user_id set not null,
  alter column category set default 'support',
  alter column category set not null,
  alter column subject set not null,
  alter column message set not null,
  alter column status set default 'open',
  alter column status set not null,
  alter column app_surface set default 'help_support',
  alter column app_surface set not null,
  alter column created_at set default now(),
  alter column created_at set not null,
  alter column updated_at set default now(),
  alter column updated_at set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'support_requests_id_unique'
      and conrelid = 'public.support_requests'::regclass
  ) then
    alter table public.support_requests
      add constraint support_requests_id_unique unique (id);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'support_requests_category_valid'
      and conrelid = 'public.support_requests'::regclass
  ) then
    alter table public.support_requests
      add constraint support_requests_category_valid
      check (category in ('support', 'bug', 'account', 'privacy')) not valid;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'support_requests_status_valid'
      and conrelid = 'public.support_requests'::regclass
  ) then
    alter table public.support_requests
      add constraint support_requests_status_valid
      check (status in ('open', 'in_review', 'resolved', 'closed')) not valid;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'support_requests_subject_valid'
      and conrelid = 'public.support_requests'::regclass
  ) then
    alter table public.support_requests
      add constraint support_requests_subject_valid
      check (char_length(btrim(subject)) between 3 and 160) not valid;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'support_requests_message_valid'
      and conrelid = 'public.support_requests'::regclass
  ) then
    alter table public.support_requests
      add constraint support_requests_message_valid
      check (char_length(btrim(message)) between 10 and 4000) not valid;
  end if;
end;
$$;

create index if not exists idx_support_requests_user_id
  on public.support_requests(user_id);
create index if not exists idx_support_requests_status_created_at
  on public.support_requests(status, created_at desc);
create index if not exists idx_support_requests_category_created_at
  on public.support_requests(category, created_at desc);

drop trigger if exists update_support_requests_updated_at
  on public.support_requests;
create trigger update_support_requests_updated_at
  before update on public.support_requests
  for each row
  execute function public.update_updated_at_column();

alter table public.support_requests enable row level security;

do $$
declare
  policy_record record;
begin
  for policy_record in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'support_requests'
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

create policy "Users can view own support requests"
  on public.support_requests
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can insert own support requests"
  on public.support_requests
  for insert
  to authenticated
  with check (
    (select auth.uid()) = user_id
    and status = 'open'
    and not public.has_pending_account_deletion(user_id)
  );

create policy "Users can delete own support requests"
  on public.support_requests
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

revoke all
  on public.support_requests
  from public, anon, authenticated, service_role;
grant select, insert, delete
  on public.support_requests
  to authenticated;
grant select, update, delete
  on public.support_requests
  to service_role;

comment on table public.support_requests is
  'Authenticated in-app FlowFit support and bug requests for service-role/admin processing.';

commit;
