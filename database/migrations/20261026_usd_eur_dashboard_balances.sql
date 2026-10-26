-- Applied to the dedicated PLEDGE BANK Supabase project on 2026-10-26.
-- Restricts every banking record to USD/EUR and exposes only the signed-in user's
-- posted-ledger balances through a read-only security-definer RPC.
begin;
alter table public.bank_accounts alter column currency set default 'USD';
alter table public.bank_transactions alter column currency set default 'USD';
alter table public.ledger_entries alter column currency set default 'USD';

alter table public.bank_accounts drop constraint if exists bank_accounts_currency_supported;
alter table public.bank_accounts add constraint bank_accounts_currency_supported check (currency in ('USD','EUR')) not valid;
alter table public.bank_accounts validate constraint bank_accounts_currency_supported;

alter table public.bank_transactions drop constraint if exists bank_transactions_currency_supported;
alter table public.bank_transactions add constraint bank_transactions_currency_supported check (currency in ('USD','EUR')) not valid;
alter table public.bank_transactions validate constraint bank_transactions_currency_supported;

alter table public.ledger_entries drop constraint if exists ledger_entries_currency_supported;
alter table public.ledger_entries add constraint ledger_entries_currency_supported check (currency in ('USD','EUR')) not valid;
alter table public.ledger_entries validate constraint ledger_entries_currency_supported;

create or replace function public.get_my_account_balances()
returns table (account_id uuid, currency char(3), balance numeric)
language sql stable security definer set search_path = ''
as $function$
  select a.id, a.currency,
         coalesce(sum(case le.entry_type when 'credit' then le.amount else -le.amount end), 0)::numeric(20,2)
  from public.bank_accounts as a
  left join public.ledger_entries as le
    on le.account_id = a.id and le.currency = a.currency
   and exists (select 1 from public.bank_transactions as t
               where t.id = le.transaction_id and t.status = 'posted' and t.currency = le.currency)
  where a.owner_id = auth.uid()
  group by a.id, a.currency;
$function$;
revoke all on function public.get_my_account_balances() from public, anon;
grant execute on function public.get_my_account_balances() to authenticated;
commit;
