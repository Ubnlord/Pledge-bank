-- Customer dashboard settings, support requests, and notification center.
begin;
create table if not exists public.customer_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email_notifications boolean not null default true,
  security_alerts boolean not null default true,
  marketing_emails boolean not null default false,
  preferred_language text not null default 'en' check (preferred_language in ('en')),
  updated_at timestamptz not null default now()
);
create table if not exists public.support_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subject text not null check (char_length(subject) between 4 and 120),
  category text not null check (category in ('account','login','transactions','security','other')),
  message text not null check (char_length(message) between 10 and 3000),
  status text not null default 'open' check (status in ('open','in_progress','resolved','closed')),
  created_at timestamptz not null default now()
);
create table if not exists public.customer_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  body text not null check (char_length(body) between 1 and 1000),
  category text not null default 'account' check (category in ('account','security','transaction','support','general')),
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists support_requests_user_created_idx on public.support_requests(user_id,created_at desc);
create index if not exists customer_notifications_user_created_idx on public.customer_notifications(user_id,created_at desc);
alter table public.customer_settings enable row level security;
alter table public.support_requests enable row level security;
alter table public.customer_notifications enable row level security;
drop policy if exists customer_settings_read_self on public.customer_settings;
create policy customer_settings_read_self on public.customer_settings for select to authenticated using ((select auth.uid())=user_id);
drop policy if exists customer_settings_insert_self on public.customer_settings;
create policy customer_settings_insert_self on public.customer_settings for insert to authenticated with check ((select auth.uid())=user_id);
drop policy if exists customer_settings_update_self on public.customer_settings;
create policy customer_settings_update_self on public.customer_settings for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
drop policy if exists support_requests_read_self on public.support_requests;
create policy support_requests_read_self on public.support_requests for select to authenticated using ((select auth.uid())=user_id);
drop policy if exists support_requests_create_self on public.support_requests;
create policy support_requests_create_self on public.support_requests for insert to authenticated with check ((select auth.uid())=user_id and status='open');
drop policy if exists customer_notifications_read_self on public.customer_notifications;
create policy customer_notifications_read_self on public.customer_notifications for select to authenticated using ((select auth.uid())=user_id);
drop policy if exists customer_notifications_update_self on public.customer_notifications;
create policy customer_notifications_update_self on public.customer_notifications for update to authenticated using ((select auth.uid())=user_id) with check ((select auth.uid())=user_id);
revoke all on public.customer_settings,public.support_requests,public.customer_notifications from public,anon,authenticated;
grant select,insert,update on public.customer_settings to authenticated;
grant select,insert on public.support_requests to authenticated;
grant select on public.customer_notifications to authenticated;
grant update (read_at) on public.customer_notifications to authenticated;
commit;
