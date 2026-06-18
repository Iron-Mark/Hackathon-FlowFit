-- Resolve Supabase advisor findings from the live recovery project.

drop policy if exists "Deletion RPC can create own pending account deletion requests"
  on public.account_deletion_requests;

create policy "Deletion RPC can create own pending account deletion requests"
  on public.account_deletion_requests
  for insert
  to authenticated
  with check (
    (select auth.uid()) = user_id
    and status = 'pending'
    and processed_at is null
    and processor_notes is null
    and coalesce((select current_setting('app.flowfit_account_deletion_rpc', true)), '') = '1'
  );

drop policy if exists "No client access to recovery quarantine"
  on public.flowfit_recovery_quarantine;

create policy "No client access to recovery quarantine"
  on public.flowfit_recovery_quarantine
  for all
  to public
  using (false)
  with check (false);
