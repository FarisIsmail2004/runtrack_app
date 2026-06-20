-- Initial RunTrack schema: profiles, runs, run_points, goals — with Row Level
-- Security enabled on every table from day one (user_id = auth.uid()).
--
-- Applied to the Supabase project via MCP apply_migration; kept here so the
-- schema is version-controlled alongside the app. Mirrors the data model in
-- CLAUDE.md and the domain models in lib/features/run_tracking/domain/.

-- ── Tables ──────────────────────────────────────────────────────────────────

-- One profile row per auth user. PK == auth.users.id (per CLAUDE.md sketch).
create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  weight_kg    double precision,
  dob          date,
  unit_pref    text not null default 'km' check (unit_pref in ('km', 'mi')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create table public.runs (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references public.profiles (id) on delete cascade,
  started_at        timestamptz not null,
  ended_at          timestamptz,
  distance_m        double precision not null default 0,
  duration_s        integer not null default 0,
  avg_pace_s_per_km double precision,
  calories_est      double precision,
  synced            boolean not null default false,
  created_at        timestamptz not null default now()
);
create index runs_user_id_idx on public.runs (user_id);
create index runs_started_at_idx on public.runs (started_at desc);

-- High-volume: bigint identity PK, indexed on run_id. `recorded_at` maps to the
-- RunPoint.timestamp domain field (named to avoid the reserved `timestamp` word).
create table public.run_points (
  id          bigint generated always as identity primary key,
  run_id      uuid not null references public.runs (id) on delete cascade,
  lat         double precision not null,
  lng         double precision not null,
  elevation   double precision,
  speed       double precision,
  accuracy    double precision,
  recorded_at timestamptz not null
);
create index run_points_run_id_idx on public.run_points (run_id);

create table public.goals (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  type         text not null,
  target_value double precision,
  period       text,
  created_at   timestamptz not null default now()
);
create index goals_user_id_idx on public.goals (user_id);

-- ── Row Level Security ────────────────────────────────────────────────────────

alter table public.profiles enable row level security;
alter table public.runs enable row level security;
alter table public.run_points enable row level security;
alter table public.goals enable row level security;

-- profiles: own row keyed by id = auth.uid()
create policy "profiles_select_own" on public.profiles
  for select to authenticated using ((select auth.uid()) = id);
create policy "profiles_insert_own" on public.profiles
  for insert to authenticated with check ((select auth.uid()) = id);
create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
create policy "profiles_delete_own" on public.profiles
  for delete to authenticated using ((select auth.uid()) = id);

-- runs: user_id = auth.uid()
create policy "runs_select_own" on public.runs
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "runs_insert_own" on public.runs
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "runs_update_own" on public.runs
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "runs_delete_own" on public.runs
  for delete to authenticated using ((select auth.uid()) = user_id);

-- run_points: ownership derived from the parent run
create policy "run_points_select_own" on public.run_points
  for select to authenticated
  using (exists (select 1 from public.runs r
                 where r.id = run_id and r.user_id = (select auth.uid())));
create policy "run_points_insert_own" on public.run_points
  for insert to authenticated
  with check (exists (select 1 from public.runs r
                      where r.id = run_id and r.user_id = (select auth.uid())));
create policy "run_points_update_own" on public.run_points
  for update to authenticated
  using (exists (select 1 from public.runs r
                 where r.id = run_id and r.user_id = (select auth.uid())))
  with check (exists (select 1 from public.runs r
                      where r.id = run_id and r.user_id = (select auth.uid())));
create policy "run_points_delete_own" on public.run_points
  for delete to authenticated
  using (exists (select 1 from public.runs r
                 where r.id = run_id and r.user_id = (select auth.uid())));

-- goals: user_id = auth.uid()
create policy "goals_select_own" on public.goals
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "goals_insert_own" on public.goals
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "goals_update_own" on public.goals
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "goals_delete_own" on public.goals
  for delete to authenticated using ((select auth.uid()) = user_id);

-- ── Triggers ──────────────────────────────────────────────────────────────────

-- Auto-create a profile row on signup. SECURITY DEFINER (needs to write to a
-- table the new user can't yet touch) with a locked empty search_path and
-- schema-qualified writes; EXECUTE revoked from client roles so it is not a
-- callable public endpoint (the trigger still fires regardless of grants).
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, split_part(coalesce(new.email, ''), '@', 1));
  return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Keep profiles.updated_at fresh. SECURITY INVOKER (no elevated privilege needed).
create function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();
