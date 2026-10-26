-- Tighten the balance aggregation so each ledger line is matched to its
-- own source transaction and account, in addition to the owner filter.
create or replace function public.get_my_account_balances()
returns table (account_id uuid, currency char(3), balance numeric)
language sql
stable
security definer
set search_path = ''
as $function$
  select a.id,
         a.currency,
         coalesce(sum(case le.entry_type when 'credit' then le.amount else -le.amount end), 0)::numeric(20,2) as balance
  from public.bank_accounts as a
  left join public.ledger_entries as le
    on le.account_id = a.id
   and le.currency = a.currency
   and exists (
     select 1 from public.bank_transactions as t
     where t.id = le.transaction_id
       and t.account_id = le.account_id
       and t.status = 'posted'
       and t.currency = le.currency
   )
  where a.owner_id = auth.uid()
  group by a.id, a.currency;
$function$;
revoke all on function public.get_my_account_balances() from public, anon;
grant execute on function public.get_my_account_balances() to authenticated;
