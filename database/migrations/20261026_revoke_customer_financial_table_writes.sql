-- Revoke inherited table grants, then restore only intended customer access.
begin;
revoke all on public.bank_accounts from public, anon, authenticated;
revoke all on public.bank_transactions from public, anon, authenticated;
revoke all on public.profiles from public, anon, authenticated;
revoke all on public.ledger_entries from public, anon, authenticated;
grant select on public.bank_accounts to authenticated;
grant select on public.bank_transactions to authenticated;
grant select on public.profiles to authenticated;
grant update (display_name, phone) on public.profiles to authenticated;
grant execute on function public.get_my_account_balances() to authenticated;
revoke all on function public.get_my_account_balances() from public, anon;
commit;
