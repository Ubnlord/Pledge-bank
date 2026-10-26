-- PLEDGE BANK database foundation
-- Apply only to a dedicated PLEDGE BANK Supabase project after review.
-- This file is a schema draft; it has NOT been applied to any live database.
-- No client role can create accounts or mutate financial records directly.
begin;

create extension if not exists pgcrypto;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_display_name_length check (char_length(display_name) <= 120),
  constraint profiles_phone_length check (phone is null or char_length(phone) <= 32)
);

do $$ begin
  create type public.bank_account_type as enum ('current', 'savings');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.bank_account_status as enum ('pending', 'active', 'restricted', 'closed');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.bank_transaction_type as enum ('deposit', 'withdrawal', 'transfer', 'bill_payment', 'fee', 'adjustment');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.bank_transaction_status as enum ('pending', 'processing', 'posted', 'failed', 'reversed', 'cancelled');
exception when duplicate_object then null;
end $$;

create table if not exists public.bank_accounts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete restrict,
  account_number text not null unique,
  account_type public.bank_account_type not null default 'current',
  currency char(3) not null default 'NGN',
  status public.bank_account_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bank_accounts_number_format check (account_number ~ '^[0-9]{10,20}$'),
  constraint bank_accounts_currency_uppercase check (currency ~ '^[A-Z]{3}$')
);

-- Transaction metadata only. Amounts are immutable records, not a source of balance truth.
-- A posted transaction must have balanced ledger entries before the posting workflow can be enabled.
create table if not exists public.bank_transactions (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.bank_accounts(id) on delete restrict,
  initiated_by uuid references auth.users(id) on delete set null,
  transaction_type public.bank_transaction_type not null,
  status public.bank_transaction_status not null default 'pending',
  amount numeric(20,2) not null,
  currency char(3) not null default 'NGN',
  reference text not null unique,
  description text,
  idempotency_key text,
  created_at timestamptz not null default now(),
  posted_at timestamptz,
  constraint bank_transactions_amount_positive check (amount > 0),
  constraint bank_transactions_currency_uppercase check (currency ~ '^[A-Z]{3}$'),
  constraint bank_transactions_reference_length check (char_length(reference) between 8 and 100),
  constraint bank_transactions_description_length check (description is null or char_length(description) <= 240),
  constraint bank_transactions_idempotency_length check (idempotency_key is null or char_length(idempotency_key) between 8 and 160)
);

create unique index if not exists bank_transactions_account_idempotency_unique
  on public.bank_transactions(account_id, idempotency_key)
  where idempotency_key is not null;
create index if not exists bank_accounts_owner_created_idx
  on public.bank_accounts(owner_id, created_at desc);
create index if not exists bank_transactions_account_created_idx
  on public.bank_transactions(account_id, created_at desc);

-- Append-oriented ledger lines. Access is deliberately withheld from browser roles.
create table if not exists public.ledger_entries (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references public.bank_transactions(id) on delete restrict,
  account_id uuid not null references public.bank_accounts(id) on delete restrict,
  entry_type text not null check (entry_type in ('debit', 'credit')),
  amount numeric(20,2) not null check (amount > 0),
  currency char(3) not null default 'NGN',
  created_at timestamptz not null default now(),
  constraint ledger_entries_currency_uppercase check (currency ~ '^[A-Z]{3}$')
);
create index if not exists ledger_entries_account_created_idx
  on public.ledger_entries(account_id, created_at desc);
create index if not exists ledger_entries_transaction_idx
  on public.ledger_entries(transaction_id);

create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;
revoke all on function private.set_updated_at() from public, anon, authenticated;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function private.set_updated_at();

drop trigger if exists bank_accounts_set_updated_at on public.bank_accounts;
create trigger bank_accounts_set_updated_at
before update on public.bank_accounts
for each row execute function private.set_updated_at();

-- Create a minimal profile after an Auth user is created. User-editable metadata
-- is only used as a display name, never as an authorization or role claim.
create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    left(coalesce(new.raw_user_meta_data ->> 'display_name', ''), 120)
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
revoke all on function private.handle_new_auth_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute function private.handle_new_auth_user();

alter table public.profiles enable row level security;
alter table public.bank_accounts enable row level security;
alter table public.bank_transactions enable row level security;
alter table public.ledger_entries enable row level security;

-- Customers can read and update only their own basic profile.
drop policy if exists "profile_read_self" on public.profiles;
create policy "profile_read_self" on public.profiles
for select to authenticated
using ((select auth.uid()) = id);

drop policy if exists "profile_update_self" on public.profiles;
create policy "profile_update_self" on public.profiles
for update to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

-- Customer browser sessions may only read their own account records.
-- Account creation, account number assignment, status changes, and all balance
-- changes must be performed by a trusted, audited server-side workflow.
drop policy if exists "account_read_owner" on public.bank_accounts;
create policy "account_read_owner" on public.bank_accounts
for select to authenticated
using ((select auth.uid()) = owner_id);

-- Transaction history is readable only when the linked account belongs to the caller.
drop policy if exists "transaction_read_account_owner" on public.bank_transactions;
create policy "transaction_read_account_owner" on public.bank_transactions
for select to authenticated
using (
  exists (
    select 1
    from public.bank_accounts a
    where a.id = bank_transactions.account_id
      and a.owner_id = (select auth.uid())
  )
);

-- No RLS policies are created for ledger_entries: browser roles receive no access.
revoke all on public.ledger_entries from public, anon, authenticated;
revoke all on public.bank_accounts from anon;
revoke all on public.bank_transactions from anon;
revoke all on public.profiles from anon;

grant select on public.profiles to authenticated;
grant update (display_name, phone) on public.profiles to authenticated;
grant select on public.bank_accounts to authenticated;
grant select on public.bank_transactions to authenticated;

commit;
