-- Calendar notes: one row per note, multiple notes per day allowed.
-- Run this in Supabase's SQL editor (Project -> SQL Editor -> New query).

create extension if not exists pgcrypto; -- for gen_random_uuid()

create table if not exists public.calendar_notes (
  id uuid primary key default gen_random_uuid(),
  bs_year int not null,
  bs_month int not null check (bs_month between 1 and 12),
  bs_day int not null check (bs_day between 1 and 32),
  ad_date date not null,               -- redundant Gregorian date, handy for lookups/sorting
  note text not null check (char_length(note) between 1 and 500),
  created_at timestamptz not null default now()
);

create index if not exists calendar_notes_bs_idx
  on public.calendar_notes (bs_year, bs_month, bs_day);

-- Row Level Security: the app talks to Supabase directly from the browser
-- using the public "anon" key (there is no login system in this app), so
-- anyone who can load the page can read/add/delete notes. That's fine for
-- a personal/local tool; if you ever host this page publicly and want
-- real access control, add Supabase Auth and tighten these policies to
-- check auth.uid() instead of allowing anon everything.
alter table public.calendar_notes enable row level security;

create policy "anon can read notes"
  on public.calendar_notes for select
  to anon
  using (true);

create policy "anon can add notes"
  on public.calendar_notes for insert
  to anon
  with check (true);

create policy "anon can delete notes"
  on public.calendar_notes for delete
  to anon
  using (true);
