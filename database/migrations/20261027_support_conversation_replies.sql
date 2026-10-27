-- Store support conversations separately from the initial customer request.
begin;
create table if not exists public.support_replies (
 id uuid primary key default gen_random_uuid(),
 support_request_id uuid not null references public.support_requests(id) on delete cascade,
 author_user_id uuid references auth.users(id) on delete set null,
 author_role text not null check (author_role in ('admin','customer')),
 message text not null check (char_length(message) between 1 and 3000),
 created_at timestamptz not null default now()
);
create index if not exists support_replies_request_created_idx on public.support_replies(support_request_id,created_at asc);
alter table public.support_replies enable row level security;
revoke all on public.support_replies from public,anon,authenticated;
grant select,insert on public.support_replies to authenticated;
drop policy if exists support_replies_read_request_owner on public.support_replies;
create policy support_replies_read_request_owner on public.support_replies for select to authenticated using (
 exists (select 1 from public.support_requests r where r.id=support_request_id and r.user_id=(select auth.uid()))
);
drop policy if exists support_replies_customer_reply_own_open_request on public.support_replies;
create policy support_replies_customer_reply_own_open_request on public.support_replies for insert to authenticated with check (
 author_user_id=(select auth.uid()) and author_role='customer' and exists (
  select 1 from public.support_requests r where r.id=support_request_id and r.user_id=(select auth.uid()) and r.status in ('open','in_progress')
 )
);
commit;
