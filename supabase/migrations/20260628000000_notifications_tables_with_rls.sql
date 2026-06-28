-- Smart-notifications Spec 2 schema: device_tokens, notification_prefs,
-- notification_log. RLS on every table (user_id = auth.uid()); the
-- evaluate-notifications Edge Function reads across users via the service role.
-- Applied via MCP apply_migration; versioned here alongside the app.

-- ── Tables ──────────────────────────────────────────────────────────────────

-- One row per device. The client upserts (user_id, token); timezone is the
-- device IANA zone used by the function to compute local time / quiet hours.
create table public.device_tokens (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  token      text not null,
  platform   text not null check (platform in ('android', 'ios')),
  timezone   text not null default 'UTC',
  updated_at timestamptz not null default now(),
  primary key (user_id, token)
);
create index device_tokens_user_id_idx on public.device_tokens (user_id);

-- Mirrors the Settings subset Spec 1 already stores locally. One row per user.
create table public.notification_prefs (
  user_id              uuid primary key references public.profiles (id) on delete cascade,
  streak_alerts        boolean not null default true,
  weekly_goal_alerts   boolean not null default true,
  goal_achieved_alerts boolean not null default true,
  comeback_alerts      boolean not null default true,
  quiet_hours_start_min integer not null default 1260, -- 21:00
  quiet_hours_end_min   integer not null default 480,  -- 08:00
  updated_at           timestamptz not null default now()
);

-- Server-side send log for dedup / frequency caps. `type` is one of
-- 'streak' | 'weekly_goal' | 'goal_achieved' | 'comeback'.
create table public.notification_log (
  id      bigint generated always as identity primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  type    text not null check (type in ('streak','weekly_goal','goal_achieved','comeback')),
  sent_at timestamptz not null default now()
);
create index notification_log_user_type_idx on public.notification_log (user_id, type, sent_at desc);

-- ── Row Level Security ────────────────────────────────────────────────────────

alter table public.device_tokens enable row level security;
alter table public.notification_prefs enable row level security;
alter table public.notification_log enable row level security;

-- device_tokens: user_id = auth.uid()
create policy "device_tokens_select_own" on public.device_tokens
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "device_tokens_insert_own" on public.device_tokens
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "device_tokens_update_own" on public.device_tokens
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "device_tokens_delete_own" on public.device_tokens
  for delete to authenticated using ((select auth.uid()) = user_id);

-- notification_prefs: user_id = auth.uid()
create policy "notification_prefs_select_own" on public.notification_prefs
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "notification_prefs_insert_own" on public.notification_prefs
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "notification_prefs_update_own" on public.notification_prefs
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

-- notification_log: clients may read their own history; only the service role
-- (which bypasses RLS) writes rows. No insert/update/delete policy for
-- authenticated == those operations are denied to clients by default.
create policy "notification_log_select_own" on public.notification_log
  for select to authenticated using ((select auth.uid()) = user_id);

-- Keep notification_prefs.updated_at fresh (reuse the existing helper from the
-- init migration; it is SECURITY INVOKER with a locked search_path).
create trigger notification_prefs_set_updated_at
  before update on public.notification_prefs
  for each row execute function public.set_updated_at();
